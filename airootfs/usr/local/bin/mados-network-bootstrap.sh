#!/usr/bin/env bash
set -euo pipefail

if ! command -v nmcli >/dev/null 2>&1; then
    exit 0
fi

if ! systemctl is-active --quiet NetworkManager; then
    exit 0
fi

while IFS=: read -r device type state; do
    if [[ "$type" != "ethernet" ]]; then
        continue
    fi

    if [[ "$state" == "unmanaged" ]]; then
        nmcli device set "$device" managed yes >/dev/null 2>&1 || true
    fi

    if [[ "$state" == "disconnected" || "$state" == "unavailable" || "$state" == "connected (externally)" ]]; then
        nmcli device connect "$device" >/dev/null 2>&1 || true
    fi
done < <(nmcli -t -f DEVICE,TYPE,STATE device status)

exit 0
