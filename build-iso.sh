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

# Build stages
declare -A STAGES=(
    ["prepare"]="Preparing system"
    ["pkgs"]="Installing packages"
    ["customize"]="Running customizations"
    ["syslinux"]="Setting up SYSLINUX"
    ["uefi"]="Setting up systemd-boot"
    ["sfs"]="Creating SquashFS"
    ["iso"]="Creating ISO image"
)

#-------------------------------------------------------------------------------
# Progress display
#-------------------------------------------------------------------------------

show_progress() {
    local stage="$1"
    local percent="$2"
    local total=8
    local current=0
    
    case "$stage" in
        prepare) current=1 ;;
        pkgs) current=2 ;;
        customize) current=3 ;;
        syslinux) current=4 ;;
        uefi) current=5 ;;
        sfs) current=6 ;;
        iso) current=7 ;;
    esac
    
    local p=$((percent > 100 ? 100 : percent))
    local filled=$(( (current * 100 / total) + (p / total) ))
    local bar_len=$(( filled * 40 / 100 ))
    local bar=""
    
    for i in {1..40}; do
        if [[ $i -le $bar_len ]]; then
            bar+="█"
        else
            bar+="░"
        fi
    done
    
    printf "\r  [%s] %-20s %3d%% " "$bar" "$stage" "$p"
}

#-------------------------------------------------------------------------------
# Main build
#-------------------------------------------------------------------------------

echo ""
echo "  madOS ISO Builder v${_iso_tag}"
echo ""

mkdir -p "${OUT_DIR}" "${CLEAN_WORK_DIR}"

printf "  Cleaning old builds..."
sudo rm -f "${OUT_DIR}"/*.iso "${OUT_DIR}"/*.iso.* 2>/dev/null || true
sudo rm -rf "${WORK_DIR}-"* 2>/dev/null || true
rm -rf "${WORK_DIR}/x86_64/airootfs/home/mados/.oh-my-zsh" 2>/dev/null || true
rm -rf "${WORK_DIR}/x86_64/airootfs/root/.oh-my-zsh" 2>/dev/null || true
echo -e "\r  ✓ Cleaned"
echo ""

echo "  Building ISO..."
echo ""

# Run mkarchiso
sudo mkarchiso -v -o "${OUT_DIR}" -w "${CLEAN_WORK_DIR}" . 2>&1 | while IFS= read -r line; do
    echo "  $line" >&2
    
    # Detect stage from output
    case "$line" in
        *"[mkarchiso] INFO: Installing packages"*)
            show_progress "pkgs" 50
            ;;
        *"[mkarchiso] INFO: Running customize_airootfs.sh"*)
            show_progress "customize" 60
            ;;
        *"[mkarchiso] INFO: Setting up syslinux"*)
            show_progress "syslinux" 70
            ;;
        *"[mkarchiso] INFO: Setting up UEFI"*)
            show_progress "uefi" 80
            ;;
        *"[mkarchiso] INFO: Creating SquashFS image"*)
            show_progress "sfs" 90
            ;;
        *"[mkarchiso] INFO: Creating ISO image"*)
            show_progress "iso" 95
            ;;
        *"[mkarchiso] INFO: Done!"*)
            show_progress "iso" 100
            echo ""
            ;;
        *"[mkarchiso] ERROR"*)
            echo ""
            echo "  ✗ Build failed: $line"
            exit 1
            ;;
    esac
done

echo ""

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
