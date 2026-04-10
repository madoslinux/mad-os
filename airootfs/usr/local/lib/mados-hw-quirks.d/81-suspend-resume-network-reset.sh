#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"
STATE_DIR="/run/mados"
STATE_FILE="/run/mados/suspend-reset-needed"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(81-suspend-net): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "suspend"; then
    log "suspend quirks disabled via mados.disable_quirks"
    exit 0
fi

mkdir -p "$STATE_DIR"

if [[ ! -r /sys/class/dmi/id/sys_vendor ]] || [[ ! -r /sys/class/dmi/id/product_name ]]; then
    exit 0
fi

vendor="$(tr '[:upper:]' '[:lower:]' < /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
product="$(tr '[:upper:]' '[:lower:]' < /sys/class/dmi/id/product_name 2>/dev/null || true)"

if [[ "$vendor $product" != *"lenovo"* ]] && [[ "$vendor $product" != *"ideapad"* ]] && [[ "$vendor $product" != *"hp"* ]] && [[ "$vendor $product" != *"probook"* ]] && [[ "$vendor $product" != *"dell"* ]] && [[ "$vendor $product" != *"inspiron"* ]]; then
    exit 0
fi

if command -v lspci >/dev/null 2>&1 && lspci -nn -D | grep -Eqi 'Network controller \[0280\].*\[(10ec|8086):[0-9a-f]{4}\]'; then
    printf '%s\n' "1" > "$STATE_FILE"
    log "resume network reset marker enabled for known DMI profile"
fi

exit 0
