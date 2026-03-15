#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
WORK_DIR="${SCRIPT_DIR}/work"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CLEAN_WORK_DIR="${WORK_DIR}-${TIMESTAMP}"

echo "=== Building madOS ISO ==="
echo "Output: ${OUT_DIR}"
echo "Work:   ${CLEAN_WORK_DIR}"
echo ""

mkdir -p "${OUT_DIR}" "${CLEAN_WORK_DIR}"

echo "Cleaning previous ISOs..."
sudo rm -f "${OUT_DIR}"/*.iso "${OUT_DIR}"/*.iso.* || true
sudo rm -rf "${WORK_DIR}"-* || true

if [[ -d "$WORK_DIR" && -d "$WORK_DIR/x86_64/airootfs/home/mados" ]]; then
    echo "Cleaning previous .oh-my-zsh from work dir..."
    rm -rf "$WORK_DIR/x86_64/airootfs/home/mados/.oh-my-zsh" 2>/dev/null || true
    rm -rf "$WORK_DIR/x86_64/airootfs/root/.oh-my-zsh" 2>/dev/null || true
fi

sudo mkarchiso \
    -o "${OUT_DIR}" \
    -w "${CLEAN_WORK_DIR}" \
    -v \
    .

echo ""
echo "=== Build complete ==="
ls -lh "${OUT_DIR}"/*.iso || echo "No ISO found in ${OUT_DIR}"