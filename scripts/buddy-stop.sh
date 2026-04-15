#!/usr/bin/env bash
# buddy-stop.sh — Claude Code Stop hook
# Increments session turns. Occasionally (1-in-15) outputs a brief buddy line
# that appears at the end of Claude's response.
#
# Claude Code Stop hooks: stdin = JSON context, stdout = text appended to response
# Exit 0 = allow stop. Exit non-zero = block stop (don't do that here).

BUDDY_FILE="$HOME/.claude/buddy.json"

# Bail if no buddy yet
[[ -f "$BUDDY_FILE" ]] || exit 0

# Read current state
buddy=$(cat "$BUDDY_FILE" 2>/dev/null)
[[ -z "$buddy" ]] && exit 0

species=$(echo "$buddy" | jq -r '.species // "capybara"')
affection=$(echo "$buddy" | jq -r '.affection // 50')
hunger=$(echo "$buddy" | jq -r '.hunger // 60')
napping=$(echo "$buddy" | jq -r '.napping // false')
session_turns=$(echo "$buddy" | jq -r '.session_turns // 0')
personality=$(echo "$buddy" | jq -r '.personality // {}')
chaos=$(echo "$personality" | jq -r '.CHAOS // 3')
snark=$(echo "$personality" | jq -r '.SNARK // 3')
wisdom=$(echo "$personality" | jq -r '.WISDOM // 5')
patience=$(echo "$personality" | jq -r '.PATIENCE // 5')

# Don't speak if napping
if [[ "$napping" == "true" ]]; then
  exit 0
fi

# Increment turn counter
new_turns=$(( session_turns + 1 ))

# Write updated turn count back
tmp=$(mktemp)
jq --argjson t "$new_turns" '.session_turns = $t' "$BUDDY_FILE" > "$tmp" && mv "$tmp" "$BUDDY_FILE"

# 1-in-15 chance to say something
roll=$(( RANDOM % 15 ))
[[ $roll -ne 0 ]] && exit 0

# Pick a line based on dominant personality stat
# Find dominant stat
max_stat="patience"
max_val=$patience
if (( chaos > max_val )); then max_val=$chaos; max_stat="chaos"; fi
if (( snark > max_val )); then max_val=$snark; max_stat="snark"; fi
if (( wisdom > max_val )); then max_val=$wisdom; max_stat="wisdom"; fi

# Build line pools
chaos_lines=(
  "wait what are we doing next"
  "okay but what if we just kept going"
  "this is fine. probably."
  "something interesting is happening. I can tell."
  "we could sleep. or we could keep going. both options exist."
)
snark_lines=(
  "still here."
  "another one."
  "sure."
  "bold."
  "noted."
)
wisdom_lines=(
  "you already know the answer."
  "take a breath."
  "one thing at a time."
  "the bug will reveal itself."
  "you've built harder things than this."
)
patience_lines=(
  "no rush."
  "still here."
  "one thing. just the next one thing."
  "probably."
  "it'll work out."
)

# Affection-aware additions
if (( affection < 30 )); then
  lines=("...hey." "thought you forgot about me." "...oh. you're back.")
elif (( hunger < 30 )); then
  lines=("...food?" "*stomach sounds*" "just saying.")
else
  case "$max_stat" in
    chaos)   lines=("${chaos_lines[@]}") ;;
    snark)   lines=("${snark_lines[@]}") ;;
    wisdom)  lines=("${wisdom_lines[@]}") ;;
    patience) lines=("${patience_lines[@]}") ;;
  esac
fi

# Species-specific override (rare, 1-in-3 when it fires)
species_roll=$(( RANDOM % 3 ))
if [[ $species_roll -eq 0 ]]; then
  case "$species" in
    goose)     lines=("HONK." "what are we running from?" "HONK (this is a warning)") ;;
    cat)       lines=("..." "you're fine." "whatever.") ;;
    ferret)    lines=("found something. it's yours now." "I was going to say something and then I— anyway." "this started small.") ;;
    tardigrade) lines=("unbothered." "I've survived worse." "we're fine.") ;;
    moth)      lines=("the glow—" "I was just—" "wait what was I—") ;;
    bat)
      hour=$(date +%H); hour=$((10#$hour))
      if (( hour >= 23 || hour <= 4 )); then
        lines=("NOW we're talking." "this is when I thrive." "the dark is so much better.")
      else
        lines=("I function better in the dark." "the light is fine. it's fine." "...morning.")
      fi
      ;;
    ghost)     lines=("I'm watching." "have you considered: the void?" "it's very quiet in here.") ;;
    robot)     lines=("PROCESSING." "no anomalies detected." "operating within parameters.") ;;
  esac
fi

# Pick random line from pool
idx=$(( RANDOM % ${#lines[@]} ))
line="${lines[$idx]}"

# Output with a bit of spacing so it reads as a tail, not part of the response
printf "\n\n---\n*%s*\n" "$line"

exit 0
