#!/usr/bin/env bash
# 14-skwd-wall.sh - Install skwd-wall wallpaper selector
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

SKWD_WALL_REPO="madkoding/skwd-wall"
SKWD_WALL_INSTALL_DIR="/usr/local/share/skwd-wall"
SKWD_WALL_COMPAT_DIR="/opt/mados/skwd-wall"

install_skwd_wall() {
    echo "Installing skwd-wall..."

    local build_dir="${BUILD_DIR}/skwd-wall_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$BUILD_DIR"

    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --branch main --no-tags "https://github.com/${SKWD_WALL_REPO}.git" "${build_dir}/skwd-wall"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone skwd-wall after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi

    mkdir -p "$INSTALL_DIR" "/usr/local/share" "/opt/mados" /etc/skel/.config/skwd-wall /etc/skel/.config/systemd/user
    rm -rf "$SKWD_WALL_INSTALL_DIR"
    mv "${build_dir}/skwd-wall" "$SKWD_WALL_INSTALL_DIR"

    rm -rf "$SKWD_WALL_COMPAT_DIR"
    ln -s "$SKWD_WALL_INSTALL_DIR" "$SKWD_WALL_COMPAT_DIR"

    if [[ ! -e "$SKWD_WALL_INSTALL_DIR/scripts" && -d "$SKWD_WALL_INSTALL_DIR/data/scripts" ]]; then
        ln -s "$SKWD_WALL_INSTALL_DIR/data/scripts" "$SKWD_WALL_INSTALL_DIR/scripts"
    fi

    if [[ -f "$SKWD_WALL_INSTALL_DIR/data/config.json.example" ]]; then
        cp "$SKWD_WALL_INSTALL_DIR/data/config.json.example" /etc/skel/.config/skwd-wall/config.json
        sed -i 's/"compositor":[[:space:]]*"[^"]*"/"compositor": "hyprland"/' /etc/skel/.config/skwd-wall/config.json
    fi

    if [[ ! -f /etc/skel/.config/systemd/user/skwd-wall.service ]]; then
        cat > /etc/skel/.config/systemd/user/skwd-wall.service << 'SKWD_WALL_SERVICE_FALLBACK'
[Unit]
Description=skwd-wall wallpaper selector daemon
Documentation=https://github.com/madkoding/skwd-wall
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mados-skwd-wall-daemon
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
SKWD_WALL_SERVICE_FALLBACK
    fi

    if [[ -d /home/mados ]]; then
        mkdir -p /home/mados/.config/skwd-wall /home/mados/.config/systemd/user
        if [[ -f /etc/skel/.config/skwd-wall/config.json ]]; then
            cp /etc/skel/.config/skwd-wall/config.json /home/mados/.config/skwd-wall/config.json
        fi
        if [[ -f /etc/skel/.config/systemd/user/skwd-wall.service ]]; then
            cp /etc/skel/.config/systemd/user/skwd-wall.service /home/mados/.config/systemd/user/skwd-wall.service
        fi
        chown -R 1000:1000 /home/mados/.config/skwd-wall /home/mados/.config/systemd
    fi

    for helper in /usr/local/bin/mados-wallpaper-picker /usr/local/bin/skwd-wall /usr/local/bin/mados-skwd-wall-daemon /usr/local/bin/mados-skwd-wall-sources /usr/local/bin/mados-skwd-wall-doctor; do
        if [[ -f "$helper" ]]; then
            chmod +x "$helper"
        fi
    done

    rm -rf "$build_dir"

    echo "✓ skwd-wall installed to ${SKWD_WALL_INSTALL_DIR}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_skwd_wall
fi
