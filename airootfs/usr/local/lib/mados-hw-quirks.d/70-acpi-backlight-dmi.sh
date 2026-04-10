#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(70-acpi-backlight): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "acpi"; then
    log "acpi quirks disabled via mados.disable_quirks"
    exit 0
fi

if [[ ! -r /sys/class/dmi/id/sys_vendor ]] || [[ ! -r /sys/class/dmi/id/product_name ]]; then
    exit 0
fi

vendor="$(tr '[:upper:]' '[:lower:]' < /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
product="$(tr '[:upper:]' '[:lower:]' < /sys/class/dmi/id/product_name 2>/dev/null || true)"

if [[ -z "$vendor" && -z "$product" ]]; then
    exit 0
fi

if [[ "$vendor $product" != *"asus"* ]] && [[ "$vendor $product" != *"lenovo"* ]] && [[ "$vendor $product" != *"ideapad"* ]] && [[ "$vendor $product" != *"thinkpad"* ]]; then
    exit 0
fi

if [[ -d /sys/class/backlight/intel_backlight ]] || [[ -d /sys/class/backlight/amdgpu_bl0 ]]; then
    exit 0
fi

log "possible DMI backlight issue detected; requesting acpi video module"
if command -v modprobe >/dev/null 2>&1; then
    modprobe video 2>/dev/null || true
fi
exit 0
