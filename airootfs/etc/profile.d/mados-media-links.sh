#!/usr/bin/env bash
# Link system media content to user directories
# Creates symlinks from /usr/share/music/* -> ~/Music/
# and /usr/share/video/* -> ~/Videos/

set -euo pipefail

# Only run for interactive sessions with a real home
[[ -z "$HOME" || "$HOME" == "/" ]] && exit 0

MARKER="${HOME}/.cache/.mados-media-linked"

# Only run once per user
[[ -f "$MARKER" ]] && exit 0

# Ensure user directories exist
mkdir -p "${HOME}/Music" "${HOME}/Videos" "${HOME}/.cache"

# Link music files
if [[ -d /usr/share/music ]]; then
    for f in /usr/share/music/*; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        if [[ ! -e "${HOME}/Music/$base" ]]; then
            ln -s "$f" "${HOME}/Music/$base" 2>/dev/null || true
        fi
    done
fi

# Link video files
if [[ -d /usr/share/video ]]; then
    for f in /usr/share/video/*; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        if [[ ! -e "${HOME}/Videos/$base" ]]; then
            ln -s "$f" "${HOME}/Videos/$base" 2>/dev/null || true
        fi
    done
fi

# Mark as done
touch "$MARKER"
