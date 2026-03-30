#!/usr/bin/env bash
# 03-apps.sh - Install madOS native applications
# Atomic module for apps installation
set -euo pipefail

MADOS_APPS=(
    "mados-audio-player"
    "mados-equalizer"
    "mados-launcher"
    "mados-pdf-viewer"
    "mados-photo-viewer"
    "mados-video-player"
    "mados-wallpaper"
)

GITHUB_REPO="madoslinux"
INSTALLER_APP="mados-installer"
INSTALLER_GITHUB_REPO="madoslinux"
UPDATER_APP="mados-updater"
UPDATER_GITHUB_REPO="madkoding"

install_single_app() {
    local app="$1"
    local python_app_name="${app//-/_}"
    local app_dir="/usr/local/lib/${app}"
    local python_app_dir="/usr/local/lib/${python_app_name}"
    local launcher="/usr/local/bin/${app}"
    
    if [[ -d "$python_app_dir/.git" ]]; then
        echo "Updating $app..."
        (cd "$python_app_dir" && git pull --ff-only origin main) 2>/dev/null || true
        return 0
    fi
    
    echo "Installing $app from GitHub..."
    rm -rf "$app_dir" "$python_app_dir"
    
    local build_dir
    build_dir=$(mktemp -d)
    
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 "https://github.com/${GITHUB_REPO}/${app}.git" "$build_dir/${app}" || {
        rm -rf "$build_dir"
        echo "WARNING: Failed to clone $app"
        return 1
    }
    
    mkdir -p /usr/local/lib
    mv "$build_dir/${app}" "$python_app_dir"
    rm -rf "$build_dir"
    
    cat > "$launcher" << 'EOF'
#!/bin/bash
cd "/usr/local/lib/${python_app_name}"
export PYTHONPATH="/usr/local/lib:${PYTHONPATH:-}"
exec python3 -m "${python_app_name}" "$@"
EOF
    chmod +x "$launcher"
    
    if [[ "$app" == "mados-wallpaper" && -f "$python_app_dir/daemon/mados-wallpaperd" ]]; then
        cp "$python_app_dir/daemon/mados-wallpaperd" /usr/local/bin/mados-wallpaperd
        chmod +x /usr/local/bin/mados-wallpaperd
    fi
    
    echo "✓ $app installed"
    return 0
}

install_mados_apps() {
    local failed=0
    for app in "${MADOS_APPS[@]}"; do
        if ! install_single_app "$app"; then
            echo "WARNING: Failed to install $app"
            failed=1
        fi
    done
    return $failed
}

setup_wallpaper_desktop_entry() {
    local wallpaper_dir="/usr/local/lib/mados_wallpaper"
    
    if [[ ! -d "$wallpaper_dir" ]]; then
        return 0
    fi
    
    echo "Setting up mados-wallpaper desktop entry..."
    
    if [[ -f "$wallpaper_dir/mados-wallpaper.desktop" ]]; then
        cp "$wallpaper_dir/mados-wallpaper.desktop" /usr/share/applications/
        echo "  → Desktop entry installed"
    fi
    
    if [[ -f "$wallpaper_dir/mados-wallpaper.svg" ]]; then
        mkdir -p /usr/share/icons/hicolor/scalable/apps
        cp "$wallpaper_dir/mados-wallpaper.svg" /usr/share/icons/hicolor/scalable/apps/
        echo "  → Icon installed"
    fi
    
    mkdir -p /etc/skel/.local/share/mados/wallpapers
    cp "$wallpaper_dir"/*.png /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    
    mkdir -p /usr/share/backgrounds
    cp "$wallpaper_dir"/*.png /usr/share/backgrounds/ 2>/dev/null || true
    
    if [[ -d /home/mados ]]; then
        mkdir -p /home/mados/.local/share/mados/wallpapers
        cp "$wallpaper_dir"/*.png /home/mados/.local/share/mados/wallpapers/ 2>/dev/null || true
        chown -R 1000:1000 /home/mados/.local/share/mados
    fi
    
    return 0
}

install_installer() {
    local installer_dir="/usr/local/lib/${INSTALLER_APP}"
    local installer_python_dir="/usr/local/lib/mados_installer"
    local installer_launcher="/usr/local/bin/${INSTALLER_APP}"
    
    if [[ -d "$installer_python_dir/.git" ]]; then
        rm -rf "$installer_dir" "$installer_python_dir"
    fi
    
    echo "Installing $INSTALLER_APP from GitHub..."
    local build_dir
    build_dir=$(mktemp -d)
    
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 "https://github.com/${INSTALLER_GITHUB_REPO}/${INSTALLER_APP}.git" "$build_dir/${INSTALLER_APP}" || {
        rm -rf "$build_dir"
        echo "WARNING: Failed to install $INSTALLER_APP"
        return 1
    }
    
    mkdir -p /usr/local/lib
    mv "$build_dir/${INSTALLER_APP}" "$installer_python_dir"
    ln -sf "$installer_python_dir" "$installer_dir"
    rm -rf "$build_dir"
    
    cat > "$installer_launcher" << 'EOF'
#!/bin/bash
export PYTHONPATH="/usr/local/lib:${PYTHONPATH:-}"
cd "/usr/local/lib/mados_installer"
exec python3 -m mados_installer "$@"
EOF
    chmod +x "$installer_launcher"
    echo "✓ $INSTALLER_APP installed"
    return 0
}

install_updater() {
    local updater_dir="/usr/local/lib/${UPDATER_APP}"
    local updater_python_dir="/usr/local/lib/mados_updater"
    local updater_launcher="/usr/local/bin/${UPDATER_APP}"
    
    if [[ -d "$updater_python_dir/.git" ]]; then
        rm -rf "$updater_dir" "$updater_python_dir"
    fi
    
    echo "Installing $UPDATER_APP from GitHub..."
    local build_dir
    build_dir=$(mktemp -d)
    
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 "https://github.com/${UPDATER_GITHUB_REPO}/${UPDATER_APP}.git" "$build_dir/${UPDATER_APP}" || {
        rm -rf "$build_dir"
        echo "WARNING: Failed to install $UPDATER_APP"
        return 1
    }
    
    mkdir -p /usr/local/lib
    mv "$build_dir/${UPDATER_APP}" "$updater_python_dir"
    ln -sf "$updater_python_dir" "$updater_dir"
    rm -rf "$build_dir"
    
    cat > "$updater_launcher" << 'EOF'
#!/bin/bash
export PYTHONPATH="/usr/local/lib:${PYTHONPATH:-}"
cd "/usr/local/lib/mados_updater"
exec python3 -m mados_updater "$@"
EOF
    chmod +x "$updater_launcher"
    echo "✓ $UPDATER_APP installed"
    return 0
}

install_oh_my_zsh() {
    local omz_dir="/usr/share/oh-my-zsh"
    
    if [[ -d "$omz_dir" ]]; then
        echo "Oh My Zsh already present"
        return 0
    fi
    
    echo "Installing Oh My Zsh..."
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir" || {
        echo "WARNING: Failed to clone Oh My Zsh"
        return 1
    }
    
    echo "✓ Oh My Zsh installed"
    
    if [[ -d /home/mados ]]; then
        rm -rf /home/mados/.oh-my-zsh
        ln -sf /usr/share/oh-my-zsh /home/mados/.oh-my-zsh
        chown -h 1000:1000 /home/mados/.oh-my-zsh
    fi
    
    rm -rf /root/.oh-my-zsh
    ln -sf /usr/share/oh-my-zsh /root/.oh-my-zsh
    
    if [[ -d "$omz_dir" && ! -d /etc/skel/.oh-my-zsh ]]; then
        ln -sf /usr/share/oh-my-zsh /etc/skel/.oh-my-zsh
    fi
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS Apps Installation ==="
    install_mados_apps
    setup_wallpaper_desktop_entry
    install_installer
    install_updater
    install_oh_my_zsh
    echo "=== Apps installation complete ==="
fi
