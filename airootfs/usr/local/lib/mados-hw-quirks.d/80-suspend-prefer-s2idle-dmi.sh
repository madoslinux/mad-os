#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(80-suspend-s2idle): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "suspend"; then
    log "suspend quirks disabled via mados.disable_quirks"
    exit 0
fi

if [[ ! -w /sys/power/mem_sleep ]]; then
    exit 0
fi

mem_sleep="$(cat /sys/power/mem_sleep 2>/dev/null || true)"
if [[ "$mem_sleep" != *"s2idle"* ]] || [[ "$mem_sleep" != *"deep"* ]]; then
    exit 0
fi

if [[ ! -r /sys/class/dmi/id/sys_vendor ]] || [[ ! -r /sys/class/dmi/id/product_name ]]; then
    exit 0
fi

vendor="$(tr '[:upper:]' '[:lower:]' < /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
product="$(tr '[:upper:]' '[:lower:]' < /sys/class/dmi/id/product_name 2>/dev/null || true)"

if [[ "$vendor $product" != *"lenovo"* ]] && [[ "$vendor $product" != *"ideapad"* ]] && [[ "$vendor $product" != *"asus"* ]] && [[ "$vendor $product" != *"vivobook"* ]] && [[ "$vendor $product" != *"acer"* ]] && [[ "$vendor $product" != *"aspire"* ]]; then
    exit 0
fi

if [[ "$mem_sleep" == *"[s2idle]"* ]]; then
    exit 0
fi

log "DMI profile matched; preferring s2idle over deep for suspend stability"
printf '%s\n' "s2idle" > /sys/power/mem_sleep || true
exit 0
