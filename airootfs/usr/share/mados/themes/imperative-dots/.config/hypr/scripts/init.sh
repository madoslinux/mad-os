#!/usr/bin/env bash

SESSION_KEY="${HYPRLAND_INSTANCE_SIGNATURE:-$(id -u)}"
SESSION_FLAG="/tmp/mados-wallpaper-initialized-${SESSION_KEY}"
GUIDE_FLAG="$HOME/.cache/wallpaper_initialized"
MATUGEN_SOURCE=""

[[ -f "$SESSION_FLAG" ]] && exit 0

sleep 0.2

if [[ -f "/tmp/lock_bg.png" ]]; then
    MATUGEN_SOURCE="/tmp/lock_bg.png"
elif [[ -d "${WALLPAPER_DIR:-}" ]]; then
    shopt -s nullglob
    wallpapers=(
        "$WALLPAPER_DIR"/*.jpg
        "$WALLPAPER_DIR"/*.jpeg
        "$WALLPAPER_DIR"/*.png
        "$WALLPAPER_DIR"/*.webp
    )
    shopt -u nullglob

    if (( ${#wallpapers[@]} > 0 )); then
        MATUGEN_SOURCE="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    fi
fi

if [[ -n "$MATUGEN_SOURCE" ]]; then
    cp "$MATUGEN_SOURCE" /tmp/lock_bg.png
    awww img "$MATUGEN_SOURCE" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    matugen image "$MATUGEN_SOURCE" --source-color-index 0
    bash ~/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh
fi

# Launch the guide widget only once per user profile.
if [[ ! -f "$GUIDE_FLAG" ]]; then
    bash ~/.config/hypr/scripts/qs_manager.sh guide &
    mkdir -p "$(dirname "$GUIDE_FLAG")"
    touch "$GUIDE_FLAG"
fi

touch "$SESSION_FLAG"
