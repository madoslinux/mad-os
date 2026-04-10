#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(51-audio-sof): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "audio"; then
    log "audio quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v modprobe >/dev/null 2>&1; then
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

if ! lspci -nn -D | grep -Eqi 'Audio device.*\[8086:[0-9a-f]{4}\]'; then
    exit 0
fi

if [[ -r /proc/asound/cards ]] && ! grep -Eq '--- no soundcards ---|^\s*$' /proc/asound/cards; then
    exit 0
fi

if ! modprobe -n snd_intel_dspcfg >/dev/null 2>&1; then
    exit 0
fi

log "intel audio detected without card; preferring legacy HDA path"
modprobe -r snd_sof_pci_intel_tgl snd_sof_pci snd_sof_intel_hda_common snd_sof snd_intel_dspcfg 2>/dev/null || true
modprobe snd_intel_dspcfg dsp_driver=1 || true
modprobe snd_hda_intel dmic_detect=0 || true
exit 0
