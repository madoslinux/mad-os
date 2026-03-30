#!/usr/bin/env bash
#===============================================================================
# madOS ISO Build Script
#===============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
WORK_DIR="${SCRIPT_DIR}/work"

# Get ISO version from git tag
_iso_tag="$(git -C "$SCRIPT_DIR" tag -l --sort=-version:refname 'v*' 2>/dev/null | head -1)"
_iso_tag="${_iso_tag:-dev}"
_iso_tag="${_iso_tag#v}"

# Timestamped work directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CLEAN_WORK_DIR="${WORK_DIR}-${TIMESTAMP}"

#-------------------------------------------------------------------------------
# Progress bar
#-------------------------------------------------------------------------------
spin() {
    local pid=$1
    local delay=0.1
    local chars=('▸▸' '▸▸' '▸ ▸' ' ▸▸')
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r  Building... %s" "${chars[i]}"
        i=$(( (i+1) % 4 ))
        sleep $delay
    done
    wait $pid
    return $?
}

#-------------------------------------------------------------------------------
# Main build
#-------------------------------------------------------------------------------

echo ""
echo "  madOS ISO Builder v${_iso_tag}"
echo ""

# Create directories
mkdir -p "${OUT_DIR}" "${CLEAN_WORK_DIR}"

# Clean old ISOs
printf "  Cleaning..."
sudo rm -f "${OUT_DIR}"/*.iso "${OUT_DIR}"/*.iso.* 2>/dev/null || true
sudo rm -rf "${WORK_DIR}-"* 2>/dev/null || true
rm -rf "${WORK_DIR}/x86_64/airootfs/home/mados/.oh-my-zsh" 2>/dev/null || true
rm -rf "${WORK_DIR}/x86_64/airootfs/root/.oh-my-zsh" 2>/dev/null || true
echo -e "\r  ✓ Cleaned"

# Build with progress
printf "  Building ISO..."
echo ""

# Run mkarchiso in background and capture output
mkarchiso_output=$(sudo mkarchiso -o "${OUT_DIR}" -w "${CLEAN_WORK_DIR}" . 2>&1) &
pid=$!
spin $pid
wait $pid
exit_code=$?

# Check for warnings/errors
warnings=$(echo "$mkarchiso_output" | grep -c "WARNING" || true)
errors=$(echo "$mkarchiso_output" | grep -cE "ERROR|FAIL" || true)

if [[ $exit_code -ne 0 ]] || [[ $errors -gt 0 ]]; then
    echo ""
    echo "$mkarchiso_output" | grep -E "^\[mkarchiso\] (ERROR|FAIL)" || echo "  ✗ Build failed"
    exit 1
fi

# Show warnings if any
if [[ $warnings -gt 0 ]]; then
    echo "$mkarchiso_output" | grep "WARNING" | sed 's/^/  ⚠ /'
fi

# Find ISO
ISO_FILE=$(ls "${OUT_DIR}"/mados-${_iso_tag}-*.iso 2>/dev/null | head -1)
ISO_FILE="${ISO_FILE:-$(ls "${OUT_DIR}"/*.iso 2>/dev/null | head -1)}"

if [[ -z "$ISO_FILE" ]]; then
    echo "  ✗ ISO not found"
    exit 1
fi

ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)

echo ""
echo "  ✓ Done: ${ISO_FILE##*/} (${ISO_SIZE})"
echo ""
