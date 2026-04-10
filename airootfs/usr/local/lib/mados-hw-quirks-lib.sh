#!/usr/bin/env bash
set -euo pipefail

MADOS_QUIRKS_CMDLINE_PATH="${MADOS_QUIRKS_CMDLINE_PATH:-/proc/cmdline}"

hwq_log() {
    printf '%s\n' "mados-hw-quirks: $*"
}

hwq_get_disable_token() {
    local cmdline token
    cmdline="$(cat "$MADOS_QUIRKS_CMDLINE_PATH" 2>/dev/null || true)"

    for token in $cmdline; do
        if [[ "$token" == mados.disable_quirks=* ]]; then
            printf '%s\n' "${token#mados.disable_quirks=}"
            return 0
        fi
    done

    printf '%s\n' ""
    return 0
}

hwq_is_global_disabled() {
    [[ "$(hwq_get_disable_token)" == "1" ]]
}

hwq_is_group_disabled() {
    local group disable token
    group="${1:-}"
    disable="$(hwq_get_disable_token)"

    [[ -n "$group" ]] || return 1
    [[ -n "$disable" ]] || return 1

    for token in ${disable//,/ }; do
        [[ "$token" == "$group" ]] && return 0
    done

    return 1
}
