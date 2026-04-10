#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(60-usb-wifi): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "usb"; then
    log "usb quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lsusb >/dev/null 2>&1; then
    exit 0
fi

if ! command -v grep >/dev/null 2>&1; then
    exit 0
fi

if ! lsusb | grep -Eq '(0bda:c811|0bda:b812|0bda:b82c|148f:7601|0e8d:7612|2357:010c)'; then
    exit 0
fi

if [[ ! -w /sys/module/usbcore/parameters/autosuspend ]]; then
    log "usbcore autosuspend parameter is not writable; skipping"
    exit 0
fi

log "known unstable USB Wi-Fi adapter detected; disabling usb autosuspend"
printf '%s\n' "-1" > /sys/module/usbcore/parameters/autosuspend || true
exit 0
