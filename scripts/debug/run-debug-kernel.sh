#!/usr/bin/env bash
# Run QEMU with kernel debug options

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

echo "=== Running with kernel debug ==="
echo "Press ESC to enter GRUB menu, then press 'e' to edit kernel line"
echo "Add: earlyprintk=serial console=ttyS0,115200"
echo ""

# Run con OVMF para UEFI boot si es necesario
qemu-system-x86_64 \
    -m 4G \
    -smp 4 \
    -enable-kvm \
    -cpu host \
    -hda "$DISK_FILE" \
    -boot c \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -vga virtio \
    -display sdl \
    -serial stdio \
    "$@"
