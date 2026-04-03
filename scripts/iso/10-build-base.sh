#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

step "1/5" "Building base ISO with archiso"
log "stage: 10-build-base.sh"

require_cmd mkarchiso

mkarchiso -v -o "${OUT_DIR}" -w "${CLEAN_WORK}" "${REPO_DIR}"

BASE_ISO=""

if ls -t "${OUT_DIR}"/*.iso >/dev/null 2>&1; then
    BASE_ISO=$(ls -t "${OUT_DIR}"/*.iso | head -1)
fi

[[ -n "${BASE_ISO}" ]] || fail "Base ISO not found after mkarchiso"

log "✓ Base ISO: $(basename "${BASE_ISO}")"
echo "BASE_ISO=${BASE_ISO}" > "${STATE_FILE}"
