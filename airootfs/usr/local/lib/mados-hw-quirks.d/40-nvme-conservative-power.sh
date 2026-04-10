#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(40-nvme): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "storage"; then
    log "storage quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

if ! command -v modprobe >/dev/null 2>&1; then
    exit 0
fi

if ! lspci -nn -D | grep -Eqi '\[0108\]'; then
    exit 0
fi

if ! modprobe -n nvme_core >/dev/null 2>&1; then
    exit 0
fi

log "nvme controller detected; disabling APST for compatibility"
modprobe -r nvme nvme_core 2>/dev/null || true
modprobe nvme_core default_ps_max_latency_us=0 || true
modprobe nvme || true
exit 0
