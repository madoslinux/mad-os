#!/usr/bin/env bash
# 02-themes.sh - Install GTK themes, icons, and fonts
# Atomic module for theme installation
set -euo pipefail

apply_default_gtk_theme() {
    local settings_file="/etc/gtk-3.0/settings.ini"

    mkdir -p /etc/gtk-3.0
    if [[ -f "$settings_file" ]]; then
        sed -i 's/^gtk-theme-name=.*/gtk-theme-name=adw-gtk3-dark/' "$settings_file"
        sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=Papirus/' "$settings_file"
    else
        cat > "$settings_file" << 'EOF'
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus
gtk-font-name=Hack Nerd Font 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=16
gtk-application-prefer-dark-theme=true
gtk-decoration-layout=:minimize,maximize,close
EOF
    fi

    echo "✓ Default GTK theme set to adw-gtk3-dark (Papirus icons)"
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
    apply_default_gtk_theme
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
