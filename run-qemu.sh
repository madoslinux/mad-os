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

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration"
else
    echo "KVM not available, using TCG"
fi

qemu-system-x86_64 \
    -m "$MEMORY" \
    -smp "$CPU" \
    -enable-kvm \
    -cdrom "$ISO_FILE" \
    -boot d \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -display gtk,grab-on-hover=on \
    "$@"