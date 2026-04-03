#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

step "2/5" "Extracting ISO contents"
log "stage: 20-extract-base.sh"

[[ -f "${STATE_FILE}" ]] || fail "State file missing: ${STATE_FILE}"
source "${STATE_FILE}"

[[ -f "${BASE_ISO}" ]] || fail "Base ISO does not exist: ${BASE_ISO}"

mkdir -p "${ISO_MNT}" "${ISO_EXTRACT}"
mount -o ro,loop "${BASE_ISO}" "${ISO_MNT}"
cp -a "${ISO_MNT}"/. "${ISO_EXTRACT}/"
umount "${ISO_MNT}"

log "✓ Extracted to: ${ISO_EXTRACT}"
