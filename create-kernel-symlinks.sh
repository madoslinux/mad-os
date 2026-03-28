#!/usr/bin/env bash
# create-kernel-symlinks.sh
# Creates symlinks in /boot pointing to kernels in the work directory
# This is needed because mkinitcpio runs on the HOST system, not the chroot

set -e

WORK_DIR="${1:-.}"

echo "=== Creating kernel symlinks for mkinitcpio ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (for /boot access)"
    exit 1
fi

# Kernel versions in the airootfs
ZEN_KVER="6.19.10-zen1-1-zen"
LTS_KVER="6.18.20-1-lts"
ARCH_KVER="6.19.10-arch1-1"

AIROOTFS="${WORK_DIR}/work/x86_64/airootfs"

# Create symlinks for each kernel
for kver in "$ZEN_KVER" "$LTS_KVER" "$ARCH_KVER"; do
    SRC="${AIROOTFS}/usr/lib/modules/${kver}/vmlinuz"
    
    if [ -f "$SRC" ]; then
        case "$kver" in
            *-zen*)
                DEST="/boot/vmlinuz-linux-zen"
                ;;
            *-lts*)
                DEST="/boot/vmlinuz-linux-lts"
                ;;
            *)
                DEST="/boot/vmlinuz-linux"
                ;;
        esac
        
        # Backup existing if exists and is different
        if [ -L "$DEST" ]; then
            rm -f "$DEST"
        elif [ -f "$DEST" ]; then
            mv "$DEST" "${DEST}.backup"
        fi
        
        ln -sf "$SRC" "$DEST"
        echo "✓ Created symlink: $DEST -> $SRC"
    else
        echo "⚠ Kernel not found: $SRC"
    fi
done

echo "=== Kernel symlinks ready ==="
