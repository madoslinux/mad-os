#!/usr/bin/env bash

# 1. Battery Info
# Gracefully fall back to BAT1 if BAT0 doesn't exist, or default to 100% AC if on a desktop
BAT_PATH="/sys/class/power_supply/BAT0"
if [ ! -d "$BAT_PATH" ]; then
    BAT_PATH="/sys/class/power_supply/BAT1"
fi

if [ -d "$BAT_PATH" ]; then
    BAT_PCT=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "100")
    BAT_STATUS=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")
else
    BAT_PCT="100"
    BAT_STATUS="AC"
fi

# 2. Current User
# Tries to get the formatted Real Name from passwd, falls back to the capitalized username
CURRENT_USER=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)
if [ -z "$CURRENT_USER" ]; then
    CURRENT_USER=${USER^}
fi

# 3. Keyboard Layout
# Extracts the active keymap of the main keyboard from Hyprland
LAYOUT=$(hyprctl devices -j 2>/dev/null | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n 1)

# Shorten the layout name (e.g., "English (US)" -> "US")
if [[ "$LAYOUT" == *"English (US)"* ]]; then
    KB_LAYOUT="US"
elif [[ "$LAYOUT" == *"Russian"* ]]; then
    KB_LAYOUT="RU"
elif [ -z "$LAYOUT" ] || [ "$LAYOUT" == "null" ]; then
    KB_LAYOUT="UNK"
else
    KB_LAYOUT="${LAYOUT:0:3}"
fi

# Output data cleanly for Quickshell
echo "$BAT_PCT"
echo "$BAT_STATUS"
echo "$CURRENT_USER"
echo "$KB_LAYOUT"
