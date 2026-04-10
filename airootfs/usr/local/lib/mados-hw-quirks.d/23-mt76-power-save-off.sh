#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(23-mt76-power-save): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "wifi"; then
    log "wifi quirks disabled via mados.disable_quirks"
    exit 0
fi

mt76_loaded=false
if command -v lsmod >/dev/null 2>&1; then
    if lsmod 2>/dev/null | grep -q "^mt76"; then
        mt76_loaded=true
    fi
fi

if [[ "$mt76_loaded" == "false" ]]; then
    if command -v lspci >/dev/null 2>&1; then
        if lspci 2>/dev/null | grep -qi "mediatek\|mt7921\|mt7922\|mt7612"; then
            mt76_loaded=true
        fi
    fi
fi

if [[ "$mt76_loaded" == "false" ]]; then
    exit 0
fi

kernel_params_file="/etc/modprobe.d/mt76.conf"
{
    echo "# MediaTek MT76 power save disable"
    echo "# Applied by mados-hw-quirks 23-mt76-power-save-off.sh"
    echo "# Fixes stability issues with MT7921/MT7922/MT7612 WiFi+Bluetooth combo adapters"
    echo "options mt76 power_save=0"
} > "$kernel_params_file"

if [[ -f /etc/modprobe.d/mt7921.conf ]]; then
    if ! grep -q "power_save=0" /etc/modprobe.d/mt7921.conf 2>/dev/null; then
        echo "options mt76 power_save=0" >> /etc/modprobe.d/mt7921.conf
    fi
fi

log "Applied mt76.power_save=0 for MediaTek WiFi stability"
exit 0