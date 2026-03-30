#!/usr/bin/env bash
#===============================================================================
# madOS ISO Build Script
#===============================================================================
# Builds a madOS ISO using archiso with custom kernel and apps.
#
# Usage:
#   sudo ./build-iso.sh
#
# Output:
#   out/madOS-*.iso
#===============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
WORK_DIR="${SCRIPT_DIR}/work"

# Get ISO version from git tag (e.g., v1.0.0 -> 1.0.0, or "dev" if no tag)
_iso_tag="$(git -C "$SCRIPT_DIR" tag -l --sort=-version:refname 'v*' 2>/dev/null | head -1)"
_iso_tag="${_iso_tag:-dev}"
_iso_tag="${_iso_tag#v}"  # Remove 'v' prefix

# Timestamped work directory to allow parallel builds
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CLEAN_WORK_DIR="${WORK_DIR}-${TIMESTAMP}"

#-------------------------------------------------------------------------------
# Helper functions
#-------------------------------------------------------------------------------

print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_step() {
    echo ""
    echo "▸ $1"
}

print_success() {
    echo "  ✓ $1"
}

print_error() {
    echo "  ✗ ERROR: $1" >&2
}

print_warning() {
    echo "  ⚠ WARNING: $1"
}

#-------------------------------------------------------------------------------
# Main build
#-------------------------------------------------------------------------------

print_header "madOS ISO Builder"

echo ""
echo "  Version:    ${_iso_tag}"
echo "  Output:     ${OUT_DIR}"
echo "  Work dir:   ${CLEAN_WORK_DIR}"
echo ""

# Create directories
mkdir -p "${OUT_DIR}" "${CLEAN_WORK_DIR}"

# Clean up old builds
print_step "Cleaning previous builds..."

# Remove old ISOs
if ls "${OUT_DIR}"/*.iso &>/dev/null; then
    sudo rm -f "${OUT_DIR}"/*.iso "${OUT_DIR}"/*.iso.*
    print_success "Removed old ISOs"
else
    print_success "No old ISOs to remove"
fi

# Remove old work directories (keep only current timestamped one)
sudo rm -rf "${WORK_DIR}-"* 2>/dev/null || true
print_success "Cleaned old work directories"

# Remove leftover .oh-my-zsh from previous builds
if [[ -d "$WORK_DIR/x86_64/airootfs/home/mados/.oh-my-zsh" ]]; then
    rm -rf "$WORK_DIR/x86_64/airootfs/home/mados/.oh-my-zsh"
    rm -rf "$WORK_DIR/x86_64/airootfs/root/.oh-my-zsh"
    print_success "Removed leftover .oh-my-zsh directories"
fi

# Build the ISO
print_header "Building ISO with archiso"
echo ""
echo "  This may take 10-20 minutes..."
echo ""

if ! sudo mkarchiso -v -o "${OUT_DIR}" -w "${CLEAN_WORK_DIR}" .; then
    print_error "archiso build failed"
    exit 1
fi

# Find the generated ISO
ISO_FILE=$(ls "${OUT_DIR}"/mados-${_iso_tag}-*.iso 2>/dev/null | head -1)
ISO_FILE="${ISO_FILE:-$(ls "${OUT_DIR}"/*.iso 2>/dev/null | head -1)}"

if [[ -z "$ISO_FILE" || ! -f "$ISO_FILE" ]]; then
    print_error "No ISO file found in ${OUT_DIR}"
    ls -la "${OUT_DIR}"/ | head -10
    exit 1
fi

# Get ISO size
ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)

# Done!
print_header "Build Complete!"
echo ""
echo "  ISO: ${ISO_FILE}"
echo "  Size: ${ISO_SIZE}"
echo ""
