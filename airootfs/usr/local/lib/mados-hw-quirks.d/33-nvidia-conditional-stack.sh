#!/usr/bin/env bash
set -euo pipefail

LIB_PATH="/usr/local/lib/mados-hw-quirks-lib.sh"
NVIDIA_EGL_JSON="/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json"
NVIDIA_EGL_JSON_DISABLED="${NVIDIA_EGL_JSON}.disabled"

if [[ -f "$LIB_PATH" ]]; then
    # shellcheck source=/usr/local/lib/mados-hw-quirks-lib.sh
    source "$LIB_PATH"
fi

log() {
    printf '%s\n' "mados-hw-quirk(33-nvidia-stack): $*"
}

if command -v hwq_is_group_disabled >/dev/null 2>&1 && hwq_is_group_disabled "gpu"; then
    log "gpu quirks disabled via mados.disable_quirks"
    exit 0
fi

if ! command -v lspci >/dev/null 2>&1; then
    exit 0
fi

if lspci -nn -D | grep -Eqi '((VGA compatible controller)|(3D controller)|(Display controller)).*\[10de:[0-9a-f]{4}\]'; then
    if [[ ! -e "$NVIDIA_EGL_JSON" && -e "$NVIDIA_EGL_JSON_DISABLED" ]]; then
        log "nvidia gpu detected; restoring nvidia egl external platform"
        mv -f "$NVIDIA_EGL_JSON_DISABLED" "$NVIDIA_EGL_JSON"
    fi
    exit 0
fi

if [[ -e "$NVIDIA_EGL_JSON" ]]; then
    log "non-nvidia system detected; disabling nvidia egl external platform"
    mv -f "$NVIDIA_EGL_JSON" "$NVIDIA_EGL_JSON_DISABLED"
fi

exit 0
