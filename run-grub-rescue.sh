#!/usr/bin/env bash
# Run QEMU with GRUB rescue shell

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

echo "=== Running QEMU with GRUB rescue ==="
echo "When GRUB loads, press 'c' for command line"
echo "Then type: ls, ls (hd0,msdos1)/boot, ls (hd0,msdos2)/boot"
echo ""

# Set GRUB to timeout immediately and drop to shell
# Create a temporary overlay to add GRUB variables

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"

# Run with no default boot, drop to GRUB shell
exec qemu-system-x86_64 \
    -m "$MEMORY" \
    -smp "$CPU" \
    -enable-kvm \
    -cpu host \
    -hda "$DISK_FILE" \
    -boot c \
    -net nic \
    -nographic \
    -serial mon:stdio \
    "$@"