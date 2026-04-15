# better-buddy

A terminal companion for Claude Code. Hatches from an egg. Judges you gently. Naps if you ask.

Claude shipped `/buddy` as an April Fools feature in 2026 and pulled it in v2.1.97. This rebuilds it as a Claude Code skill with a persistent status line presence, event-reactive faces, and dreams when you've been away too long.

---

## What you get

**The `/buddy` skill** — a full companion system: 18 species, 5 rarity tiers, personality stats, affection/hunger tracking, naps, dreams, time-of-day mood shifts. Runs in any Claude Code session.

**Status line** — your buddy's face lives in the terminal status bar between every message. Changes expression when you commit, push, or edit big chunks of code.

**Stop hook** — 1-in-15 chance your buddy says something at the end of a response. It's usually one word. It's always appropriate.

**PostToolUse hook** — silently watches for git commits, force pushes, test runs, and large edits. Updates the status line face for 10 seconds.

---

## Install

```bash
git clone https://github.com/snackdriven/better-buddy.git
cd better-buddy
bash scripts/install.sh
```

Restart Claude Code. Then:

```
/buddy
```

An egg appears. Something hatches. It's yours now.

---

## Species

18 to choose from. Each has weighted personality stats (CHAOS / SNARK / WISDOM / PATIENCE) that shape what it says and when.

| Species | Vibe |
|---------|------|
| goose | high CHAOS, no regrets |
| cat | high SNARK, above it all |
| rabbit | anxious but fast |
| owl | high WISDOM, unhurried |
| penguin | content with everything |
| snail | maximum patience |
| dragon | CHAOS + SNARK, committed to the bit |
| octopus | doing eight things, all of them |
| ghost | WISDOM + SNARK, unsettling |
| robot | WISDOM-heavy, low CHAOS, honest |
| cactus | patient, dry |
| mushroom | connected to something you can't see |
| chonk | balanced, round, has opinions about snacks |
| capybara | unbothered, calming presence |
| bat | inverted — thrives at night, grumpy in daylight |
| tardigrade | max PATIENCE, survived worse than this |
| moth | high CHAOS, loses the thread mid-sentence |
| ferret | kinetic gremlin energy, found something, it's yours now |

---

## Commands

```
/buddy                    # check in with your buddy
/buddy pet                # +5 affection
/buddy feed               # +15 hunger
/buddy stats              # full stat display + days alive
/buddy nap                # put buddy to sleep (protects affection decay)
/buddy rename <name>      # give them a new name
/buddy reroll             # release current buddy, hatch new one
/buddy reroll <species>   # force species, randomize everything else
/buddy reroll <species> <rarity>  # force both
/buddy off                # say goodbye (buddy persists for next time)
```

---

## How it works

Three layers:

1. **`buddy.md`** — the skill. Claude reads this when you invoke `/buddy`. All companion logic lives here: hatching, personality, commands, state management.

2. **`buddy-status.sh`** — reads `~/.claude/buddy.json` and outputs a compact status line. Claude Code runs this before every response. The face changes based on `current_event` (10-second window set by the hook).

3. **`buddy-hook.sh`** + **`buddy-stop.sh`** — PostToolUse and Stop hooks. The hook watches tool calls silently and writes events to buddy.json. The stop hook increments a turn counter and occasionally appends a one-liner to the response.

State is stored at `~/.claude/buddy.json`. Affection decays 3 points per 24 hours of absence. Naps stop the decay. If you've been away 8+ hours, buddy had a dream — you'll see it next time you check in.

---

## Requirements

- Claude Code (any recent version)
- `jq` — for the status line and hook scripts
- `python3` — for the installer's settings.json merge (falls back to manual instructions without it)
- bash

---

## Rarity

On hatch, a weighted roll determines rarity. Keeps for the buddy's lifetime.

| Rarity | Odds | Display |
|--------|------|---------|
| Common | 60% | no prefix |
| Uncommon | 25% | ✦ |
| Rare | 10% | ★ |
| Epic | 4% | ✦★ |
| Legendary | 1% | ✦★✦ |

Plus a 1% independent shiny chance. Shiny Legendary exists. Good luck.

---

## Credit

Original `/buddy` feature by Anthropic, April 2026. This is a fan reconstruction built from memory, community reports, and a lot of opinions about what makes a good terminal companion.
