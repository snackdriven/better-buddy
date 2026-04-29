# buddy/ — multi-region Claude Code statusline

Built 2026-04-27. Replaces the old single-script `~/.claude/statusline-command.sh` (still on disk, no longer wired).

## What it does

The Claude Code statusline becomes a multi-row composed display where each region (buddy, context%, active ticket, project, meeting, conscience hint, coordinator) is produced independently and rendered together with width budgeting and TTL-based staleness.

Active wiring lives in `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/buddy-status.sh" }
```

`~/.claude/buddy-status.sh` is a thin shim that execs `~/.claude/buddy/render.sh`.

## Architecture

```
Claude Code → buddy-status.sh → render.sh
                                  ├─ forks all producers/*.sh in parallel (each self-caches via TTL)
                                  └─ reads regions/*.json, sorts, fits, colors, prints
```

**Region contract** (each producer writes one):

```json
{
  "id": "ticket",
  "text": "TTOAD-44 · idle 99m",
  "color": "dim",
  "row": 0,
  "priority": 80,
  "ttl_sec": 60,
  "updated_at": 1777497903
}
```

**Render rules** (`render.sh`):
- Sort by `row` asc, then `priority` desc within row
- Drop entries where `now - updated_at > ttl_sec`
- 120-char width budget per row, separator ` · `, ANSI colors (dim/cyan/magenta/yellow/red/green)
- Width overflow = silently drop, no truncation
- Empty rows skipped (no blank lines between rendered rows)

## Producers

| File | Region | Row | Priority | TTL | What it shows |
|---|---|---|---|---|---|
| `buddy.sh` | buddy companion | 0 | 90 | 30s | Pet (`(•ω•) ★ Bandit ❤❤❤`) — ported from old buddy-status.sh |
| `context.sh` | context window | 0 | 80 | 15s | `ctx 13%` from live transcript JSONL |
| `ticket.sh` | active ticket | 0 | 80 | 60s | Detected TTOAD ticket from filesystem activity, with idle timer |
| `coord.sh` | coordinator | 1 | 75 | 30s | Multi-session coordinator heartbeat + worker dots |
| `project.sh` | project | 1 | 60 | 30s | `client-intake on main+5` (basename + branch + dirty count) |
| `meeting.sh` | next meeting | 1 | 50 | 60s | From `~/.claude/next-meeting.txt` |
| `conscience.sh` | rule hint | 2 | 40 | 60s | Match recent activity against feedback rules, surface one hint |

Each producer runs as `bash producer.sh` with the Claude Code statusline JSON piped to stdin (`workspace.current_dir`, `transcript_path`, etc.). Producers self-cache by checking their region file's `updated_at` against TTL before doing real work, so the renderer parallelism is cheap.

## Conscience system

The conscience producer matches recent tool activity against an 18-rule feedback index and surfaces one hint. Files:

- `build-conscience-index.sh` — manual rebuild trigger. Hardcoded 18 rules. Run when adding/editing rules.
- `conscience-index.json` — generated rule table (file → hint, color, cooldown_min, triggers[]).
- `.cooldowns.json` — per-rule last-shown timestamps so the same hint doesn't spam.
- `events.log` — append-only ledger of recent tool calls (`<ts> <tool> <cmd> <cwd> <file>`). Populated by a hook elsewhere.

**Trigger kinds** in the rule table:
- `bash_cmd` regex against the bash command string
- `file_path` regex against tool target path
- `cwd_path` regex against the working directory
- `tool_name` regex against the tool name

Adding a rule: edit `build-conscience-index.sh`, run it, done. Future improvement (called out in the script header): pull triggers from feedback memory frontmatter instead of the hardcoded list.

## Session state

- `session-state.json` — short-lived per-session counters (closer_phrases, pass_fail_log, recent_searches).
- `session-reset.sh` — wired to SessionStart hook. Resets the file so each new session starts clean.

## When to touch what

- **Adding a region** → write `producers/<name>.sh` that emits `regions/<name>.json`. Pick a row + priority that doesn't fight existing producers. Set TTL to whatever cadence the data updates at. No renderer changes needed.
- **Adding a conscience rule** → edit `build-conscience-index.sh`, run it. Cooldown is per-rule.
- **Renderer changes** (width budget, separator, color map) → `render.sh`. Only place those live.
- **Wiring changes** (which command runs as statusLine) → `~/.claude/settings.json`.

## Things to know

- `set -u` not `-e` in the renderer — producer failures shouldn't kill the line.
- Bare `&` (not subshell-fork) for producer parallelism so the parent can `wait` on them.
- Single `jq -rs` pass does the filter+sort, output is TSV, then bash groups by row.
- Old `~/.claude/statusline-command.sh` (4/2 buddy-only renderer) is still on disk but not wired. Safe to delete if cleanup time, but harmless to leave.

## Last verified

2026-04-29 — system actively running, `events.log` and `session-state.json` updating in real time. No edits to renderer or producers since 4/27.
