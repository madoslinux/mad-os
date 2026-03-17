#!/usr/bin/env bash
# Run QEMU con monitor redirect a archivo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

echo "=== Running QEMU with monitor log ==="
echo "Run this, wait for kernel panic, then Ctrl+C"
echo ""

# Run con QMP (QEMU Machine Protocol) para más debug
exec qemu-system-x86_64 \
    -m 4G \
    -smp 4 \
    -enable-kvm \
    -cpu host \
    -hda "$DISK_FILE" \
    -boot c \
    -net nic \
    -display sdl \
    -monitor stdio \
    -d all \
    -D /tmp/qemu-full.log \
    "$@"