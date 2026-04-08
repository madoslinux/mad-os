#!/usr/bin/env bash
set -euo pipefail

out="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
if [ -z "$out" ]; then
    printf "VOL --\n"
    exit 0
fi

if [[ "$out" == *"MUTED"* ]]; then
    printf "VOL Muted\n"
    exit 0
fi

value="$(printf "%s" "$out" | awk '{for (i=1; i<=NF; i++) if ($i ~ /^[0-9]*\.?[0-9]+$/) {print $i; exit}}')"
if [ -z "$value" ]; then
    printf "VOL --\n"
    exit 0
fi

pct="$(awk -v v="$value" 'BEGIN { printf "%d", (v * 100) + 0.5 }')"
printf "VOL %s%%\n" "$pct"
