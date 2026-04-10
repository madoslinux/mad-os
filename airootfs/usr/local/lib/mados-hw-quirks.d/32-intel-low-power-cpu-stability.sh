#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(32-intel-low-power-cpu): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "acpi"; then
    log "acpi quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lscpu >/dev/null 2>&1; then
    exit 0
fi

cpu_vendor=$(lscpu | grep "^Vendor ID:" | awk '{print $3}' || true)
if [[ "$cpu_vendor" != *"Intel"* ]]; then
    exit 0
fi

cpu_family=$(lscpu | grep "^CPU family:" | awk '{print $3}' || true)
cpu_model=$(lscpu | grep "^Model:" | awk '{print $2}' || true)

is_low_power_intel=false

case "$cpu_family" in
    0x4c|76|77|78|79|86|87|88|89|90|91|92|93|94|95)
        is_low_power_intel=true
        ;;
esac

if [[ "$cpu_family" == "6" ]]; then
    case "$cpu_model" in
        0x5c|92|0x5d|93|0x6a|106|0x6b|107|0x6c|108|0x6d|109|0x6f|111|0x7a|122|0x7a|123|124)
            is_low_power_intel=true
            ;;
        0x4f|79|0x55|118|0x56|122)
            is_low_power_intel=true
            ;;
        0x5e|78|0x9e|142|0x9f|143|0xa6|166|0xa7|167|174|0xa8|168|0xa9|169|0xac|172|0xad|173)
            is_low_power_intel=true
            ;;
    esac
fi

if [[ "$is_low_power_intel" == "false" ]]; then
    exit 0
fi

kernel_params_file="/etc/modprobe.d/intel-low-power-cpu.conf"
{
    echo "# Intel low power CPU stability quirks"
    echo "# Applied by mados-hw-quirks 32-intel-low-power-cpu-stability.sh"
    echo "# Fixes hang/freeze issues on Intel Atom (Baytrail/Cherry Trail) and low-power Intel CPUs"
    echo ""
    echo "# Prevent deep C-states (fixes random hangs)"
    echo "options intel_idle max_cstate=1"
    echo ""
    echo "# Disable GPU DC for stability on low-power Intel"
    echo "options i915 enable_dc=0"
} > "$kernel_params_file"

sysctl_conf="/etc/sysctl.d/99-intel-low-power-cpu.conf"
{
    echo "# Intel low power CPU sysctl tunings"
    echo "# Applied by mados-hw-quirks 32-intel-low-power-cpu-stability.sh"
    echo ""
    echo "# Reduce timer interrupt frequency for power savings"
    kernel.timer_latency_monitoring = 0
} > "$sysctl_conf"

log "Applied intel_idle.max_cstate=1 and i915.enable_dc=0 for low-power Intel CPU stability"
exit 0