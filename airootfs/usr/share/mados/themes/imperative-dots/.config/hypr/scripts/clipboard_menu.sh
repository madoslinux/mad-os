#!/usr/bin/env bash

if pgrep -x "wofi" > /dev/null; then
    pkill wofi
    exit 0
fi

wofi_args=(--dmenu --prompt "Clipboard")

if [[ -f "$HOME/.config/wofi/config" ]]; then
    wofi_args+=(--conf "$HOME/.config/wofi/config")
fi

if [[ -f "$HOME/.config/wofi/style.css" ]]; then
    wofi_args+=(--style "$HOME/.config/wofi/style.css")
fi

selection=$(cliphist list | wofi "${wofi_args[@]}")

if [[ -n "$selection" ]]; then
    printf "%s" "$selection" | cliphist decode | wl-copy
fi
