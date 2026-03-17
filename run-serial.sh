#!/usr/bin/env bash
# Run QEMU with serial console to see boot messages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

echo "=== Running QEMU with serial console ==="
echo "Disk: $DISK_FILE"
echo ""

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"

# Run with serial output to console, more verbose
exec qemu-system-x86_64 \
    -m "$MEMORY" \
    -smp "$CPU" \
    -enable-kvm \
    -cpu host \
    -hda "$DISK_FILE" \
    -boot c \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -nographic \
    -serial mon:stdio \
    -debugcon file:/tmp/qemu-debug.log \
    -d int,cpu_reset \
    "$@"