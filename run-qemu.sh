#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
ISO_FILE=$(ls -t "${OUT_DIR}"/*.iso 2>/dev/null | head -1)

if [ -z "$ISO_FILE" ]; then
    echo "No ISO found in ${OUT_DIR}"
    exit 1
fi

echo "=== Running QEMU with ${ISO_FILE} ==="

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
RESOLUTION="${RESOLUTION:-1920x1080}"
XRES="${RESOLUTION%x*}"
YRES="${RESOLUTION#*x}"
DISK_SIZE="${DISK_SIZE:-10G}"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

# Create virtual disk if it doesn't exist
if [ ! -f "$DISK_FILE" ]; then
    echo "Creating ${DISK_SIZE} virtual disk at ${DISK_FILE}..."
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
fi

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration"
else
    echo "KVM not available, using TCG"
fi

qemu-system-x86_64 \
    -m "$MEMORY" \
    -smp "$CPU" \
    -enable-kvm \
    -cpu host \
    -cdrom "$ISO_FILE" \
    -boot d \
    -hda "$DISK_FILE" \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -global virtio-vga.max_outputs=1 \
    -display sdl \
    -audiodev id=audio,driver=alsa \
    -device ich9-intel-hda \
    -device hda-output,audiodev=audio \
    -bios /usr/share/edk2/x64/OVMF.4m.fd \
    "$@"