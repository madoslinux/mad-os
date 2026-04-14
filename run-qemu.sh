#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
USER_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mados-qemu"
LAST_CFG_FILE="${USER_STATE_DIR}/last.conf"

MEMORY="${MEMORY:-4G}"
CPU="${CPU:-4}"
DISK_SIZE="${DISK_SIZE:-30G}"
DISK_FILE="${OUT_DIR}/madOS-test.qcow2"
RENDER_MODE="${RENDER_MODE:-auto}"
DISPLAY_BACKEND="${DISPLAY_BACKEND:-gtk}"
VIDEO_PROFILE="${VIDEO_PROFILE:-virtio}"
SCREEN_RESOLUTION="${SCREEN_RESOLUTION:-}"
ENABLE_AUDIO="${ENABLE_AUDIO:-1}"
NET_MODE="${NET_MODE:-nat}"
BRIDGE_IF="${BRIDGE_IF:-br0}"
INTERACTIVE=0
USE_LAST=0

GL_SANITIZE_VARS=(
    LIBGL_ALWAYS_SOFTWARE
    GALLIUM_DRIVER
    MESA_LOADER_DRIVER_OVERRIDE
    MESA_GL_VERSION_OVERRIDE
)

QEMU_EXTRA_ARGS=()

print_usage() {
    cat << 'EOF'
Usage: ./run-qemu.sh [options] [-- <extra qemu args>]

Options:
  --interactive         Launch interactive menu (TUI)
  --last                Reuse last interactive configuration
  --software-render     Force software rendering profile
  --virtio-render       Use virgl/virtio render profile
  --gtk                 Use GTK display backend
  --sdl                 Use SDL display backend
  --memory <size>       RAM, e.g. 4G
  --cpu <count>         CPU cores, e.g. 4
  --disk-size <size>    Disk size when creating qcow2, e.g. 30G
  --disk-file <path>    Disk image path
  --iso <path>          ISO path (default: latest from out/)
  --preset <name>       Preset: normal | software-drm | no-drm-test
  --no-audio            Disable audio
  --net-mode <mode>     Network mode: nat | bridge
  --bridge <ifname>     Bridge interface for bridge mode (default: br0)
  --resolution <wxh>   Screen resolution (e.g. 1920x1080)
  --help                Show this help

Examples:
  ./run-qemu.sh
  ./run-qemu.sh --interactive
  ./run-qemu.sh --preset no-drm-test
  ./run-qemu.sh --software-render --gtk -- -serial mon:stdio
EOF
}

ensure_state_dir() {
    mkdir -p "$USER_STATE_DIR"
}

list_isos() {
    shopt -s nullglob
    local files=("${OUT_DIR}"/*.iso)
    shopt -u nullglob
    printf '%s\n' "${files[@]}"
}

detect_default_iso() {
    local first
    first=$(ls -t "${OUT_DIR}"/*.iso 2>/dev/null | head -1 || true)
    if [[ -z "$first" ]]; then
        echo "No ISO found in ${OUT_DIR}"
        exit 1
    fi
    ISO_FILE="$first"
}

save_last_config() {
    ensure_state_dir
    cat > "$LAST_CFG_FILE" << EOF
ISO_FILE=${ISO_FILE}
MEMORY=${MEMORY}
CPU=${CPU}
DISK_SIZE=${DISK_SIZE}
DISK_FILE=${DISK_FILE}
RENDER_MODE=${RENDER_MODE}
DISPLAY_BACKEND=${DISPLAY_BACKEND}
VIDEO_PROFILE=${VIDEO_PROFILE}
ENABLE_AUDIO=${ENABLE_AUDIO}
NET_MODE=${NET_MODE}
BRIDGE_IF=${BRIDGE_IF}
SCREEN_RESOLUTION=${SCREEN_RESOLUTION}
EOF
}

load_last_config() {
    if [[ ! -f "$LAST_CFG_FILE" ]]; then
        echo "No previous launcher config found at ${LAST_CFG_FILE}"
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$LAST_CFG_FILE"
}

choose_from_list() {
    local prompt="$1"
    shift
    local options=("$@")
    local idx=1

    echo "$prompt" >&2
    for option in "${options[@]}"; do
        echo "  ${idx}) ${option}" >&2
        idx=$((idx + 1))
    done

    while true; do
        read -rp "Select [1-${#options[@]}] (Enter keeps current): " choice
        if [[ -z "$choice" ]]; then
            return 1
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "${options[$((choice - 1))]}"
            return 0
        fi
        echo "Invalid choice" >&2
    done
}

prompt_value() {
    local label="$1"
    local current="$2"
    local value
    read -rp "${label} [${current}]: " value
    if [[ -z "$value" ]]; then
        echo "$current"
        return 0
    fi
    echo "$value"
}

apply_preset() {
    local preset="$1"
    case "$preset" in
        normal)
            RENDER_MODE="auto"
            DISPLAY_BACKEND="gtk"
            VIDEO_PROFILE="virtio"
            ;;
        software-drm)
            RENDER_MODE="software"
            DISPLAY_BACKEND="gtk"
            VIDEO_PROFILE="virtio"
            ;;
        no-drm-test)
            RENDER_MODE="software"
            DISPLAY_BACKEND="gtk"
            VIDEO_PROFILE="std"
            ;;
        *)
            echo "Unknown preset: ${preset}"
            echo "Valid presets: normal, software-drm, no-drm-test"
            exit 1
            ;;
    esac
}

interactive_menu() {
    echo "=== madOS QEMU Launcher (Interactive) ==="
    echo ""

    local presets=("normal" "software-drm" "no-drm-test")
    local preset
    preset=$(choose_from_list "Quick preset:" "${presets[@]}" || true)
    if [[ -n "${preset:-}" ]]; then
        apply_preset "$preset"
    fi

    local iso_entries
    mapfile -t iso_entries < <(list_isos)
    if (( ${#iso_entries[@]} == 0 )); then
        echo "No ISO found in ${OUT_DIR}"
        exit 1
    fi
    local chosen_iso
    chosen_iso=$(choose_from_list "Select ISO:" "${iso_entries[@]}" || true)
    if [[ -n "${chosen_iso:-}" ]]; then
        ISO_FILE="$chosen_iso"
    fi

    MEMORY=$(prompt_value "Memory" "$MEMORY")
    CPU=$(prompt_value "CPU cores" "$CPU")
    DISK_SIZE=$(prompt_value "Disk size" "$DISK_SIZE")
    DISK_FILE=$(prompt_value "Disk path" "$DISK_FILE")

    local render_choice
    render_choice=$(choose_from_list "Render mode:" "auto" "software" || true)
    if [[ -n "${render_choice:-}" ]]; then
        RENDER_MODE="$render_choice"
    fi

    local backend_choice
    backend_choice=$(choose_from_list "Display backend:" "gtk" "sdl" || true)
    if [[ -n "${backend_choice:-}" ]]; then
        DISPLAY_BACKEND="$backend_choice"
    fi

    local net_mode_choice
    net_mode_choice=$(choose_from_list "Network mode:" "nat" "bridge" || true)
    if [[ -n "${net_mode_choice:-}" ]]; then
        NET_MODE="$net_mode_choice"
    fi

    if [[ "$NET_MODE" == "bridge" ]]; then
        BRIDGE_IF=$(prompt_value "Bridge interface" "$BRIDGE_IF")
    fi

    local profile_choice
    profile_choice=$(choose_from_list "Video profile:" "virtio" "std (no-drm test)" || true)
    if [[ -n "${profile_choice:-}" ]]; then
        if [[ "$profile_choice" == "std (no-drm test)" ]]; then
            VIDEO_PROFILE="std"
        else
            VIDEO_PROFILE="virtio"
        fi
    fi

    echo ""
    echo "Scenario help:"
    echo "  - normal: virgl path for modern guests"
    echo "  - software-drm: software rendering while keeping DRM"
    echo "  - no-drm-test: legacy std VGA to test sway X11 fallback"
    echo ""

    save_last_config
}

parse_args() {
    local preset_name=""

    if [[ $# -eq 0 ]]; then
        INTERACTIVE=1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive)
                INTERACTIVE=1
                shift
                ;;
            --last)
                USE_LAST=1
                shift
                ;;
            --software-render)
                RENDER_MODE="software"
                shift
                ;;
            --virtio-render)
                RENDER_MODE="auto"
                shift
                ;;
            --gtk)
                DISPLAY_BACKEND="gtk"
                shift
                ;;
            --sdl)
                DISPLAY_BACKEND="sdl"
                shift
                ;;
            --memory)
                MEMORY="$2"
                shift 2
                ;;
            --cpu)
                CPU="$2"
                shift 2
                ;;
            --disk-size)
                DISK_SIZE="$2"
                shift 2
                ;;
            --disk-file)
                DISK_FILE="$2"
                shift 2
                ;;
            --iso)
                ISO_FILE="$2"
                shift 2
                ;;
            --preset)
                preset_name="$2"
                shift 2
                ;;
            --no-audio)
                ENABLE_AUDIO=0
                shift
                ;;
            --net-mode)
                NET_MODE="$2"
                shift 2
                ;;
            --bridge)
                BRIDGE_IF="$2"
                shift 2
                ;;
            --resolution)
                SCREEN_RESOLUTION="$2"
                shift 2
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            --)
                shift
                QEMU_EXTRA_ARGS+=("$@")
                break
                ;;
            *)
                QEMU_EXTRA_ARGS+=("$1")
                shift
                ;;
        esac
    done

    if [[ -n "$preset_name" ]]; then
        apply_preset "$preset_name"
    fi
}

resolve_disk_file_path() {
    if [[ -f "$DISK_FILE" ]] && [[ ! -w "$DISK_FILE" ]]; then
        ensure_state_dir
        local fallback_disk_file="${USER_STATE_DIR}/madOS-test.qcow2"
        echo "Primary disk is not writable by current user"
        echo "Using user-writable disk: ${fallback_disk_file}"
        DISK_FILE="$fallback_disk_file"
    elif [[ ! -f "$DISK_FILE" ]]; then
        local disk_parent
        disk_parent="$(dirname "$DISK_FILE")"
        if [[ ! -d "$disk_parent" ]]; then
            mkdir -p "$disk_parent"
        fi
        if [[ ! -w "$disk_parent" ]]; then
            ensure_state_dir
            DISK_FILE="${USER_STATE_DIR}/madOS-test.qcow2"
            echo "Disk directory is not writable by current user"
            echo "Creating disk in user-writable path: ${DISK_FILE}"
        fi
    fi
}

ensure_disk_exists() {
    if [[ ! -f "$DISK_FILE" ]]; then
        echo "Creating ${DISK_SIZE} virtual disk..."
        qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
    fi
}

set_kvm_accel() {
    if [[ -w /dev/kvm ]]; then
        echo "Using KVM acceleration (yes)"
        KVM_ARGS=(-enable-kvm -cpu host)
    else
        echo "KVM not available, using TCG"
        KVM_ARGS=()
    fi
}

set_resolution_opts() {
    if [[ -z "$SCREEN_RESOLUTION" ]]; then
        RES_OPTS=()
        return
    fi

    local width height
    IFS='x' read -r width height <<< "$SCREEN_RESOLUTION"

    if [[ ! "$width" =~ ^[0-9]+$ ]] || [[ ! "$height" =~ ^[0-9]+$ ]]; then
        echo "Invalid resolution format: ${SCREEN_RESOLUTION} (expected WIDTHxHEIGHT)"
        RES_OPTS=()
        return
    fi

    echo "Resolution: ${width}x${height} (guest sets)"
    RES_OPTS=()
}

set_rendering_opts() {
    local mode="$1"
    local backend="$2"

    if [[ -n "$SCREEN_RESOLUTION" ]]; then
        echo "Resolution override: std VGA (guest controls resolution)"
        VIDEO_OPTS=(-vga std -display "${backend},gl=off")
        DMI_OPTS=(-smbios type=1,product=madOS-QEMU-SWRENDER)
        return
    fi

    if [[ "$VIDEO_PROFILE" == "std" ]]; then
        echo "Using std VGA profile (for no-DRM fallback testing)"
        VIDEO_OPTS=(-vga std -display "${backend},gl=off")
        DMI_OPTS=(-smbios type=1,product=madOS-QEMU-SWRENDER)
        return
    fi

    if [[ "$mode" == "software" ]]; then
        echo "Using software rendering mode (virtio DRM + GL off)"
        echo "Hint: keeps DRM for wlroots while forcing software render in guest"
        VIDEO_OPTS=(-vga virtio -global virtio-vga.max_outputs=1 -display "${backend},gl=off")
        DMI_OPTS=(-smbios type=1,product=madOS-QEMU-SWRENDER)
    else
        echo "Using virtio rendering mode (virgl) with ${backend} backend"
        VIDEO_OPTS=(-device virtio-vga-gl -display "${backend},gl=on")
        DMI_OPTS=(-smbios type=1,product=madOS-QEMU-HWRENDER)
    fi
}

set_uefi_firmware() {
    UEFI_FW="/usr/share/edk2/x64/OVMF.4m.fd"
    if [[ ! -f "$UEFI_FW" ]]; then
        UEFI_FW="/usr/share/edk2/ovmf/OVMF.4m.fd"
    fi
    if [[ ! -f "$UEFI_FW" ]]; then
        echo "WARNING: UEFI firmware not found, BIOS boot only"
        UEFI_FW=""
    fi
}

set_audio_opts() {
    if [[ "$ENABLE_AUDIO" -eq 1 ]]; then
        local audio_backend=""
        local audio_device=""

        if [[ -d /dev/snd ]] && ls /dev/snd/* >/dev/null 2>&1; then
            audio_backend="alsa"
            audio_device="ac97"
        else
            audio_backend="none"
            audio_device="ac97"
        fi

        echo "Audio enabled (${audio_backend}/${audio_device})"
        AUDIO_OPTS=(
            -audiodev "${audio_backend},id=audio0"
            -device "${audio_device},audiodev=audio0"
        )
    else
        echo "Audio disabled"
        AUDIO_OPTS=()
    fi
}

set_network_opts() {
    case "$NET_MODE" in
        nat)
            echo "Network mode: NAT (QEMU user networking)"
            NET_OPTS=(
                -netdev user,id=net0,hostfwd=tcp::2222-:22
                -device virtio-net-pci,netdev=net0
            )
            ;;
        bridge)
            echo "Network mode: bridge (${BRIDGE_IF})"
            NET_OPTS=(
                -netdev "bridge,id=net0,br=${BRIDGE_IF}"
                -device virtio-net-pci,netdev=net0
            )
            ;;
        *)
            echo "Invalid net mode: ${NET_MODE}"
            echo "Valid net modes: nat, bridge"
            exit 1
            ;;
    esac
}

build_qemu_cmd() {
    QEMU_CMD=(
        qemu-system-x86_64
        -m "$MEMORY"
        -smp "$CPU"
        "${KVM_ARGS[@]}"
        -cdrom "$ISO_FILE"
        -boot d
        -drive file="$DISK_FILE",format=qcow2,if=virtio
        "${NET_OPTS[@]}"
        "${VIDEO_OPTS[@]}"
        "${DMI_OPTS[@]}"
        "${RES_OPTS[@]}"
        -device qemu-xhci
        -device usb-tablet
        "${AUDIO_OPTS[@]}"
        "${QEMU_EXTRA_ARGS[@]}"
    )

    if [[ -n "$UEFI_FW" ]]; then
        QEMU_CMD+=(-bios "$UEFI_FW")
    fi
}

print_config() {
    echo "=== madOS QEMU Launcher ==="
    echo ""
    echo "Configuration:"
    echo "  ISO: ${ISO_FILE}"
    echo "  Memory: ${MEMORY}"
    echo "  CPU: ${CPU}"
    echo "  Disk: ${DISK_FILE}"
    echo "  Disk size (new): ${DISK_SIZE}"
    echo "  Render mode: ${RENDER_MODE}"
    echo "  Display backend: ${DISPLAY_BACKEND}"
    echo "  Video profile: ${VIDEO_PROFILE}"
    echo "  Network mode: ${NET_MODE}"
    if [[ "$NET_MODE" == "bridge" ]]; then
        echo "  Bridge interface: ${BRIDGE_IF}"
    fi
    if [[ -n "$SCREEN_RESOLUTION" ]]; then
        echo "  Resolution: ${SCREEN_RESOLUTION}"
    fi
    echo "  Audio: $([ "$ENABLE_AUDIO" -eq 1 ] && echo "enabled" || echo "disabled")"
    echo ""
}

print_qemu_command() {
    local cmd_display=""
    local arg
    for arg in "${QEMU_CMD[@]}"; do
        if [[ -z "$cmd_display" ]]; then
            cmd_display=$(printf '%q' "$arg")
        else
            cmd_display+=" $(printf '%q' "$arg")"
        fi
    done
    echo "QEMU command:"
    echo "  ${cmd_display}"
    echo ""
}

run_qemu_cmd() {
    local mode="$1"

    if [[ "$mode" == "software" ]]; then
        "${QEMU_CMD[@]}" &
        local qemu_pid=$!
        sleep 2
        if [[ -n "$SCREEN_RESOLUTION" ]] && command -v xdotool &>/dev/null; then
            local width height
            IFS='x' read -r width height <<< "$SCREEN_RESOLUTION"
            local winid
            winid=$(xdotool search --pid "$qemu_pid" --name "QEMU" 2>/dev/null | head -1 || true)
            if [[ -n "$winid" ]]; then
                xdotool windowsize "$winid" "$width" "$height"
            fi
        fi
        wait "$qemu_pid"
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
    "${env_cmd[@]}" &
    local qemu_pid=$!
    sleep 2
    if [[ -n "$SCREEN_RESOLUTION" ]] && command -v xdotool &>/dev/null; then
        local width height
        IFS='x' read -r width height <<< "$SCREEN_RESOLUTION"
        local winid
        winid=$(xdotool search --pid "$qemu_pid" --name "QEMU" 2>/dev/null | head -1 || true)
        if [[ -n "$winid" ]]; then
            xdotool windowsize "$winid" "$width" "$height"
        fi
    fi
    wait "$qemu_pid"
    return $?
}

main() {
    parse_args "$@"

    if [[ $USE_LAST -eq 1 ]]; then
        load_last_config
    fi

    if [[ -z "${ISO_FILE:-}" ]]; then
        detect_default_iso
    fi

    if [[ $INTERACTIVE -eq 1 ]]; then
        interactive_menu
    fi

    print_config

    resolve_disk_file_path
    echo "Effective disk path: ${DISK_FILE}"
    ensure_disk_exists

    set_kvm_accel
    set_uefi_firmware
    set_resolution_opts
    set_audio_opts
    set_network_opts

    echo ""
    echo "Starting QEMU..."
    echo ""

    set_rendering_opts "auto" "$DISPLAY_BACKEND"
    build_qemu_cmd
    print_qemu_command
    if run_qemu_cmd "auto"; then
        exit 0
    fi

    if [[ "$DISPLAY_BACKEND" == "gtk" ]]; then
        echo ""
        echo "GTK + virgl failed. Trying SDL + virgl..."
        echo ""

        set_rendering_opts "auto" "sdl"
        build_qemu_cmd
        print_qemu_command
        if run_qemu_cmd "auto"; then
            exit 0
        fi
    fi

    if [[ "$VIDEO_PROFILE" == "std" ]]; then
        echo ""
        echo "std profile failed. Not retrying with virtio fallback automatically."
        echo ""
        exit 1
    fi

    echo ""
    echo "Virgl mode failed. Falling back to software rendering..."
    echo ""

    set_rendering_opts "software" "$DISPLAY_BACKEND"
    build_qemu_cmd
    print_qemu_command
    run_qemu_cmd "software"
}

main "$@"
