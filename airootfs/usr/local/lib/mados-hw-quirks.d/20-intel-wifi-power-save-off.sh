#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(20-intel-wifi): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "wifi"; then
    log "wifi quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

if ! command -v modprobe >/dev/null 2>&1; then
    exit 0
fi

if ! lspci -nn -D | grep -Eqi 'Network controller \[0280\].*\[8086:[0-9a-f]{4}\]'; then
    exit 0
fi

if ! modprobe -n iwlwifi >/dev/null 2>&1; then
    exit 0
fi

log "intel device detected; disabling iwlwifi power_save"
modprobe -r iwlmvm iwlwifi 2>/dev/null || true
modprobe iwlwifi power_save=0 || true
exit 0
