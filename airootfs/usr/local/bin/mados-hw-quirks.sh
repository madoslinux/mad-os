#!/usr/bin/env bash
set -euo pipefail

QUIRKS_DIR="/usr/local/lib/mados-hw-quirks.d"
LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

log() {
    printf '%s\n' "mados-hw-quirks: $*"
}

fallback_disable_token() {
    local cmdline token
    cmdline="$(cat /proc/cmdline 2>/dev/null || true)"

    for token in $cmdline; do
        if [[ "$token" == mados.disable_quirks=* ]]; then
            printf '%s\n' "${token#mados.disable_quirks=}"
            return 0
        fi
    done

    printf '%s\n' ""
}

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

if command -v hwq_is_global_disabled >/dev/null 2>&1; then
    if hwq_is_global_disabled; then
        log "disabled via kernel parameter mados.disable_quirks=1"
        exit 0
    fi
elif [[ "$(fallback_disable_token)" == "1" ]]; then
    log "disabled via kernel parameter mados.disable_quirks=1"
    exit 0
fi

if [[ ! -d "$QUIRKS_DIR" ]]; then
    log "quirks directory not found: $QUIRKS_DIR"
    exit 0
fi

applied=0

for quirk in "$QUIRKS_DIR"/*.sh; do
    [[ -f "$quirk" ]] || continue

    if ! bash "$quirk"; then
        log "quirk failed (non-fatal): $(basename "$quirk")"
        continue
    fi

    applied=$((applied + 1))
done

log "quirk scan completed; scripts executed: $applied"
exit 0
