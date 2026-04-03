#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

step "4/5" "Packing Limine ISO (BIOS + UEFI)"
log "stage: 40-pack-limine.sh"

require_cmd xorriso limine

[[ -d "${ISO_EXTRACT}" ]] || fail "ISO extract dir missing: ${ISO_EXTRACT}"

MKISOFS_ARGS=(
    -iso-level 3
    -full-iso9660-filenames
    -volid "MADOS_LIMINE"
    -eltorito-boot limine-bios-cd.bin
    -boot-load-size 4
    -boot-info-table
    -no-emul-boot
    -eltorito-alt-boot
    -e limine-uefi-cd.bin
    -no-emul-boot
    -isohybrid-gpt-basdat
)

if xorriso -as mkisofs -help 2>&1 | grep -q -- "-udf"; then
    MKISOFS_ARGS+=( -udf )
    log "Using xorriso -udf support"
else
    log "xorriso -as mkisofs has no -udf support; building without -udf"
fi

xorriso -as mkisofs \
    "${MKISOFS_ARGS[@]}" \
    -output "${FINAL_ISO}" \
    "${ISO_EXTRACT}"

limine bios-install "${FINAL_ISO}" >/dev/null

[[ -f "${FINAL_ISO}" ]] || fail "Failed to create ${FINAL_ISO}"
log "✓ Built: $(basename "${FINAL_ISO}")"
