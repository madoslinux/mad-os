#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

step "3/5" "Injecting Limine BIOS/UEFI files"
log "stage: 30-inject-limine.sh"

require_cmd limine

[[ -d "${ISO_EXTRACT}" ]] || fail "ISO extract dir missing: ${ISO_EXTRACT}"
[[ -f "${REPO_DIR}/limine/limine.cfg" ]] || fail "Missing limine/limine.cfg"

ARCHISO_UUID=$(grep -Rho 'archisosearchuuid=[^ ]*' "${ISO_EXTRACT}" 2>/dev/null | head -1 | cut -d= -f2)
[[ -n "${ARCHISO_UUID}" ]] || fail "Could not detect archisosearchuuid"

mkdir -p "${ISO_EXTRACT}/EFI/BOOT"
cp /usr/share/limine/limine-bios.sys "${ISO_EXTRACT}/"
cp /usr/share/limine/limine-bios-cd.bin "${ISO_EXTRACT}/"
cp /usr/share/limine/limine-uefi-cd.bin "${ISO_EXTRACT}/"
cp /usr/share/limine/BOOTX64.EFI "${ISO_EXTRACT}/EFI/BOOT/"
cp /usr/share/limine/BOOTIA32.EFI "${ISO_EXTRACT}/EFI/BOOT/" 2>/dev/null || true

cp "${REPO_DIR}/limine/limine.cfg" "${ISO_EXTRACT}/limine.conf"
sed -i "s/ARCHISO_UUID/${ARCHISO_UUID}/g" "${ISO_EXTRACT}/limine.conf"

# Keep a single authoritative config to avoid UEFI volume ambiguity.
# Limine will discover /limine.conf from the boot volume.
rm -f "${ISO_EXTRACT}/EFI/BOOT/limine.conf" 2>/dev/null || true
rm -f "${ISO_EXTRACT}/limine.cfg" 2>/dev/null || true
rm -f "${ISO_EXTRACT}/EFI/BOOT/limine.cfg" 2>/dev/null || true

rm -rf "${ISO_EXTRACT}/isolinux" 2>/dev/null || true
rm -f "${ISO_EXTRACT}/EFI/BOOT/BOOTX64.EFI.systemd-boot" 2>/dev/null || true
rm -f "${ISO_EXTRACT}/EFI/BOOT/BOOTX64.EFI.backup" 2>/dev/null || true

log "✓ Detected archiso UUID: ${ARCHISO_UUID}"
log "✓ Limine files installed"
