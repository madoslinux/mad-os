#!/usr/bin/env bash
# Run QEMU with explicit IDE disk controller

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

echo "=== Running with IDE controller ==="

# Use -device ide-hd to explicitly create IDE disk
exec qemu-system-x86_64 \
    -m 4G \
    -smp 4 \
    -enable-kvm \
    -cpu host \
    -drive file="$DISK_FILE",format=qcow2,if=ide,index=0,media=disk \
    -boot c \
    -net nic \
    -display sdl \
    -serial stdio