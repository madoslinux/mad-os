#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(30-intel-i915): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "gpu"; then
    log "gpu quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

if ! command -v modprobe >/dev/null 2>&1; then
    exit 0
fi

if ! lspci -nn -D | grep -Eqi 'VGA compatible controller.*\[8086:[0-9a-f]{4}\]'; then
    exit 0
fi

if ! modprobe -n i915 >/dev/null 2>&1; then
    exit 0
fi

log "intel i915 detected; disabling PSR/FBC for stability"
modprobe -r i915 2>/dev/null || true
modprobe i915 enable_psr=0 enable_fbc=0 || true
exit 0
