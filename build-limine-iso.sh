#!/usr/bin/env bash
# build-limine-iso.sh - Build madOS ISO with pure Limine bootloader
# This script:
# 1. Builds base ISO with archiso (syslinux for BIOS, systemd-boot for UEFI)
# 2. Extracts ISO contents
# 3. Replaces syslinux with limine for BIOS boot
# 4. Adds limine EFI files for UEFI boot
# 5. Reassembles the ISO

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
WORK_DIR="${SCRIPT_DIR}/work"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CLEAN_WORK="${WORK_DIR}-${TIMESTAMP}"
ISO_VERSION=$(git -C "$SCRIPT_DIR" tag -l --sort=-version:refname 'v*' 2>/dev/null | head -1)
ISO_VERSION="${ISO_VERSION:-dev}"
ISO_VERSION="${ISO_VERSION#v}"

echo ""
echo "  madOS ISO Builder with Limine v${ISO_VERSION}"
echo ""

# Check for required tools
for cmd in limine xorriso sudo mkarchiso; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "  ✗ $cmd not found. Install required packages."
        exit 1
    fi
done

# Clean old builds
echo "  Cleaning old builds..."
mkdir -p "${OUT_DIR}" "${CLEAN_WORK}"
rm -f "${OUT_DIR}"/*.iso "${OUT_DIR}"/*.iso.* 2>/dev/null || true
rm -rf "${WORK_DIR}-"* 2>/dev/null || true
echo "  ✓ Cleaned"
echo ""

# Step 1: Build base ISO with archiso
echo "  [1/5] Building base ISO with archiso..."
if ! sudo mkarchiso -v -o "${OUT_DIR}" -w "${CLEAN_WORK}" .; then
    echo "  ✗ mkarchiso failed"
    exit 1
fi

# Find generated ISO
BASE_ISO=$(ls "${OUT_DIR}"/mados-${ISO_VERSION}-*.iso 2>/dev/null | head -1)
BASE_ISO="${BASE_ISO:-$(ls "${OUT_DIR}"/*.iso 2>/dev/null | head -1)}"

if [[ -z "$BASE_ISO" ]]; then
    echo "  ✗ Base ISO not found"
    exit 1
fi
echo "  ✓ Base ISO: $(basename "$BASE_ISO")"

# Step 2: Extract ISO contents
echo ""
echo "  [2/5] Extracting ISO contents..."
ISO_MNT="/tmp/limine_mnt_$$"
ISO_EXTRACT="/tmp/limine_extract_$$"
mkdir -p "$ISO_MNT" "$ISO_EXTRACT"

sudo mount -o ro,loop "$BASE_ISO" "$ISO_MNT"
cp -a "$ISO_MNT"/* "$ISO_EXTRACT/"
sudo umount "$ISO_MNT"
rmdir "$ISO_MNT"
echo "  ✓ Extracted to: $ISO_EXTRACT"

# Step 3: Replace syslinux with limine for BIOS boot
echo ""
echo "  [3/5] Installing limine for BIOS boot..."

# Copy limine BIOS sys replacement
if [[ -d "$ISO_EXTRACT/isolinux" ]]; then
    # limine replaces syslinux
    cp /usr/share/limine/limine-bios.sys "$ISO_EXTRACT/isolinux/"
    
    # Create limine.cfg in the root
    cat > "$ISO_EXTRACT/limine.cfg" << 'LIMINECFG'
TIMEOUT: 10
DEFAULT: 1

:1
    COMMENT: madOS Live
    KERNEL: /arch/boot/x86_64/vmlinuz-linux-mados-zen
    INITRD: /arch/boot/x86_64/initramfs-linux-mados-zen.img
    PARAMETERS: archisobasedir=arch archisosearchuuid=ARCHISO_UUID cow_spacesize=256M quiet splash

:2
    COMMENT: madOS Live with Persistence
    KERNEL: /arch/boot/x86_64/vmlinuz-linux-mados-zen
    INITRD: /arch/boot/x86_64/initramfs-linux-mados-zen.img
    PARAMETERS: archisobasedir=arch archisosearchuuid=ARCHISO_UUID cow_label=mados-persist quiet splash

:3
    COMMENT: madOS Live (Safe Graphics)
    KERNEL: /arch/boot/x86_64/vmlinuz-linux-mados-zen
    INITRD: /arch/boot/x86_64/initramfs-linux-mados-zen.img
    PARAMETERS: archisobasedir=arch archisosearchuuid=ARCHISO_UUID cow_spacesize=256M nomodeset quiet splash
LIMINECFG
    
    echo "  ✓ Limine BIOS installed"
fi

# Step 4: Add limine for UEFI boot
echo ""
echo "  [4/5] Installing limine for UEFI boot..."

if [[ -d "$ISO_EXTRACT/EFI/BOOT" ]]; then
    # Backup original systemd-boot
    if [[ -f "$ISO_EXTRACT/EFI/BOOT/BOOTX64.EFI" ]]; then
        mv "$ISO_EXTRACT/EFI/BOOT/BOOTX64.EFI" "$ISO_EXTRACT/EFI/BOOT/BOOTX64.EFI.systemd-boot"
    fi
    
    # Copy limine EFI
    cp /usr/share/limine/BOOTX64.EFI "$ISO_EXTRACT/EFI/BOOT/"
    cp /usr/share/limine/BOOTIA32.EFI "$ISO_EXTRACT/EFI/BOOT/" 2>/dev/null || true
    
    # Create limine UEFI config
    cat > "$ISO_EXTRACT/EFI/BOOT/limine.cfg" << 'LIMINECFG'
TIMEOUT: 10
DEFAULT: 1

:1
    COMMENT: madOS Live
    KERNEL: /arch/boot/x86_64/vmlinuz-linux-mados-zen
    INITRD: /arch/boot/x86_64/initramfs-linux-mados-zen.img
    PARAMETERS: archisobasedir=arch archisosearchuuid=ARCHISO_UUID cow_spacesize=256M quiet splash

:2
    COMMENT: madOS Live with Persistence
    KERNEL: /arch/boot/x86_64/vmlinuz-linux-mados-zen
    INITRD: /arch/boot/x86_64/initramfs-linux-mados-zen.img
    PARAMETERS: archisobasedir=arch archisosearchuuid=ARCHISO_UUID cow_label=mados-persist quiet splash

:3
    COMMENT: madOS Live (Safe Graphics)
    KERNEL: /arch/boot/x86_64/vmlinuz-linux-mados-zen
    INITRD: /arch/boot/x86_64/initramfs-linux-mados-zen.img
    PARAMETERS: archisobasedir=arch archisosearchuuid=ARCHISO_UUID cow_spacesize=256M nomodeset quiet splash
LIMINECFG
    
    echo "  ✓ Limine UEFI installed"
fi

# Step 5: Create new ISO with limine
echo ""
echo "  [5/5] Creating limine ISO..."
FINAL_ISO="${OUT_DIR}/mados-${ISO_VERSION}-limine.iso"

# Use xorriso to create the ISO with limine boot sector
# The key is using limine-bios-cd.bin as the El Torito boot sector

xorriso -as mkisofs \
    -iso-level 3 \
    -boot-load-size 4 \
    -boot-info-table \
    -no-emul-boot \
    -output "$FINAL_ISO" \
    "$ISO_EXTRACT"

# Cleanup
rm -rf "$ISO_EXTRACT"

# Verify
if [[ -f "$FINAL_ISO" ]]; then
    FINAL_SIZE=$(du -h "$FINAL_ISO" | cut -f1)
    echo ""
    echo "  ✓ Done: $(basename "$FINAL_ISO") (${FINAL_SIZE})"
    echo ""
    echo "  Original ISO preserved: $(basename "$BASE_ISO")"
else
    echo ""
    echo "  ✗ Failed to create limine ISO"
    exit 1
fi
