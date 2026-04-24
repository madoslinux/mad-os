#!/usr/bin/env bash
# 13-wallpaper-assets.sh - Setup wallpaper assets
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

setup_wallpaper_assets() {
    local wallpaper_dir="${INSTALL_DIR}/mados_wallpaper"
    local wallpapers_subdir="${wallpaper_dir}/wallpapers"
    local icon_source="${wallpaper_dir}/mados-wallpaper.svg"
    local nullglob_was_set=0
    local source
    local target
    local assets=()
    local has_assets=false
    local targets=(
        "/usr/share/mados/wallpapers"
        "/usr/share/backgrounds"
        "/etc/skel/.local/share/mados/wallpapers"
        "/etc/skel/Pictures/Wallpapers"
    )

    if [[ ! -d "$wallpaper_dir" ]]; then
        return 0
    fi

    echo "Setting up wallpaper assets..."

    if [[ -f "$icon_source" ]]; then
        mkdir -p /usr/share/icons/hicolor/scalable/apps
        cp "$icon_source" /usr/share/icons/hicolor/scalable/apps/
    fi

    for target in "${targets[@]}"; do
        mkdir -p "$target"
    done

    if shopt -q nullglob; then
        nullglob_was_set=1
    else
        shopt -s nullglob
    fi

    for source in "$wallpapers_subdir" "$wallpaper_dir"; do
        [[ -d "$source" ]] || continue

        assets=(
            "$source"/*.png
            "$source"/*.jpg
            "$source"/*.jpeg
            "$source"/*.webp
            "$source"/*.bmp
            "$source"/*.tif
            "$source"/*.tiff
        )

        if (( ${#assets[@]} == 0 )); then
            continue
        fi

        has_assets=true
        cp "${assets[@]}" /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
        cp "${assets[@]}" /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
        cp "${assets[@]}" /usr/share/mados/wallpapers/ 2>/dev/null || true
        cp "${assets[@]}" /usr/share/backgrounds/ 2>/dev/null || true
    done

    if [[ $nullglob_was_set -eq 0 ]]; then
        shopt -u nullglob
    fi

    if [[ "$has_assets" == false ]]; then
        echo "  → No wallpaper image assets found in ${wallpaper_dir}"
        return 0
    fi

    if [[ -d /home/mados ]]; then
        mkdir -p /home/mados/.local/share/mados/wallpapers
        mkdir -p /home/mados/Pictures/Wallpapers

        if shopt -q nullglob; then
            nullglob_was_set=1
        else
            nullglob_was_set=0
            shopt -s nullglob
        fi

        assets=(
            /usr/share/mados/wallpapers/*.png
            /usr/share/mados/wallpapers/*.jpg
            /usr/share/mados/wallpapers/*.jpeg
            /usr/share/mados/wallpapers/*.webp
            /usr/share/mados/wallpapers/*.bmp
            /usr/share/mados/wallpapers/*.tif
            /usr/share/mados/wallpapers/*.tiff
        )

        if (( ${#assets[@]} > 0 )); then
            cp "${assets[@]}" /home/mados/.local/share/mados/wallpapers/ 2>/dev/null || true
            cp "${assets[@]}" /home/mados/Pictures/Wallpapers/ 2>/dev/null || true
        fi

        if [[ $nullglob_was_set -eq 0 ]]; then
            shopt -u nullglob
        fi

        chown -R 1000:1000 /home/mados/.local/share/mados
        chown -R 1000:1000 /home/mados/Pictures
    fi

    echo "✓ Wallpaper assets configured"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_wallpaper_assets
fi
