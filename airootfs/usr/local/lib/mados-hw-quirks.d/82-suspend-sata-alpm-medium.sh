#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(82-suspend-sata-alpm): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "suspend"; then
    log "suspend quirks disabled via mados.disable_quirks"
    exit 0
fi

if [[ ! -w /sys/class/scsi_host/host0/link_power_management_policy ]]; then
    exit 0
fi

if [[ ! -r /sys/class/dmi/id/sys_vendor ]]; then
    exit 0
fi

vendor=$(tr '[:upper:]' '[:lower:]' < /sys/class/dmi/id/sys_vendor 2>/dev/null || true)

sata_controller_found=false
for host in /sys/class/scsi_host/host*; do
    if [[ -r "$host/../../../class" ]]; then
        class=$(cat "$host/../../../class" 2>/dev/null || true)
        if [[ "$class" == *"ide"* ]] || [[ "$class" == *"ata"* ]]; then
            sata_controller_found=true
            break
        fi
    fi
done

if [[ "$sata_controller_found" == "false" ]]; then
    for dev in /sys/class/ata_port/*; do
        if [[ -d "$dev" ]]; then
            sata_controller_found=true
            break
        fi
    done
fi

if [[ "$sata_controller_found" == "false" ]]; then
    exit 0
fi

for host in /sys/class/scsi_host/host*; do
    if [[ -w "$host/link_power_management_policy" ]]; then
        echo "medium_power" > "$host/link_power_management_policy" 2>/dev/null || true
    fi
done

if [[ -w /sys/module/libata/parameters/force ]]; then
    echo 1 > /sys/module/libata/parameters/force 2>/dev/null || true
fi

modprobe_conf="/etc/modprobe.d/libata-alpm.conf"
{
    echo "# SATA ALPM medium_power for suspend stability"
    echo "# Applied by mados-hw-quirks 82-suspend-sata-alpm-medium.sh"
    echo "options libata force=1"
} > "$modprobe_conf"

sysctl_conf="/etc/sysctl.d/99-sata-alpm.conf"
{
    echo "# SATA ALPM setting"
    echo "# Applied by mados-hw-quirks 82-suspend-sata-alpm-medium.sh"
    echo "# Note: sata_alpm is a kernel boot parameter, sysctl provides fallback"
} > "$sysctl_conf"

log "Applied medium_power ALPM for SATA suspend stability"
exit 0