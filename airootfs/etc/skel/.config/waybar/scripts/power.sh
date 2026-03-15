#!/usr/bin/env bash

options="<span size='14000' font_family='monospace'><span color='#BF616A' weight='bold'>⎋  Logout   </span> Cerrar sesión</span>
<span size='14000' font_family='monospace'><span color='#E5C07B' weight='bold'>⟳  Restart </span> Reiniciar</span>
<span size='14000' font_family='monospace'><span color='#61AFEF' weight='bold'>⏻  PowerOff</span> Apagar</span>"

choice=$(echo "$options" | wofi --show dmenu \
    --width=300 \
    --height=140 \
    --allow-markup \
    --matching=fuzzy \
    --location=center \
    --force-display \
    --hide-scroll=true \
    --hide-search \
    --no-actions \
    --prompt="" \
    --title="Power Menu" \
    --gtk-dark \
    2>/dev/null)

case "$choice" in
    *Logout*|*Cerrar*)
        hyprctl dispatch exit
        ;;
    *Restart*|*Reiniciar*)
        systemctl reboot
        ;;
    *PowerOff*|*Apagar*)
        systemctl poweroff
        ;;
esac