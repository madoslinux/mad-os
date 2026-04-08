#!/usr/bin/env bash
set -euo pipefail

active=""
if command -v i3-msg >/dev/null 2>&1; then
    active="$(i3-msg -t get_workspaces 2>/dev/null | python3 -c 'import json,sys
try:
    data=json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit(0)
for ws in data:
    if ws.get("focused"):
        print(ws.get("num", ""))
        break
' 2>/dev/null || true)"
fi

out=""
for n in 1 2 3 4 5 6; do
    if [ "$n" = "$active" ]; then
        out+="[%{F#ECEFF4}%{B#81A1C1} ${n} %{B-}%{F-}] "
    else
        out+="%{F#88C0D0}${n}%{F-} "
    fi
done

printf "%s\n" "${out% }"
