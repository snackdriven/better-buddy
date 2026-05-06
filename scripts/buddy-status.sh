#!/usr/bin/env bash
# buddy-status.sh — Claude Code status line for buddy companion
# Outputs a compact status line: face + name + affection + hunger + event reaction
# Invoked by Claude Code as a status line command; receives JSON on stdin

# Delegate to multi-region renderer if installed (claude-statusline)
RENDERER="$HOME/.claude/buddy/render.sh"
if [[ -f "$RENDERER" ]]; then
  exec bash "$RENDERER"
fi

BUDDY_FILE="$HOME/.claude/buddy.json"

# Read buddy state
if [[ ! -f "$BUDDY_FILE" ]]; then
  # No buddy yet — show egg prompt
  printf "\033[90m🥚 /buddy\033[0m"
  exit 0
fi

buddy=$(cat "$BUDDY_FILE" 2>/dev/null)
if [[ -z "$buddy" ]]; then
  printf "\033[90m🥚 /buddy\033[0m"
  exit 0
fi

# Parse fields
name=$(echo "$buddy" | jq -r '.name // "Buddy"')
species=$(echo "$buddy" | jq -r '.species // "capybara"')
affection=$(echo "$buddy" | jq -r '.affection // 50')
hunger=$(echo "$buddy" | jq -r '.hunger // 60')
napping=$(echo "$buddy" | jq -r '.napping // false')
nap_started=$(echo "$buddy" | jq -r '.nap_started // ""')
rarity=$(echo "$buddy" | jq -r '.rarity // "Common"')
shiny=$(echo "$buddy" | jq -r '.shiny // false')
current_event=$(echo "$buddy" | jq -r '.current_event // ""')
event_ts=$(echo "$buddy" | jq -r '.event_ts // 0')

# Time of day
hour=$(date +%H)
hour=$((10#$hour))

# Species faces (inline, single-char width friendly)
face_for_species() {
  local sp="$1" is_napping="$2" hr="$3" ev="$4"
  case "$sp" in
    goose)    echo "(ò_ó)>" ;;
    cat)      echo "( •ω•)" ;;
    rabbit)   echo "(•ᴗ•)" ;;
    owl)      echo "(◉‿◉)" ;;
    penguin)  echo "(•◡•)" ;;
    snail)    echo "(@‿@)" ;;
    dragon)   echo "(>ᴗ<)" ;;
    octopus)  echo "(✿◠‿◠)" ;;
    ghost)    echo "(◌ᵒ◌)" ;;
    robot)    echo "[•_•]" ;;
    cactus)   echo "(♥‿♥)" ;;
    mushroom) echo "(◕‿◕)" ;;
    chonk)    echo "(ꖘ ꖘ)" ;;
    capybara) echo "(ᵒᴗᵒ)" ;;
    bat)
      # bat face changes by time of day
      if (( hr >= 23 || hr <= 4 )); then
        echo "(ò_ó)"   # night: wide awake
      elif (( hr >= 5 && hr <= 11 )); then
        echo "(–_–)"   # morning: grumpy
      else
        echo "(._. )"  # afternoon: just existing
      fi
      ;;
    tardigrade) echo "(>°w°<)" ;;
    moth)     echo "(•‿•)" ;;
    ferret)   echo "(•ω•)>" ;;
    *)        echo "(•‿•)" ;;
  esac
}

# Event face override (10 second window)
now=$(date +%s)
event_face=""
event_label=""

if [[ -n "$current_event" && "$event_ts" != "0" ]]; then
  age=$(( now - event_ts ))
  if (( age < 10 )); then
    case "$current_event" in
      git_commit)   event_face="(•‿•)✓" event_label=" committed" ;;
      test_fail)    event_face="(×_×)"  event_label=" tests failed" ;;
      force_push)   event_face="(ò_ó)!" event_label=" bold move" ;;
      new_file)     event_face="(•ω•)"  event_label=" new file" ;;
      big_edit)     event_face="(•_•)"  event_label=" big edit" ;;
      error_loop)   event_face="(>_<)"  event_label=" errors..." ;;
    esac
  fi
fi

# Nap face
if [[ "$napping" == "true" ]]; then
  case "$species" in
    bat) face="(–_–)💤" ;;
    *)   face="(-_-)💤" ;;
  esac
  printf "\033[90m%s %s \033[90m💤\033[0m" "$face" "$name"
  exit 0
fi

# Normal face
if [[ -n "$event_face" ]]; then
  face="$event_face"
else
  face=$(face_for_species "$species" "false" "$hour" "$current_event")
fi

# Affection hearts (3 tiers)
if (( affection >= 70 )); then
  hearts="❤❤❤"
elif (( affection >= 40 )); then
  hearts="❤❤♡"
else
  hearts="❤♡♡"
fi

# Hunger indicator
if (( hunger < 30 )); then
  hunger_icon="🍖?"
else
  hunger_icon=""
fi

# Rarity prefix
rarity_prefix=""
case "$rarity" in
  Uncommon)  rarity_prefix="✦ " ;;
  Rare)      rarity_prefix="★ " ;;
  Epic)      rarity_prefix="✦★ " ;;
  Legendary) rarity_prefix="✦★✦ " ;;
esac

shiny_tag=""
if [[ "$shiny" == "true" ]]; then
  shiny_tag="✨"
fi

# Assemble output
# Color: dim for name, normal for face, muted for hearts
if [[ -n "$event_label" ]]; then
  printf "\033[0m%s \033[90m%s%s%s\033[0m \033[31m%s\033[0m\033[90m%s\033[0m" \
    "$face" "$rarity_prefix" "$name" "$shiny_tag" "$hearts" "$hunger_icon"
else
  printf "\033[0m%s \033[90m%s%s%s\033[0m \033[31m%s\033[0m\033[90m%s\033[0m" \
    "$face" "$rarity_prefix" "$name" "$shiny_tag" "$hearts" "$hunger_icon"
fi
