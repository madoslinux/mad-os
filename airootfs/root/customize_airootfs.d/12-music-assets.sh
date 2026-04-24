#!/usr/bin/env bash
# 12-music-assets.sh - Setup demo music assets
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

setup_music_assets() {
    if [[ ! -d /usr/share/music ]] || [[ -z "$(ls -A /usr/share/music 2>/dev/null)" ]]; then
        return 0
    fi

    echo "Setting up music assets..."
    mkdir -p /etc/skel/Music
    if [[ ! -L /etc/skel/Music/demo ]]; then
        cp -r /usr/share/music/. /etc/skel/Music/ 2>/dev/null || true
    fi
    echo "✓ Music assets configured"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_music_assets
fi
