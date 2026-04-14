#!/usr/bin/env bash
# 02-themes.sh - Install GTK themes, icons, and fonts
# Atomic module for theme installation
set -euo pipefail

install_nordic_theme() {
    local nordic_dir="/usr/share/themes/Nordic"
    local nordic_build_dir=$(mktemp -d)
    
    if [[ -d "$nordic_dir" ]]; then
        echo "Nordic theme already installed"
        rm -rf "$nordic_build_dir"
        return 0
    fi
    
    echo "Installing Nordic GTK theme..."
    if git clone --depth=1 https://github.com/EliverLara/Nordic.git "$nordic_build_dir/Nordic" 2>&1; then
        mkdir -p /usr/share/themes
        cp -a "$nordic_build_dir/Nordic" "$nordic_dir"
        rm -rf "$nordic_dir/.git" "$nordic_dir/.gitignore"
        rm -rf "$nordic_dir/Art" "$nordic_dir/LICENSE" "$nordic_dir/README.md"
        rm -rf "$nordic_dir/KDE" "$nordic_dir/Wallpaper"
        echo "✓ Nordic theme installed"
    else
        echo "WARNING: Failed to install Nordic theme"
    fi
    rm -rf "$nordic_build_dir"
    return 0
}

install_michroma_font() {
    local michroma_dir="/usr/share/fonts/truetype/michroma"
    local michroma_url="https://github.com/google/fonts/raw/main/ofl/michroma/Michroma-Regular.ttf"
    
    if [[ -d "$michroma_dir" && -f "$michroma_dir/Michroma-Regular.ttf" ]]; then
        echo "Michroma font already installed"
        return 0
    fi
    
    echo "Installing Michroma font..."
    mkdir -p "$michroma_dir"
    if curl -fsSL "$michroma_url" -o "$michroma_dir/Michroma-Regular.ttf" 2>&1; then
        echo "✓ Michroma font installed"
    else
        echo "WARNING: Failed to install Michroma font"
    fi
    return 0
}

install_logos_and_splashes() {
    local assets_dir="/usr/share/mados/assets"
    
    if [[ ! -d "$assets_dir" ]]; then
        echo "WARNING: Assets directory not found at $assets_dir"
        return 0
    fi
    
    echo "Installing logos and splashes..."
    
    if [[ -f "$assets_dir/mados-logo-cyberpunk-plymouth.png" ]]; then
        mkdir -p /usr/share/plymouth/themes/mados
        cp "$assets_dir/mados-logo-cyberpunk-plymouth.png" /usr/share/plymouth/themes/mados/logo.png
        echo "  ✓ Plymouth logo installed"
    fi
    
    if [[ -f "$assets_dir/mados-logo-cyberpunk-grub.png" ]]; then
        mkdir -p /boot/grub
        cp "$assets_dir/mados-logo-cyberpunk-grub.png" /boot/grub/logo.png
        echo "  ✓ GRUB logo installed"
    fi
    
    if [[ -f "$assets_dir/mados-logo-cyberpunk-installer.png" ]]; then
        mkdir -p /usr/share/plymouth/themes/mados
        cp "$assets_dir/mados-logo-cyberpunk-installer.png" /usr/share/plymouth/themes/mados/installer.png 2>/dev/null || true
        echo "  ✓ Installer logo installed"
    fi
    
    echo "✓ Logos and splashes installed"
    return 0
}

install_themes() {
    install_nordic_theme

    install_michroma_font
    install_logos_and_splashes
    fc-cache -f /usr/share/fonts/truetype/ 2>/dev/null || true
    echo "✓ Themes installation complete"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS Theme Installation ==="
    install_themes
    echo "=== Theme installation complete ==="
fi
