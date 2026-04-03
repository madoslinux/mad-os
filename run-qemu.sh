#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
BASE_ISO=$(ls -t "${OUT_DIR}"/*.iso 2>/dev/null | head -1 || true)
ISO_FILE="${ISO_FILE:-}"

if [ -z "$ISO_FILE" ]; then
    ISO_FILE="$BASE_ISO"
fi

if [ -z "$ISO_FILE" ]; then
    echo "No ISO found in ${OUT_DIR}"
    exit 1
fi

echo "=== madOS QEMU Launcher ==="
echo ""

CURRENT_UID="$(id -u)"
CURRENT_GID="$(id -g)"

# Ask for sudo only for file preparation fallback (QEMU runs as normal user)
if ! sudo -v 2>/dev/null; then
    echo "Sudo may be needed to prepare disk/log files."
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
QEMU_RENDERER="${QEMU_RENDERER:-stable}"
BOOT_ORDER="${BOOT_ORDER:-c}"
ENABLE_SERIAL="${ENABLE_SERIAL:-0}"

SERIAL_LOG="${OUT_DIR}/mados-serial.log"
SERIAL_ARGS=()

if [ "$ENABLE_SERIAL" = "1" ]; then
    # Serial console output file for debugging (in OUT_DIR to avoid permissions)
    if ! rm -f "$SERIAL_LOG" 2>/dev/null || ! touch "$SERIAL_LOG" 2>/dev/null; then
        sudo rm -f "$SERIAL_LOG"
        sudo touch "$SERIAL_LOG"
        sudo chown "$CURRENT_UID:$CURRENT_GID" "$SERIAL_LOG"
    fi
    chmod 664 "$SERIAL_LOG" 2>/dev/null || true
    SERIAL_ARGS=(-serial "file:${SERIAL_LOG}")
fi

echo "Configuration:"
echo "  ISO: ${ISO_FILE}"
echo "  Memory: ${MEMORY}"
echo "  CPU: ${CPU}"
echo "  Disk: ${DISK_FILE}"
echo "  Boot order: ${BOOT_ORDER}"
echo "  Serial enabled: ${ENABLE_SERIAL}"
if [ "$ENABLE_SERIAL" = "1" ]; then
    echo "  Serial log: ${SERIAL_LOG}"
fi
echo ""

if command -v xorriso >/dev/null 2>&1; then
    BOOT_REPORT=$(xorriso -indev "$ISO_FILE" -report_el_torito as_mkisofs 2>/dev/null || true)
    if grep -q "isolinux.bin" <<< "$BOOT_REPORT"; then
        echo "  Bootloader detected: Syslinux/systemd-boot"
    else
        echo "  Bootloader detected: Unknown"
    fi
    echo ""
fi

# Create virtual disk if it doesn't exist (default 30GB)
if [ ! -f "$DISK_FILE" ]; then
    echo "Creating ${DISK_SIZE} virtual disk..."
    if ! qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE" 2>/dev/null; then
        sudo qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
        sudo chown "$CURRENT_UID:$CURRENT_GID" "$DISK_FILE"
    fi
fi

# Ensure current user can write virtual disk
if [ ! -w "$DISK_FILE" ]; then
    sudo chown "$CURRENT_UID:$CURRENT_GID" "$DISK_FILE"
fi

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration (✓)"
    KVM_OPTS=(-enable-kvm -cpu host)
else
    echo "KVM not available, using TCG (software emulation)"
    KVM_OPTS=()
fi

case "$QEMU_RENDERER" in
    stable)
        echo "Renderer profile: stable (SDL + virtio-vga)"
        VIDEO_OPTS=(-vga virtio -global virtio-vga.max_outputs=1)
        DISPLAY_OPTS=(-display sdl)
        ;;
    gl)
        echo "Renderer profile: gl (GTK GL + virtio-vga-gl)"
        VIDEO_OPTS=(-device virtio-vga-gl,max_outputs=1)
        DISPLAY_OPTS=(-display gtk,gl=on)
        ;;
    compat)
        echo "Renderer profile: compat (GTK + std VGA)"
        VIDEO_OPTS=(-vga std)
        DISPLAY_OPTS=(-display gtk)
        ;;
    *)
        echo "Invalid QEMU_RENDERER='$QEMU_RENDERER'"
        echo "Valid values: stable, gl, compat"
        exit 1
        ;;
esac

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
if [ "$ENABLE_SERIAL" = "1" ]; then
    echo "Serial output will be logged to: ${SERIAL_LOG}"
else
    echo "Serial disabled (better Plymouth visibility)"
fi
echo ""

# Build QEMU command
QEMU_CMD=(
    qemu-system-x86_64
    -m "$MEMORY"
    -smp "$CPU"
    "${KVM_OPTS[@]}"
    -cdrom "$ISO_FILE"
    -boot "$BOOT_ORDER"
    -drive file="$DISK_FILE",format=qcow2,if=virtio
    -net nic
    -net user,hostfwd=tcp::2222-:22
    "${VIDEO_OPTS[@]}"
    "${DISPLAY_OPTS[@]}"
    -device qemu-xhci
    -device usb-tablet
    "${SERIAL_ARGS[@]}"
)

if [ -n "$UEFI_FW" ]; then
    QEMU_CMD+=(-bios "$UEFI_FW")
fi

echo ""
echo "Starting QEMU..."
if [ "$ENABLE_SERIAL" = "1" ]; then
    echo "Serial output will be logged to: ${SERIAL_LOG}"
else
    echo "Serial disabled (better Plymouth visibility)"
fi
echo ""

# Start QEMU in background as current user
"${QEMU_CMD[@]}" "$@" &
QEMU_PID=$!

TAIL_PID=""
if [ "$ENABLE_SERIAL" = "1" ]; then
    # Monitor serial log in real-time
    tail -n 50 -f "$SERIAL_LOG" 2>/dev/null &
    TAIL_PID=$!
fi

# Cleanup function
cleanup() {
    if [ -n "$TAIL_PID" ]; then
        kill "$TAIL_PID" 2>/dev/null || true
    fi
    kill $QEMU_PID 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait for QEMU to finish
wait $QEMU_PID
RESULT=$?

if [ "$ENABLE_SERIAL" = "1" ]; then
    # Show final serial log
    echo ""
    echo "=== Serial Log Contents ==="
    cat "$SERIAL_LOG"
fi

exit ${RESULT:-0}
