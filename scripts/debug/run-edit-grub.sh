#!/usr/bin/env bash
# Run QEMU and wait for user to manually edit GRUB

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

echo "=== QEMU will boot from disk ==="
echo "Wait for GRUB menu (may take a few seconds)..."
echo "When GRUB menu appears:"
echo "  1. Press 'e' to edit"
echo "  2. Find line with 'linux /boot/vmlinuz-linux'"
echo "  3. Add: earlyprintk=serial console=ttyS0,115200"
echo "  4. Ctrl+X to boot"
echo ""

exec qemu-system-x86_64 \
    -m 4G \
    -smp 4 \
    -enable-kvm \
    -cpu host \
    -hda "$DISK_FILE" \
    -boot c \
    -net nic \
    -display sdl \
    -serial stdio
