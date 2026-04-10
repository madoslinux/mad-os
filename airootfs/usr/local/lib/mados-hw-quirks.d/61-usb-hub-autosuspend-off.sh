#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(61-usb-hub-autosuspend): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "usb"; then
    log "usb quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lsusb >/dev/null 2>&1; then
    exit 0
fi

usb_hubs=$(lsusb 2>/dev/null | grep -i "hub" || true)
if [[ -z "$usb_hubs" ]]; then
    exit 0
fi

has_problematic_hub=false
if echo "$usb_hubs" | grep -qi "genesys\|gl3523\|gl850g\|fl1000\|fl1100"; then
    has_problematic_hub=true
fi

if [[ "$has_problematic_hub" == "false" ]]; then
    if lsusb 2>/dev/null | grep -c "Hub" | grep -q "[2-9]"; then
        has_problematic_hub=true
    fi
fi

if [[ "$has_problematic_hub" == "false" ]]; then
    exit 0
fi

kernel_params_file="/etc/modprobe.d/usbcore-hub.conf"
{
    echo "# USB hub autosuspend disable"
    echo "# Applied by mados-hw-quirks 61-usb-hub-autosuspend-off.sh"
    echo "# Fixes issues with Genesys GL3523/GL850G and other problematic USB hubs"
    echo "options usbcore autosuspend=-1"
} > "$kernel_params_file"

if [[ -f /etc/modprobe.d/usbcore.conf ]]; then
    if ! grep -q "autosuspend=-1" /etc/modprobe.d/usbcore.conf 2>/dev/null; then
        echo "options usbcore autosuspend=-1" >> /etc/modprobe.d/usbcore.conf
    fi
fi

log "Applied usbcore.autosuspend=-1 for USB hub stability"
exit 0