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

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
RESOLUTION="${RESOLUTION:-1920x1080}"
DISK_SIZE="${DISK_SIZE:-30G}"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"
RENDER_MODE="${RENDER_MODE:-auto}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --software-render)
            RENDER_MODE="software"
            shift
            ;;
        --virtio-render)
            RENDER_MODE="auto"
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Serial console output file for debugging (in OUT_DIR to avoid permissions)
SERIAL_LOG="${OUT_DIR}/mados-serial.log"
SERIAL_OPTS="-serial file:${SERIAL_LOG}"

# Create serial log file with sudo (out dir is owned by root)
sudo rm -f "$SERIAL_LOG"
sudo bash -c "echo -n '' > '$SERIAL_LOG' && chmod 666 '$SERIAL_LOG'"

echo "Configuration:"
echo "  ISO: ${ISO_FILE}"
echo "  Memory: ${MEMORY}"
echo "  CPU: ${CPU}"
echo "  Disk: ${DISK_FILE}"
echo "  Render mode: ${RENDER_MODE}"
echo "  Serial log: ${SERIAL_LOG}"
echo ""

# Create virtual disk if it doesn't exist (default 30GB)
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

if [[ "$RENDER_MODE" == "software" ]]; then
    echo "Using software rendering mode (virtio DRM + GL off)"
    echo "Hint: this mode keeps DRM (for wlroots) but forces software rendering in guest"
    VIDEO_OPTS=(-vga virtio -global virtio-vga.max_outputs=1 -display gtk,gl=off)
    DMI_OPTS=(-smbios type=1,product=madOS-QEMU-SWRENDER)
else
    echo "Using virtio rendering mode"
    VIDEO_OPTS=(-vga virtio -global virtio-vga.max_outputs=1 -display gtk)
    DMI_OPTS=()
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

# Build QEMU command
QEMU_CMD=(
    qemu-system-x86_64
    -m "$MEMORY"
    -smp "$CPU"
    $KVM_ACCEL
    -cdrom "$ISO_FILE"
    -boot d
    -drive file="$DISK_FILE",format=qcow2,if=virtio
    -net nic
    -net user,hostfwd=tcp::2222-:22
    "${VIDEO_OPTS[@]}"
    "${DMI_OPTS[@]}"
    -device qemu-xhci
    -device usb-tablet
    $SERIAL_OPTS
)

if [ -n "$UEFI_FW" ]; then
    QEMU_CMD+=(-bios "$UEFI_FW")
fi

echo ""
echo "Starting QEMU..."
echo "Serial output will be logged to: ${SERIAL_LOG}"
echo ""

# Start QEMU in background
sudo "${QEMU_CMD[@]}" "$@" &
QEMU_PID=$!

# Monitor serial log in real-time
tail -n 50 -f "$SERIAL_LOG" 2>/dev/null &
TAIL_PID=$!

# Cleanup function
cleanup() {
    kill $TAIL_PID 2>/dev/null || true
    kill $QEMU_PID 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait for QEMU to finish
wait $QEMU_PID
RESULT=$?

# Show final serial log
echo ""
echo "=== Serial Log Contents ==="
cat "$SERIAL_LOG"

exit ${RESULT:-0}
