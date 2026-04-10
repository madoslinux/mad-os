#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(22-atheros-ath9k): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "wifi"; then
    log "wifi quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

ath_device=$(lspci 2>/dev/null | grep -i "network\|ethernet\|wireless" | grep -i "atheros\|qca" | head -1 || true)
if [[ -z "$ath_device" ]]; then
    if command -v lsmod >/dev/null 2>&1; then
        if lsmod 2>/dev/null | grep -q "^ath9k"; then
            ath_device="ath9k-detected"
        fi
    else
        exit 0
    fi
fi

if ! echo "$ath_device" | grep -qi "atheros\|qca\|ath"; then
    exit 0
fi

kernel_params_file="/etc/modprobe.d/ath9k.conf"
{
    echo "# Atheros ath9k power save disable"
    echo "# Applied by mados-hw-quirks 22-atheros-ath9k-powersave-off.sh"
    echo "# Fixes stability issues with AR928x/AR9485/AR9565 WiFi adapters"
    echo "options ath9k ps_enable=0"
} > "$kernel_params_file"

sysctl_conf="/etc/sysctl.d/99-atheros-wifi.conf"
{
    echo "# Atheros WiFi stability settings"
    echo "# Applied by mados-hw-quirks 22-atheros-ath9k-powersave-off.sh"
    echo ""
    echo "# Increase network device budget for better throughput"
    echo "net.core.netdev_budget=600"
    echo "net.core.netdev_budget_usecs=6000"
} > "$sysctl_conf"

log "Applied ath9k.ps_enable=0 for Atheros WiFi stability"
exit 0