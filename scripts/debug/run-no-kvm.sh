#!/usr/bin/env bash
# Run QEMU without KVM for debugging

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

echo "=== Running QEMU WITHOUT KVM (slower but more compatible) ==="

exec qemu-system-x86_64 \
    -m 2G \
    -smp 2 \
    -hda "$DISK_FILE" \
    -boot c \
    -net nic \
    -display sdl \
    -serial stdio
