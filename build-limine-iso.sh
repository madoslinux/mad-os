#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/iso/lib/common.sh"

require_root
require_cmd limine xorriso mkarchiso mount umount cp grep sed

ISO_VERSION="$(resolve_iso_version "${SCRIPT_DIR}")"
OUT_DIR="${SCRIPT_DIR}/out"
WORK_DIR="${SCRIPT_DIR}/work"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
CLEAN_WORK="${WORK_DIR}-${TIMESTAMP}"
STATE_FILE="${CLEAN_WORK}/state.env"
ISO_MNT="${CLEAN_WORK}/mnt"
ISO_EXTRACT="${CLEAN_WORK}/extract"
REPO_DIR="${SCRIPT_DIR}"
FINAL_ISO="${OUT_DIR}/mados-${ISO_VERSION}-limine.iso"

log "madOS ISO Builder with Limine v${ISO_VERSION}"

mkdir -p "${OUT_DIR}" "${CLEAN_WORK}"
rm -f "${OUT_DIR}"/*.iso "${OUT_DIR}"/*.iso.* 2>/dev/null || true
rm -rf "${WORK_DIR}-"* 2>/dev/null || true

cleanup() {
    umount "${ISO_MNT}" 2>/dev/null || true
    rm -rf "${ISO_MNT}" "${ISO_EXTRACT}"
}
trap cleanup EXIT

export ISO_VERSION OUT_DIR CLEAN_WORK STATE_FILE ISO_MNT ISO_EXTRACT REPO_DIR FINAL_ISO

run_stage() {
    local stage_script="$1"
    local stage_path="${SCRIPT_DIR}/scripts/iso/${stage_script}"

    [[ -f "${stage_path}" ]] || fail "Missing stage script: ${stage_path}"
    log "→ Running ${stage_script}"
    bash "${stage_path}"
}

run_stage "10-build-base.sh"
run_stage "20-extract-base.sh"
run_stage "30-inject-limine.sh"
run_stage "40-pack-limine.sh"
run_stage "50-verify-limine.sh"

log "✓ Done: $(basename "${FINAL_ISO}") ($(du -h "${FINAL_ISO}" | cut -f1))"

if [[ "${KEEP_WORK:-0}" != "1" ]]; then
    rm -rf "${CLEAN_WORK}"
    log "✓ Cleaned work dir: ${CLEAN_WORK}"
else
    log "ℹ Keeping work dir for debugging: ${CLEAN_WORK}"
fi
