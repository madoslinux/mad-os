#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
ISO_FILE=$(ls -t "${OUT_DIR}"/*.iso 2>/dev/null | head -1)
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No installed disk found at ${DISK_FILE}"
    echo "Run ./run-qemu.sh first to install madOS"
    exit 1
fi

echo "=== Running QEMU with installed disk ${DISK_FILE} ==="

# Allow booting from disk (c) or ISO (d) or both
BOOT_ORDER="${BOOT_ORDER:-c}"  # default: boot from disk first

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
RESOLUTION="${RESOLUTION:-1920x1080}"

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration"
else
    echo "KVM not available, using TCG"
fi

# Build qemu command
QEMU_CMD="qemu-system-x86_64 \
    -m $MEMORY \
    -smp $CPU \
    -enable-kvm \
    -cpu host \
    -hda $DISK_FILE \
    -boot order=$BOOT_ORDER"

# Add ISO if it exists and we want to boot from both
if [ -n "$ISO_FILE" ] && [ "$BOOT_ORDER" = "dc" ] || [ "$BOOT_ORDER" = "cd" ]; then
    echo "Also adding CD-ROM: $ISO_FILE"
    QEMU_CMD="$QEMU_CMD -cdrom $ISO_FILE"
fi

QEMU_CMD="$QEMU_CMD \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -global virtio-vga.max_outputs=1 \
    -display sdl \
    -audiodev id=audio,driver=alsa \
    -device ich9-intel-hda \
    -device hda-output,audiodev=audio"

echo "Boot order: $BOOT_ORDER (c=disk, d=cdrom)"
echo "Command: $QEMU_CMD"

eval $QEMU_CMD "$@"