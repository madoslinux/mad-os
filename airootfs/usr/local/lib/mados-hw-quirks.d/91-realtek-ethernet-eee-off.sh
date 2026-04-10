#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(91-realtek-ethernet): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "storage"; then
    log "storage quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

eth_device=$(lspci 2>/dev/null | grep -i "ethernet\|network" | grep -i "realtek" | head -1 || true)
if [[ -z "$eth_device" ]]; then
    if command -v lsmod >/dev/null 2>&1; then
        if lsmod 2>/dev/null | grep -q "^r8169\|r8168"; then
            eth_device="r8169-detected"
        fi
    else
        exit 0
    fi
fi

if ! echo "$eth_device" | grep -qi "realtek\|rtl\|r8169\|r8168"; then
    exit 0
fi

kernel_params_file="/etc/modprobe.d/r8169-eee-off.conf"
{
    echo "# Realtek Ethernet EEE disable"
    echo "# Applied by mados-hw-quirks 91-realtek-ethernet-eee-off.sh"
    echo "# Fixes stability issues and connection drops with RTL810x/RTL8111/RTL8168 NICs"
    echo "options r8169 eee=0"
} > "$kernel_params_file"

sysctl_conf="/etc/sysctl.d/99-realtek-ethernet.conf"
{
    echo "# Realtek Ethernet stability settings"
    echo "# Applied by mados-hw-quirks 91-realtek-ethernet-eee-off.sh"
    echo ""
    echo "# Increase netdev budget for better network performance"
    echo "net.core.netdev_budget=600"
    echo "net.core.netdev_budget_usecs=6000"
    echo ""
    echo "# Connection timeout tuning"
    echo "net.ipv4.tcp_fin_timeout=15"
    echo "net.ipv4.tcp_tw_reuse=1"
} > "$sysctl_conf"

log "Applied r8169eee=0 for Realtek Ethernet stability"
exit 0