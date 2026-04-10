#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(34-intel-hda-position): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "audio"; then
    log "audio quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

hda_device=$(lspci 2>/dev/null | grep -i "audio\|sound\|hda" | head -1 || true)
if [[ -z "$hda_device" ]]; then
    exit 0
fi

if ! echo "$hda_device" | grep -qi "intel"; then
    exit 0
fi

needs_position_fix=false
if echo "$hda_device" | grep -qi "8086"; then
    codec_id=$(cat /proc/asound/card*/codec* 2>/dev/null | grep "Codec:" | head -1 | awk '{print $3}' || true)
    case "$codec_id" in
        0x10ec0262|0x10ec0268|0x10ec0662|0x10ec0668|0x10ec0867|0x10ec0885|0x10ec0887)
            needs_position_fix=true
            ;;
    esac
fi

if [[ "$needs_position_fix" == "false" ]]; then
    has_dummy_output=false
    if command -v pactl >/dev/null 2>&1; then
        if pactl list short sinks 2>/dev/null | grep -qi "dummy"; then
            has_dummy_output=true
        fi
    fi
    if [[ "$has_dummy_output" == "true" ]]; then
        needs_position_fix=true
    fi
fi

if [[ "$needs_position_fix" == "false" ]]; then
    exit 0
fi

position_fix_file="/etc/modprobe.d/snd-hda-intel-position.conf"
{
    echo "# Intel HDA position fix"
    echo "# Applied by mados-hw-quirks 34-intel-hda-position-fix.sh"
    echo "# Fixes crackling/popping audio by reading position from LPIB register"
    echo "options snd-hda-intel position_fix=1"
    echo ""
    echo "# Alternative: Use DMA position buffer (uncomment if position_fix=1 doesn't help)"
    echo "# options snd-hda-intel position_fix=2"
} > "$position_fix_file"

sysctl_conf="/etc/sysctl.d/99-audio-latency.conf"
{
    echo "# Audio latency tuning"
    echo "# Applied by mados-hw-quirks 34-intel-hda-position-fix.sh"
    echo ""
    echo "# Reduce timer interrupts for audio stability"
    kernel.timer_latency_monitoring = 0
} > "$sysctl_conf"

log "Applied snd-hda-intel position_fix=1 for audio stability"
exit 0