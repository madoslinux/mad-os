#!/usr/bin/env bash
# run-qemu.sh - Boot madOS ISO in QEMU

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"

# Find ISO
ISO=$(ls "${OUT_DIR}"/*.iso 2>/dev/null | grep -i limine | head -1)
ISO="${ISO:-$(ls "${OUT_DIR}"/*.iso 2>/dev/null | head -1)}"

if [[ -z "$ISO" ]]; then
    echo "No ISO found in ${OUT_DIR}"
    exit 1
fi

echo "Booting: $(basename "$ISO")"

# QEMU command
exec qemu-system-x86_64 \
    -m 4G \
    -smp 2 \
    -cdrom "$ISO" \
    -boot order=dc \
    -enable-kvm \
    -cpu host \
    -vga virtio \
    -display sdl \
    -soundpcspk \
    -net nic \
    -net user,hostfwd=tcp::2222-:22
