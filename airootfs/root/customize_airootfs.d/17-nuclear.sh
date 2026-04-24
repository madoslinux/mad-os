#!/usr/bin/env bash
# 17-nuclear.sh - Install Nuclear music player
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

install_nuclear() {
    echo "Installing Nuclear music player..."

    echo "  → Fetching release info from GitHub API..."
    local release_json
    release_json=$(curl -fSL "https://api.github.com/repos/${NUCLEAR_GITHUB_REPO}/nuclear/releases/latest") || {
        echo "ERROR: Failed to fetch releases API (curl failed with $?)"
        return 1
    }

    if [[ -z "$release_json" ]]; then
        echo "ERROR: Empty response from GitHub API"
        return 1
    fi

    local release_tag appimage_url
    release_tag=$(printf '%s' "$release_json" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("tag_name", ""))')
    appimage_url=$(printf '%s' "$release_json" | python3 -c '
import sys, json
for a in json.load(sys.stdin).get("assets", []):
    if a.get("name", "").lower().endswith(".appimage"):
        print(a.get("browser_download_url", ""))
        break
')

    if [[ -z "$release_tag" || -z "$appimage_url" ]]; then
        echo "ERROR: Could not resolve Nuclear release (tag='${release_tag}', url='${appimage_url}')"
        return 1
    fi

    echo "  → Nuclear release: ${release_tag}"
    echo "  → AppImage: ${appimage_url}"

    local appimage_path="${BUILD_DIR}/nuclear.AppImage"
    local retries=5
    local count=0

    while [ $count -lt $retries ]; do
        echo "  → Downloading... (attempt $((count + 1))/$retries)"
        if curl -fSL -o "$appimage_path" "$appimage_url"; then
            echo "  → Download complete"
            break
        fi
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            echo "  → Retrying in 10 seconds..."
            sleep 10
        fi
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to download Nuclear after $retries attempts"
        return 1
    fi

    if [ ! -f "$appimage_path" ] || [ ! -s "$appimage_path" ]; then
        echo "ERROR: Downloaded file is missing or empty"
        return 1
    fi

    echo "  → File size: $(stat -c%s "$appimage_path" 2>/dev/null || echo 'unknown') bytes"

    mkdir -p "${NUCLEAR_INSTALL_DIR}"
    cp "$appimage_path" "${NUCLEAR_INSTALL_DIR}/nuclear.AppImage"
    chmod +x "${NUCLEAR_INSTALL_DIR}/nuclear.AppImage"

    cat > "${NUCLEAR_BIN}" << 'NUCLEAR_WRAPPER'
#!/bin/bash
exec /opt/nuclear/nuclear.AppImage "$@"
NUCLEAR_WRAPPER
    chmod +x "${NUCLEAR_BIN}"

    cat > /usr/share/applications/nuclear.desktop << 'NUCLEAR_DESKTOP'
[Desktop Entry]
Name=Nuclear Music Player
GenericName=Music Player
Comment=Free, open-source music player without ads or tracking
Exec=nuclear %U
Icon=nuclear
Terminal=false
Type=Application
Categories=Audio;Music;Player;AudioVideo;
MimeType=application/ogg;audio/flac;audio/mp3;audio/mpeg;audio/mpegurl;audio/mp4;audio/ogg;audio/vorbis;audio/wav;audio/x-flac;audio/x-mp3;audio/x-mpeg;audio/x-mpegurl;audio/x-ms-wma;audio/x-ogg;audio/x-vorbis;audio/x-wav;x-scheme-handler/nuclear;
Keywords=music;player;audio;streaming;mp3;flac;ogg;
NUCLEAR_DESKTOP

    mkdir -p /etc/skel/.local/share/applications
    cp /usr/share/applications/nuclear.desktop /etc/skel/.local/share/applications/

    echo "✓ Nuclear ${release_tag} installed to ${NUCLEAR_INSTALL_DIR}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nuclear
fi
