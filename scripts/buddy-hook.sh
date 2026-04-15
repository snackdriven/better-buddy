#!/usr/bin/env bash
# buddy-hook.sh — Claude Code PostToolUse hook
# Silently detects interesting events from tool calls and writes them to buddy.json
# Claude Code passes hook context as JSON on stdin

BUDDY_FILE="$HOME/.claude/buddy.json"

# Bail if no buddy exists yet
[[ -f "$BUDDY_FILE" ]] || exit 0

# Read hook context from stdin
context=$(cat)
tool_name=$(echo "$context" | jq -r '.tool_name // ""' 2>/dev/null)
tool_input=$(echo "$context" | jq -r '.tool_input // {}' 2>/dev/null)

# Detect event type
event=""

case "$tool_name" in
  Bash)
    cmd=$(echo "$tool_input" | jq -r '.command // ""' 2>/dev/null)
    # git commit
    if echo "$cmd" | grep -qE 'git commit'; then
      event="git_commit"
    # force push
    elif echo "$cmd" | grep -qE 'git push.*--force|git push.*-f'; then
      event="force_push"
    # test runner failure indicators — only on non-zero exit (hook fires before we know exit code)
    # so we detect invocation of common test commands as a signal
    elif echo "$cmd" | grep -qE '(npm test|yarn test|pytest|go test|cargo test|jest|vitest)'; then
      event="test_run"
    # error-suggestive: multiple retries or npm error
    elif echo "$cmd" | grep -qE 'npm install|npm ci'; then
      event="install"
    fi
    ;;
  Write)
    event="new_file"
    ;;
  Edit)
    # Big edit: check if new_string length is substantial
    new_len=$(echo "$tool_input" | jq -r '.new_string // ""' | wc -c 2>/dev/null)
    if (( new_len > 500 )); then
      event="big_edit"
    fi
    ;;
esac

# Write event to buddy.json if we detected something
if [[ -n "$event" ]]; then
  now=$(date +%s)
  # Use jq to safely update only the event fields
  tmp=$(mktemp)
  jq --arg ev "$event" --argjson ts "$now" \
    '.current_event = $ev | .event_ts = $ts' \
    "$BUDDY_FILE" > "$tmp" && mv "$tmp" "$BUDDY_FILE"
fi

exit 0
