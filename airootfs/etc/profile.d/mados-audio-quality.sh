#!/usr/bin/env bash
#
# mados-audio-quality.sh - Audio quality auto-configuration
# Executed at login via /etc/profile.d/

set -euo pipefail

# Only run once per session
[[ -n "${MADOS_AUDIO_CONFIGURED:-}" ]] && exit 0
export MADOS_AUDIO_CONFIGURED=1

exec /usr/local/bin/mados-audio-quality.sh "$@"