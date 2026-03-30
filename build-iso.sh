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
echo ""

# Run mkarchiso and show stages
echo "  Building ISO..."
echo ""

sudo mkarchiso -o "${OUT_DIR}" -w "${CLEAN_WORK_DIR}" . 2>&1 | while IFS= read -r line; do
    # Parse mkarchiso stages
    if [[ "$line" =~ ^\[mkarchiso\]\ INFO:\ (.*) ]]; then
        stage="${BASH_REMATCH[1]}"
        # Shorten common stages
        stage="${stage//Copying/•}"
        stage="${stage//Creating/•}"
        stage="${stage//Preparing/•}"
        stage="${stage//Running/•}"
        stage="${stage//Setting up/•}"
        stage="${stage//Generating/•}"
        stage="${stage//Done!/✓}"
        printf "\r    %-50s " "$stage"
    elif [[ "$line" =~ ^\[mkarchiso\]\ (WARNING|ERROR|FAIL) ]]; then
        printf "\n  ⚠ %s\n" "$line"
    fi
done

echo ""

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
