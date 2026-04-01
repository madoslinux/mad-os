#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
ISO_VERSION=$(git -C "$SCRIPT_DIR" tag -l --sort=-version:refname 'v*' 2>/dev/null | head -1)
ISO_VERSION="${ISO_VERSION:-dev}"
ISO_VERSION="${ISO_VERSION#v}"

BASE_ISO="${OUT_DIR}/mados-${ISO_VERSION}.iso"
[[ ! -f "$BASE_ISO" ]] && BASE_ISO="${OUT_DIR}/madOS-dev-x86_64.iso"
FINAL_ISO="${OUT_DIR}/mados-${ISO_VERSION}-limine.iso"
TMP_ISO="/tmp/mados-${ISO_VERSION}-limine.iso"

echo ""
echo "  Patching existing ISO with Limine"
echo "  Base:  $(basename "$BASE_ISO")"
echo "  Output: $(basename "$FINAL_ISO")"
echo ""

for cmd in limine xorriso sudo; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "  ✗ $cmd not found"
        exit 1
    fi
done

if [[ ! -f "$BASE_ISO" ]]; then
    echo "  ✗ Base ISO not found: $BASE_ISO"
    exit 1
fi

ISO_MNT="/tmp/limine_mnt_$$"
ISO_EXTRACT="/tmp/limine_extract_$$"
mkdir -p "$ISO_MNT" "$ISO_EXTRACT"

cleanup() {
    sudo umount "$ISO_MNT" 2>/dev/null || true
    sudo rm -rf "$ISO_MNT" "$ISO_EXTRACT"
}
trap cleanup EXIT

echo "  [1/3] Extracting ISO..."
sudo mount -o ro,loop "$BASE_ISO" "$ISO_MNT"
sudo cp -a "$ISO_MNT"/* "$ISO_EXTRACT/"
sudo umount "$ISO_MNT"
echo "  ✓ Extracted"

echo ""
echo "  [2/3] Installing limine..."

# BIOS (isolinux -> limine)
if [[ -d "$ISO_EXTRACT/isolinux" ]]; then
    sudo cp /usr/share/limine/limine-bios.sys "$ISO_EXTRACT/isolinux/"
    sudo tee "$ISO_EXTRACT/limine.cfg" > /dev/null << 'LIMINECFG'
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
    echo "  ✓ BIOS limine installed"
fi

# UEFI
if [[ -d "$ISO_EXTRACT/EFI/BOOT" ]]; then
    [[ -f "$ISO_EXTRACT/EFI/BOOT/BOOTX64.EFI" ]] && sudo mv "$ISO_EXTRACT/EFI/BOOT/BOOTX64.EFI" "$ISO_EXTRACT/EFI/BOOT/BOOTX64.EFI.backup"
    sudo cp /usr/share/limine/BOOTX64.EFI "$ISO_EXTRACT/EFI/BOOT/"
    sudo cp /usr/share/limine/BOOTIA32.EFI "$ISO_EXTRACT/EFI/BOOT/" 2>/dev/null || true
    sudo tee "$ISO_EXTRACT/EFI/BOOT/limine.cfg" > /dev/null << 'LIMINECFG'
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
    echo "  ✓ UEFI limine installed"
fi

echo ""
echo "  [3/3] Creating limine ISO..."

sudo xorriso \
    -rockridge on \
    -joliet off \
    -outdev "$TMP_ISO" \
    -map "$ISO_EXTRACT" / \
    2>&1 | grep -v "^xorriso: warning" || true

if [[ -f "$TMP_ISO" ]]; then
    sudo mv "$TMP_ISO" "$FINAL_ISO"
fi

if [[ -f "$FINAL_ISO" ]]; then
    echo ""
    echo "  ✓ Done: $(basename "$FINAL_ISO") ($(du -h "$FINAL_ISO" | cut -f1))"
else
    echo ""
    echo "  ✗ Failed"
    exit 1
fi
