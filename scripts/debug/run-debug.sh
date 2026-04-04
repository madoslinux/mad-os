#!/usr/bin/env bash
# Run QEMU and save serial output to file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/out"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"
LOG_FILE="/tmp/qemu-serial.log"

if [ ! -f "$DISK_FILE" ]; then
    echo "No disk found"
    exit 1
fi

rm -f "$LOG_FILE"

echo "=== Running QEMU with serial log ==="
echo "Log: $LOG_FILE"
echo "Waiting for boot... (will timeout in 30s)"
echo ""

# Run in background and capture serial output
timeout 30 qemu-system-x86_64 \
    -m 4G \
    -smp 4 \
    -enable-kvm \
    -cpu host \
    -hda "$DISK_FILE" \
    -boot c \
    -serial file:"$LOG_FILE" \
    -display none \
    2>&1 || true

echo "=== Serial log output ==="
cat "$LOG_FILE"

echo ""
echo "=== Debug log ==="
if [ -f /tmp/qemu-debug.log ]; then
    cat /tmp/qemu-debug.log
fi
