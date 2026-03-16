#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
ISO_FILE=$(ls -t "${OUT_DIR}"/*.iso 2>/dev/null | head -1)
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No installed disk found at ${DISK_FILE}"
    exit 1
fi

echo "=== Running QEMU with installed disk ${DISK_FILE} ==="
[ -n "$ISO_FILE" ] && echo "ISO available: ${ISO_FILE}"

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
BOOT="${BOOT:-disk}"  # disk, iso, or both

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration"
else
    echo "KVM not available, using TCG"
fi

# Build boot options based on BOOT variable
case "$BOOT" in
    disk)
        echo "Booting from disk only"
        BOOT_OPT="-boot c -hda $DISK_FILE"
        ;;
    iso)
        echo "Booting from ISO only"
        [ -z "$ISO_FILE" ] && echo "No ISO found" && exit 1
        BOOT_OPT="-boot d -cdrom $ISO_FILE"
        ;;
    both|recovery)
        echo "Booting from ISO (for recovery)"
        [ -z "$ISO_FILE" ] && echo "No ISO found" && exit 1
        BOOT_OPT="-boot d -hda $DISK_FILE -cdrom $ISO_FILE"
        ;;
    *)
        echo "Unknown boot option: $BOOT"
        echo "Usage: BOOT=disk|iso|both ./run-installed.sh"
        exit 1
        ;;
esac

qemu-system-x86_64 \
    -m "$MEMORY" \
    -smp "$CPU" \
    -enable-kvm \
    -cpu host \
    $BOOT_OPT \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -global virtio-vga.max_outputs=1 \
    -display sdl \
    -audiodev id=audio,driver=alsa \
    -device ich9-intel-hda \
    -device hda-output,audiodev=audio \
    "$@"