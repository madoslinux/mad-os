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

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
RESOLUTION="${RESOLUTION:-1920x1080}"
DISK_SIZE="${DISK_SIZE:-30G}"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"
RENDER_MODE="${RENDER_MODE:-auto}"
DISPLAY_BACKEND="${DISPLAY_BACKEND:-gtk}"
USER_DISK_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mados-qemu"
GL_SANITIZE_VARS=(
    LIBGL_ALWAYS_SOFTWARE
    GALLIUM_DRIVER
    MESA_LOADER_DRIVER_OVERRIDE
    MESA_GL_VERSION_OVERRIDE
)

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
        --sdl)
            DISPLAY_BACKEND="sdl"
            shift
            ;;
        --gtk)
            DISPLAY_BACKEND="gtk"
            shift
            ;;
        *)
            break
            ;;
    esac
done

echo "Configuration:"
echo "  ISO: ${ISO_FILE}"
echo "  Memory: ${MEMORY}"
echo "  CPU: ${CPU}"
echo "  Render mode: ${RENDER_MODE}"
echo "  Display backend: ${DISPLAY_BACKEND}"
echo ""

if [ -f "$DISK_FILE" ] && [ ! -w "$DISK_FILE" ]; then
    mkdir -p "$USER_DISK_DIR"
    FALLBACK_DISK_FILE="${USER_DISK_DIR}/madOS-test.qcow2"
    echo "Primary disk is not writable by current user"
    echo "Using user-writable disk: ${FALLBACK_DISK_FILE}"
    DISK_FILE="$FALLBACK_DISK_FILE"
elif [ ! -f "$DISK_FILE" ] && [ ! -w "$OUT_DIR" ]; then
    mkdir -p "$USER_DISK_DIR"
    DISK_FILE="${USER_DISK_DIR}/madOS-test.qcow2"
    echo "Output directory is not writable by current user"
    echo "Creating disk in user-writable path: ${DISK_FILE}"
fi

echo "Effective disk path: ${DISK_FILE}"

# Create virtual disk if it doesn't exist (default 30GB)
if [ ! -f "$DISK_FILE" ]; then
    echo "Creating ${DISK_SIZE} virtual disk..."
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
fi

if [ -w /dev/kvm ]; then
    echo "Using KVM acceleration (✓)"
    KVM_ACCEL="-enable-kvm -cpu host"
else
    echo "KVM not available, using TCG (software emulation)"
    KVM_ACCEL=""
fi

set_rendering_opts() {
    local mode="$1"
    local backend="$2"

    if [[ "$mode" == "software" ]]; then
        echo "Using software rendering mode (virtio DRM + GL off)"
        echo "Hint: this mode keeps DRM (for wlroots) but forces software rendering in guest"
        VIDEO_OPTS=(-vga virtio -global virtio-vga.max_outputs=1 -display "${backend},gl=off")
        DMI_OPTS=(-smbios type=1,product=madOS-QEMU-SWRENDER)
    else
        echo "Using virtio rendering mode (virgl) with ${backend} backend"
        VIDEO_OPTS=(-device virtio-vga-gl -display "${backend},gl=on")
        DMI_OPTS=(-smbios type=1,product=madOS-QEMU-HWRENDER)
    fi
}

# UEFI firmware
UEFI_FW="/usr/share/edk2/x64/OVMF.4m.fd"
if [ ! -f "$UEFI_FW" ]; then
    UEFI_FW="/usr/share/edk2/ovmf/OVMF.4m.fd"
fi
if [ ! -f "$UEFI_FW" ]; then
    echo "WARNING: UEFI firmware not found, BIOS boot only"
    UEFI_FW=""
fi

build_qemu_cmd() {
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
    )

    if [ -n "$UEFI_FW" ]; then
        QEMU_CMD+=(-bios "$UEFI_FW")
    fi
}

run_qemu_cmd() {
    local mode="$1"
    shift

    if [[ "$mode" == "software" ]]; then
        "${QEMU_CMD[@]}" "$@"
        return $?
    fi

    local env_cmd=(env)
    local had_sanitized_var=0
    local var

    for var in "${GL_SANITIZE_VARS[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            had_sanitized_var=1
            env_cmd+=(-u "$var")
        fi
    done

    if [[ $had_sanitized_var -eq 1 ]]; then
        echo "Unsetting software-forcing Mesa vars for GL launch"
    fi

    env_cmd+=("${QEMU_CMD[@]}")
    "${env_cmd[@]}" "$@"
}

echo ""
echo "Starting QEMU..."
echo ""

if [[ "$RENDER_MODE" == "software" ]]; then
    set_rendering_opts "software" "$DISPLAY_BACKEND"
    build_qemu_cmd
    run_qemu_cmd "software" "$@"
    exit $?
fi

set_rendering_opts "auto" "$DISPLAY_BACKEND"
build_qemu_cmd
if run_qemu_cmd "auto" "$@"; then
    exit 0
fi

if [[ "$DISPLAY_BACKEND" == "gtk" ]]; then
    echo ""
    echo "GTK + virgl failed. Trying SDL + virgl..."
    echo ""

    set_rendering_opts "auto" "sdl"
    build_qemu_cmd
    if run_qemu_cmd "auto" "$@"; then
        exit 0
    fi
fi

echo ""
echo "Virgl mode failed. Falling back to software rendering..."
echo ""

set_rendering_opts "software" "$DISPLAY_BACKEND"
build_qemu_cmd
run_qemu_cmd "software" "$@"
