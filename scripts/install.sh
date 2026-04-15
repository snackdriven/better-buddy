#!/usr/bin/env bash
# install.sh — better-buddy installer
# Copies buddy.md, scripts, and merges Claude Code settings

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "→ Installing better-buddy..."

# 1. Create .claude dirs if needed
mkdir -p "$CLAUDE_DIR/commands"

# 2. Copy buddy skill
cp "$REPO_DIR/buddy.md" "$CLAUDE_DIR/commands/buddy.md"
echo "  ✓ buddy.md → ~/.claude/commands/buddy.md"

# 3. Copy scripts
cp "$REPO_DIR/scripts/buddy-status.sh" "$CLAUDE_DIR/buddy-status.sh"
cp "$REPO_DIR/scripts/buddy-hook.sh" "$CLAUDE_DIR/buddy-hook.sh"
cp "$REPO_DIR/scripts/buddy-stop.sh" "$CLAUDE_DIR/buddy-stop.sh"
chmod +x "$CLAUDE_DIR/buddy-status.sh"
chmod +x "$CLAUDE_DIR/buddy-hook.sh"
chmod +x "$CLAUDE_DIR/buddy-stop.sh"
echo "  ✓ scripts → ~/.claude/"

# 4. Merge settings.json
# Requires: jq (preferred) or python3 fallback
if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
  echo ""
  echo "  ⚠  Neither jq nor python3 found."
  echo "     Add the following to $SETTINGS manually:"
  echo ""
  cat << 'EOF'
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/buddy-status.sh"
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/buddy-hook.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/buddy-stop.sh" }
        ]
      }
    ]
  }
EOF
  exit 0
fi

# Merge using python3 (handles existing hooks gracefully)
PYTHONUTF8=1 python3 - <<PYEOF
import json, sys, os

settings_path = os.path.join(os.path.expanduser("~"), ".claude", "settings.json")
os.makedirs(os.path.dirname(settings_path), exist_ok=True)
if not os.path.exists(settings_path):
    with open(settings_path, "w") as f:
        json.dump({}, f)

with open(settings_path) as f:
    settings = json.load(f)

# Status line
settings["statusLine"] = {
    "type": "command",
    "command": "bash ~/.claude/buddy-status.sh"
}

# Hooks
buddy_hook_cmd = "bash ~/.claude/buddy-hook.sh"
buddy_stop_cmd = "bash ~/.claude/buddy-stop.sh"

hooks = settings.get("hooks", {})

# PostToolUse
post_tool = hooks.get("PostToolUse", [])
buddy_hook_entry = {
    "matcher": "",
    "hooks": [{"type": "command", "command": buddy_hook_cmd}]
}
# Don't double-add
if not any(
    any(h.get("command") == buddy_hook_cmd for h in block.get("hooks", []))
    for block in post_tool
):
    post_tool.append(buddy_hook_entry)
hooks["PostToolUse"] = post_tool

# Stop
stop_hooks = hooks.get("Stop", [])
buddy_stop_entry = {
    "matcher": "",
    "hooks": [{"type": "command", "command": buddy_stop_cmd}]
}
if not any(
    any(h.get("command") == buddy_stop_cmd for h in block.get("hooks", []))
    for block in stop_hooks
):
    stop_hooks.append(buddy_stop_entry)
hooks["Stop"] = stop_hooks

settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("  ok: settings.json updated")
PYEOF

echo ""
echo "  ✓ Done. Restart Claude Code for changes to take effect."
echo ""
echo "  Run /buddy to meet your new companion."
