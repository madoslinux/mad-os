#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(31-amdgpu): $*"
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

if ! lspci -nn -D | grep -Eqi 'VGA compatible controller.*\[(1002|1022):[0-9a-f]{4}\]'; then
    exit 0
fi

if ! modprobe -n amdgpu >/dev/null 2>&1; then
    exit 0
fi

log "amd gpu detected; applying conservative amdgpu power tuning"
modprobe -r amdgpu 2>/dev/null || true
modprobe amdgpu aspm=0 || true
exit 0
