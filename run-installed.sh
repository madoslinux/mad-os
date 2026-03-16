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

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration"
else
    echo "KVM not available, using TCG"
fi

echo "Starting QEMU with SCSI disk..."
qemu-system-x86_64 \
    -m "$MEMORY" \
    -smp "$CPU" \
    -enable-kvm \
    -cpu host \
    -drive file="$DISK_FILE",format=qcow2,if=scsi,index=0,media=disk \
    -boot c \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -global virtio-vga.max_outputs=1 \
    -display sdl \
    -audiodev id=audio,driver=alsa \
    -device ich9-intel-hda \
    -device hda-output,audiodev=audio \
    -device lsi53c895a \
    "$@"