#!/usr/bin/env bash

FLAG="$HOME/.cache/wallpaper_initialized"

[ -f "$FLAG" ] && exit 0

sleep 0.2

file=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

if [ -n "$file" ]; then
    cp "$file" /tmp/lock_bg.png
    awww img "$file" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    matugen image "$file" --source-color-index 0 
fi

# Launch the guide widget (runs only once because of the flag below)
bash ~/.config/hypr/scripts/qs_manager.sh guide &

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
