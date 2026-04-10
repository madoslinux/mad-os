#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(50-audio-hda): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "audio"; then
    log "audio quirks disabled via mados.disable_quirks"
    exit 0
fi

if [[ -r /proc/asound/cards ]] && ! grep -Eq '--- no soundcards ---|^\s*$' /proc/asound/cards; then
    log "sound card already detected; skipping"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

if ! command -v modprobe >/dev/null 2>&1; then
    exit 0
fi

if ! lspci -nn -D | grep -Eqi '(Audio device|Multimedia audio controller).*(\[8086:|\[1002:|\[1022:|\[10de:)'; then
    exit 0
fi

if ! modprobe -n snd_hda_intel >/dev/null 2>&1; then
    exit 0
fi

log "no active sound card found; trying conservative snd_hda_intel fallback"
modprobe -r snd_hda_codec_hdmi snd_hda_codec snd_hda_intel 2>/dev/null || true
modprobe snd_hda_intel model=generic power_save=0 dmic_detect=0 || true
exit 0
