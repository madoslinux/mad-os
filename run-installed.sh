#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
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

# Use standard IDE with -hda
echo "Starting QEMU with standard IDE disk..."
qemu-system-x86_64 \
    -m "$MEMORY" \
    -smp "$CPU" \
    -enable-kvm \
    -cpu host \
    -hda "$DISK_FILE" \
    -boot c \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -display sdl \
    "$@"