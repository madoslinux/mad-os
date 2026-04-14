#!/usr/bin/env bash
# 13-wallpaper-assets.sh - Setup wallpaper assets
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

setup_wallpaper_assets() {
    local wallpaper_dir="${INSTALL_DIR}/mados_wallpaper"

    if [[ ! -d "$wallpaper_dir" ]]; then
        return 0
    fi

    echo "Setting up wallpaper assets..."

    if [[ -f "$wallpaper_dir/mados-wallpaper.svg" ]]; then
        mkdir -p /usr/share/icons/hicolor/scalable/apps
        cp "$wallpaper_dir/mados-wallpaper.svg" /usr/share/icons/hicolor/scalable/apps/
    fi

    mkdir -p /etc/skel/.local/share/mados/wallpapers
    mkdir -p /etc/skel/Pictures/Wallpapers
    mkdir -p /usr/share/mados/wallpapers
    mkdir -p /usr/share/backgrounds

    cp "$wallpaper_dir"/*.png /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.png /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.png /usr/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /usr/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /usr/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.png /usr/share/backgrounds/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /usr/share/backgrounds/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /usr/share/backgrounds/ 2>/dev/null || true

    if [[ -d /home/mados ]]; then
        mkdir -p /home/mados/.local/share/mados/wallpapers
        mkdir -p /home/mados/Pictures/Wallpapers
        cp "$wallpaper_dir"/*.png /home/mados/.local/share/mados/wallpapers/ 2>/dev/null || true
        cp "$wallpaper_dir"/*.jpg /home/mados/.local/share/mados/wallpapers/ 2>/dev/null || true
        cp "$wallpaper_dir"/*.jpeg /home/mados/.local/share/mados/wallpapers/ 2>/dev/null || true
        cp "$wallpaper_dir"/*.png /home/mados/Pictures/Wallpapers/ 2>/dev/null || true
        cp "$wallpaper_dir"/*.jpg /home/mados/Pictures/Wallpapers/ 2>/dev/null || true
        cp "$wallpaper_dir"/*.jpeg /home/mados/Pictures/Wallpapers/ 2>/dev/null || true
        chown -R 1000:1000 /home/mados/.local/share/mados
        chown -R 1000:1000 /home/mados/Pictures
    fi

    echo "✓ Wallpaper assets configured"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_wallpaper_assets
fi
