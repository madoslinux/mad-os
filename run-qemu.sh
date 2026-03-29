#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
ISO_FILE=$(ls -t "${OUT_DIR}"/*.iso 2>/dev/null | head -1)

if [ -z "$ISO_FILE" ]; then
    echo "No ISO found in ${OUT_DIR}"
    exit 1
fi

echo "=== madOS QEMU Launcher ==="
echo ""

# Ask for sudo password if not already authenticated
if ! sudo -v 2>/dev/null; then
    echo "This script requires sudo privileges."
    echo "Please enter your password when prompted."
    if ! sudo -v; then
        echo "sudo authentication failed"
        exit 1
    fi
fi

# Extend sudo timestamp to avoid timeout during execution
while true; do
    sleep 60
    sudo -v 2>/dev/null || break &
done &
SUDO_KEEPALIVE=$!

cleanup() {
    kill "$SUDO_KEEPALIVE" 2>/dev/null || true
}

show_serial_log() {
    echo ""
    echo "=== Serial Log Contents ==="
    if [ -f "$SERIAL_LOG" ]; then
        cat "$SERIAL_LOG"
    else
        echo "Serial log not found: $SERIAL_LOG"
    fi
}

trap show_serial_log EXIT

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
RESOLUTION="${RESOLUTION:-1920x1080}"
DISK_SIZE="${DISK_SIZE:-10G}"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"

# Serial console output file for debugging
SERIAL_LOG="/tmp/mados-serial.log"
SERIAL_OPTS="-serial file:${SERIAL_LOG}"

# Create serial log file with proper permissions (owned by current user)
touch "$SERIAL_LOG" 2>/dev/null || sudo touch "$SERIAL_LOG"
chmod 666 "$SERIAL_LOG" 2>/dev/null || sudo chmod 666 "$SERIAL_LOG"

# Cleanup function to show serial log on exit
show_serial_log() {
    echo ""
    echo "=== Serial Log Contents ==="
    if [ -f "$SERIAL_LOG" ]; then
        cat "$SERIAL_LOG"
    else
        echo "Serial log not found: $SERIAL_LOG"
    fi
}

echo "Configuration:"
echo "  ISO: ${ISO_FILE}"
echo "  Memory: ${MEMORY}"
echo "  CPU: ${CPU}"
echo "  Disk: ${DISK_FILE}"
echo "  Serial log: ${SERIAL_LOG}"
echo ""

# Create virtual disk if it doesn't exist
if [ ! -f "$DISK_FILE" ]; then
    echo "Creating ${DISK_SIZE} virtual disk..."
    sudo qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
fi

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration (✓)"
    KVM_ACCEL="-enable-kvm -cpu host"
else
    echo "KVM not available, using TCG (software emulation)"
    KVM_ACCEL=""
fi

# UEFI firmware
UEFI_FW="/usr/share/edk2/x64/OVMF.4m.fd"
if [ ! -f "$UEFI_FW" ]; then
    UEFI_FW="/usr/share/edk2/ovmf/OVMF.4m.fd"
fi
if [ ! -f "$UEFI_FW" ]; then
    echo "WARNING: UEFI firmware not found, BIOS boot only"
    UEFI_FW=""
fi

echo ""
echo "Starting QEMU..."
echo "Serial output will be logged to: ${SERIAL_LOG}"
echo ""

if [ -n "$UEFI_FW" ]; then
    sudo qemu-system-x86_64 \
        -m "$MEMORY" \
        -smp "$CPU" \
        $KVM_ACCEL \
        -cdrom "$ISO_FILE" \
        -boot d \
        -drive file="$DISK_FILE",format=qcow2,if=virtio \
        -net nic \
        -net user,hostfwd=tcp::2222-:22 \
        -vga virtio \
        -global virtio-vga.max_outputs=1 \
        -display gtk \
        -bios "$UEFI_FW" \
        $SERIAL_OPTS \
        "$@"
else
    sudo qemu-system-x86_64 \
        -m "$MEMORY" \
        -smp "$CPU" \
        $KVM_ACCEL \
        -cdrom "$ISO_FILE" \
        -boot d \
        -drive file="$DISK_FILE",format=qcow2,if=virtio \
        -net nic \
        -net user,hostfwd=tcp::2222-:22 \
        -vga virtio \
        -global virtio-vga.max_outputs=1 \
        -display gtk \
        $SERIAL_OPTS \
        "$@"
fi
