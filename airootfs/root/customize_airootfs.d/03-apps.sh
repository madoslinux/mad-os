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

clone_repo() {
    local repo="$1"
    local dest="$2"
    local url="https://github.com/${repo}.git"
    
    git clone --depth=1 "$url" "$dest"
}

install_single_app() {
    local app="$1"
    local python_app_name="${app//-/_}"
    local python_app_dir="/usr/local/lib/${python_app_name}"
    local launcher="/usr/local/bin/${app}"
    
    if [[ -d "$python_app_dir/.git" ]]; then
        echo "Updating $app..."
        (cd "$python_app_dir" && git pull --ff-only origin main) 2>/dev/null || true
        return 0
    fi
    
    echo "Installing $app from GitHub..."
    
    local build_dir
    build_dir=$(mktemp -d)
    
    if ! clone_repo "${GITHUB_REPO}/${app}" "$build_dir/${app}"; then
        rm -rf "$build_dir"
        return 1
    fi
    
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
    for app in "${MADOS_APPS[@]}"; do
        install_single_app "$app" || true
    done
}

setup_wallpaper_desktop_entry() {
    local wallpaper_dir="/usr/local/lib/mados_wallpaper"
    
    if [[ ! -d "$wallpaper_dir" ]]; then
        return 0
    fi
    
    if [[ -f "$wallpaper_dir/mados-wallpaper.desktop" ]]; then
        cp "$wallpaper_dir/mados-wallpaper.desktop" /usr/share/applications/
    fi
    
    if [[ -f "$wallpaper_dir/mados-wallpaper.svg" ]]; then
        mkdir -p /usr/share/icons/hicolor/scalable/apps
        cp "$wallpaper_dir/mados-wallpaper.svg" /usr/share/icons/hicolor/scalable/apps/
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
}

install_installer() {
    local installer_python_dir="/usr/local/lib/mados_installer"
    local installer_launcher="/usr/local/bin/${INSTALLER_APP}"
    
    if [[ -d "$installer_python_dir/.git" ]]; then
        rm -rf "$installer_python_dir"
    fi
    
    echo "Installing $INSTALLER_APP from GitHub..."
    
    local build_dir
    build_dir=$(mktemp -d)
    
    if ! clone_repo "${INSTALLER_GITHUB_REPO}/${INSTALLER_APP}" "$build_dir/${INSTALLER_APP}"; then
        rm -rf "$build_dir"
        return 1
    fi
    
    mkdir -p /usr/local/lib
    mv "$build_dir/${INSTALLER_APP}" "$installer_python_dir"
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
    local updater_python_dir="/usr/local/lib/mados_updater"
    local updater_launcher="/usr/local/bin/${UPDATER_APP}"
    
    if [[ -d "$updater_python_dir/.git" ]]; then
        rm -rf "$updater_python_dir"
    fi
    
    echo "Installing $UPDATER_APP from GitHub..."
    
    local build_dir
    build_dir=$(mktemp -d)
    
    if ! clone_repo "${UPDATER_GITHUB_REPO}/${UPDATER_APP}" "$build_dir/${UPDATER_APP}"; then
        rm -rf "$build_dir"
        return 1
    fi
    
    mkdir -p /usr/local/lib
    mv "$build_dir/${UPDATER_APP}" "$updater_python_dir"
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
        return 0
    fi
    
    echo "Installing Oh My Zsh..."
    
    if ! clone_repo "ohmyzsh/ohmyzsh" "$omz_dir"; then
        return 1
    fi
    
    if [[ -d /home/mados ]]; then
        rm -rf /home/mados/.oh-my-zsh
        ln -sf /usr/share/oh-my-zsh /home/mados/.oh-my-zsh
        chown -h 1000:1000 /home/mados/.oh-my-zsh
    fi
    
    rm -rf /root/.oh-my-zsh
    ln -sf /usr/share/oh-my-zsh /root/.oh-my-zsh
    
    if [[ ! -d /etc/skel/.oh-my-zsh ]]; then
        ln -sf /usr/share/oh-my-zsh /etc/skel/.oh-my-zsh
    fi
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mados_apps
    setup_wallpaper_desktop_entry
    install_installer
    install_updater
    install_oh_my_zsh
fi
