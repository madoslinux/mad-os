#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

step "5/5" "Verifying Limine boot entries"
log "stage: 50-verify-limine.sh"

require_cmd xorriso

[[ -f "${FINAL_ISO}" ]] || fail "Limine ISO missing: ${FINAL_ISO}"

BOOT_REPORT=$(xorriso -indev "${FINAL_ISO}" -report_el_torito as_mkisofs 2>/dev/null || true)

grep -q "limine-bios-cd.bin" <<< "${BOOT_REPORT}" || fail "Missing Limine BIOS El Torito entry"
grep -q "limine-uefi-cd.bin" <<< "${BOOT_REPORT}" || fail "Missing Limine UEFI El Torito entry"

if xorriso -indev "${FINAL_ISO}" -find / -name limine.conf 2>/dev/null | grep -q "/limine.conf"; then
    log "✓ limine.conf present"
else
    fail "limine.conf not found inside ISO"
fi

CONF_MATCHES=$(xorriso -indev "${FINAL_ISO}" -find / -name limine.conf 2>/dev/null | wc -l)
if [[ "${CONF_MATCHES}" -ne 1 ]]; then
    fail "Expected exactly one limine.conf, found ${CONF_MATCHES}"
fi

log "✓ Verified: Limine BIOS + UEFI boot entries present"
