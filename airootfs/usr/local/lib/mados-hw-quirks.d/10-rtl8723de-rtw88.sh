#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(10-rtl8723de): $*"
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

has_rtl8723de=0
while IFS= read -r line; do
    if [[ "$line" == *"[10ec:d723]"* ]]; then
        has_rtl8723de=1
        break
    fi
done < <(lspci -nn -D)

if [[ "$has_rtl8723de" -ne 1 ]]; then
    exit 0
fi

if ! modprobe -n rtw88_8723de >/dev/null 2>&1; then
    log "rtw88_8723de not available on this kernel"
    exit 0
fi

log "applying conditional rtw88 quirk"
modprobe -r rtw88_8723de rtw88_pci rtw88_core 2>/dev/null || true
modprobe rtw88_core disable_lps_deep=Y || true
modprobe rtw88_pci disable_aspm=Y || true
modprobe rtw88_8723de || true
exit 0
