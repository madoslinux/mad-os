#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(33-intel-i915-execlist): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "gpu"; then
    log "gpu quirks disabled via mados.disable_quirks"
    exit 0
fi

if [[ ! -r /sys/class/dmi/id/sys_vendor ]]; then
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

gpu_device=$(lspci 2>/dev/null | grep -i "vga\|display\|3d" | head -1 || true)
if [[ -z "$gpu_device" ]]; then
    exit 0
fi

is_broadwell_or_core_m=false
if echo "$gpu_device" | grep -qi "intel"; then
    device_id=$(echo "$gpu_device" | sed -n 's/.*\[8086:\([0-9a-fA-F]*\)\].*/\1/p' | head -1)
    if [[ -n "$device_id" ]]; then
        case "$device_id" in
            0x162|0x163|0x164|0x165|0x166|0x167|0x168|0x169)
                is_broadwell_or_core_m=true
                ;;
            0x160|0x161|0x16a|0x16b|0x16c|0x16d|0x16e|0x16f)
                is_broadwell_or_core_m=true
                ;;
            0x0a|0x0b|0x0c|0x0d|0x0e|0x0f)
                is_broadwell_or_core_m=true
                ;;
        esac
    fi
fi

if [[ "$is_broadwell_or_core_m" == "false" ]]; then
    exit 0
fi

kernel_params_file="/etc/modprobe.d/i915-execlist-off.conf"
{
    echo "# Intel i915 execlist submission disable"
    echo "# Applied by mados-hw-quirks 33-intel-i915-execlist-crash.sh"
    echo "# Fixes kernel crashes on Broadwell/Core-M with kernels 4.0+"
    echo "options i915 enable_execlists=0"
} > "$kernel_params_file"

log "Applied i915.enable_execlists=0 for Broadwell/Core-M stability"
exit 0