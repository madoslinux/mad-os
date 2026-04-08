#!/usr/bin/env bash
set -euo pipefail

if ! command -v polybar >/dev/null 2>&1; then
    exit 0
fi

pkill -x polybar 2>/dev/null || true

sleep 0.2
/usr/bin/env bash ~/.config/polybar/scripts/wallpaper.sh >/tmp/polybar-wallpaper.log 2>&1 || true
polybar top >/tmp/polybar.log 2>&1 &
