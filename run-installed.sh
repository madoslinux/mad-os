#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No installed disk found at ${DISK_FILE}"
    echo "Run ./run-qemu.sh first to install madOS"
    exit 1
fi

echo "=== Running QEMU with installed disk ${DISK_FILE} ==="

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
RESOLUTION="${RESOLUTION:-1920x1080}"

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
    -hda "$DISK_FILE" \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -global virtio-vga.max_outputs=1 \
    -display sdl \
    -audiodev id=audio,driver=alsa \
    -device ich9-intel-hda \
    -device hda-output,audiodev=audio \
    "$@"