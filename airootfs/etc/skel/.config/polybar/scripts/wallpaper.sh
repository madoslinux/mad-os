#!/usr/bin/env bash
set -euo pipefail

WALL=""
DEFAULT_WALL="/usr/share/mados/themes/imperative-dots/.config/sddm/themes/matugen-minimal/wallpaper.jpg"
USER_WALL_DIR="$HOME/.local/share/mados/wallpapers"

if [ -f "/tmp/lock_bg.png" ]; then
    WALL="/tmp/lock_bg.png"
elif [ -d "$USER_WALL_DIR" ]; then
    shopt -s nullglob
    CANDIDATES=(
        "$USER_WALL_DIR"/*.jpg
        "$USER_WALL_DIR"/*.jpeg
        "$USER_WALL_DIR"/*.png
        "$USER_WALL_DIR"/*.webp
        "$USER_WALL_DIR"/*.JPG
        "$USER_WALL_DIR"/*.JPEG
        "$USER_WALL_DIR"/*.PNG
        "$USER_WALL_DIR"/*.WEBP
    )
    shopt -u nullglob
    if [ "${#CANDIDATES[@]}" -gt 0 ]; then
        WALL="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"
    fi
fi

if [ -z "$WALL" ] && [ -f "$DEFAULT_WALL" ]; then
    WALL="$DEFAULT_WALL"
fi

if [ -n "$WALL" ] && [ -f "$WALL" ]; then
    feh --bg-fill "$WALL"
fi
