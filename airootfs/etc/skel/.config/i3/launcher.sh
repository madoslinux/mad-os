#!/usr/bin/env bash
set -euo pipefail

if command -v dmenu_run >/dev/null 2>&1; then
    exec dmenu_run
fi

if command -v wofi >/dev/null 2>&1; then
    exec wofi --show drun
fi

if command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun
fi

exec i3-nagbar -m "No launcher found (dmenu/wofi/rofi)"
