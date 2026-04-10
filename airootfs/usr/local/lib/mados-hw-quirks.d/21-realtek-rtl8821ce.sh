#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(21-rtl8821ce): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "wifi"; then
    log "wifi quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    log "lspci not available; skipping"
    exit 0
fi

if ! command -v modprobe >/dev/null 2>&1; then
    log "modprobe not available; skipping"
    exit 0
fi

if ! lspci -nn -D | grep -Eqi '\[10ec:c821\]'; then
    exit 0
fi

if ! modprobe -n rtl8821ce >/dev/null 2>&1; then
    log "rtl8821ce module not available on this kernel"
    exit 0
fi

log "realtek rtl8821ce detected; disabling ASPM and deep power save"
modprobe -r rtl8821ce 2>/dev/null || true
modprobe rtl8821ce ips=0 fwlps=0 aspm=0 || true
exit 0
