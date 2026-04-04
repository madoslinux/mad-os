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

INSTALL_DIR="/opt/mados"
BIN_DIR="/usr/local/bin"
BUILD_DIR="/root/build_tmp"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

clone_latest_main() {
    local repo_url="$1"
    local dest_dir="$2"

    # Force fresh network clone from main on every build.
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --branch main --no-tags "$repo_url" "$dest_dir"
}

clone_and_install_app() {
    local repo="$1"
    local app_name="$2"
    local module_name="${app_name//-/_}"
    local install_path="${INSTALL_DIR}/${module_name}"
    local bin_path="${BIN_DIR}/${app_name}"
    
    echo "Installing ${app_name}..."
    
    local build_dir="${BUILD_DIR}/${module_name}_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$BUILD_DIR"
    
    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if clone_latest_main "https://github.com/${repo}.git" "${build_dir}/${module_name}"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done
    
    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone ${repo} after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi
    
    mkdir -p "$INSTALL_DIR"
    rm -rf "$install_path"
    mv "${build_dir}/${module_name}" "$install_path"
    rm -rf "$build_dir"
    
    # Use original bash wrapper if it exists and is actually a bash script (for complex apps like installer)
    if [[ -f "${install_path}/${app_name}" && "$app_name" == "mados-installer" ]]; then
        # Skip - installer has special handling below
        :
    else
        # Create wrapper script for all apps
        # mados-updater needs root privileges to manage /etc and system updates
        if [[ "$app_name" == "mados-updater" ]]; then
            cat > "$bin_path" << EOF
#!/bin/bash
if [[ "\$EUID" -ne 0 ]]; then
    exec sudo -E "\$0" "\$@"
fi
export PYTHONPATH="${INSTALL_DIR}:\${PYTHONPATH:-}"
cd "${install_path}"
exec python3 -m "${module_name}" "\$@"
EOF
        else
            # cd to install_path so python3 -m can find the module
            cat > "$bin_path" << EOF
#!/bin/bash
export PYTHONPATH="${INSTALL_DIR}:\${PYTHONPATH:-}"
cd "${install_path}"
exec python3 -m "${module_name}" "\$@"
EOF
        fi
        chmod +x "$bin_path"
    fi
    
    # Copy desktop file if exists
    if [[ -f "${install_path}/${app_name}.desktop" ]]; then
        cp "${install_path}/${app_name}.desktop" /usr/share/applications/
        echo "  → Installed desktop file"
    fi
    
    # Handle wallpaper daemon (runs as python3 -m daemon)
    if [[ "$app_name" == "mados-wallpaper" && -d "${install_path}/daemon" ]]; then
        cat > "${BIN_DIR}/mados-wallpaperd" << WALLPAPERD
#!/bin/bash
export PYTHONPATH="${install_path}:\${PYTHONPATH:-}"
cd "${install_path}"
exec python3 -m daemon "\$@"
WALLPAPERD
        chmod +x "${BIN_DIR}/mados-wallpaperd"
    fi
    
    echo "✓ ${app_name} installed to ${install_path}"
    return 0
}

install_mados_apps() {
    for app in "${MADOS_APPS[@]}"; do
        clone_and_install_app "${GITHUB_REPO}/${app}" "$app"
    done
}

install_installer() {
    local installer_name="mados-installer"
    local installer_module="mados_installer"
    local install_path="${INSTALL_DIR}/${installer_module}"
    local bin_path="${BIN_DIR}/${installer_name}"
    
    echo "Installing ${installer_name}..."
    
    local build_dir="${BUILD_DIR}/${installer_module}_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if clone_latest_main "https://github.com/${INSTALLER_GITHUB_REPO}/${installer_name}.git" "${build_dir}/${installer_module}"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done
    
    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone ${INSTALLER_GITHUB_REPO}/${installer_name} after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi
    
    mkdir -p "$INSTALL_DIR"
    rm -rf "$install_path"
    mv "${build_dir}/${installer_module}" "$install_path"
    rm -rf "$build_dir"

    # Fix import in locale.py (bug in upstream: uses 'from summary' instead of 'from .summary')
    if [[ -f "${install_path}/pages/locale.py" ]]; then
        sed -i 's/from summary import/from .summary import/g' "${install_path}/pages/locale.py"
        echo "  → Fixed import in locale.py"
    fi

    # Keep installed-system Plymouth logo size identical to live ISO theme.
    if [[ -f "${install_path}/scripts/setup-plymouth.sh" ]]; then
        sed -i 's/logo.image = Image("logo.png");/logo.image = Image("logo.png");\nlogo.image = logo.image.Scale(250, 250);/' "${install_path}/scripts/setup-plymouth.sh"
        echo "  → Synced installer Plymouth logo scale with live ISO"
    fi

    # Create wrapper for installer (uses python3 __main__.py from package dir)
    cat > "$bin_path" << 'INSTALLER_WRAPPER'
#!/bin/bash
INSTALL_DIR="/opt/mados"
INSTALL_PATH="/opt/mados/mados_installer"
LOG_FILE="/var/log/mados-installer.log"

# Installer must run as root in live environment
if [[ "$EUID" -ne 0 ]]; then
    exec sudo -E "$0" "$@"
fi

# Ensure log file exists and is writable
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
touch "$LOG_FILE" 2>/dev/null || true
chmod 666 "$LOG_FILE" 2>/dev/null || true

log_msg() {
    echo "$1" | tee -a "$LOG_FILE"
}

log_msg "[mados-installer] Starting at $(date)"
log_msg "[mados-installer] PYTHONPATH=$INSTALL_DIR"
export PYTHONPATH="$INSTALL_DIR:${PYTHONPATH:-}"
cd "$INSTALL_PATH" || { log_msg "cd failed to $INSTALL_PATH"; exit 1; }
log_msg "[mados-installer] CWD=$(pwd)"
log_msg "[mados-installer] DEMO_MODE=$DEMO_MODE"
log_msg "[mados-installer] DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
log_msg "[mados-installer] Running python3 __main__.py..."
python3 __main__.py "$@" 2>&1 | tee -a "$LOG_FILE"
EXIT_CODE=$?
log_msg "[mados-installer] Exited with code: $EXIT_CODE"
exit $EXIT_CODE
INSTALLER_WRAPPER
    chmod +x "$bin_path"
    
    if [[ -f "${install_path}/${installer_name}.desktop" ]]; then
        cp "${install_path}/${installer_name}.desktop" /usr/share/applications/
        # Force sudo launch from desktop entry in live environment
        sed -i 's|^Exec=.*|Exec=sudo /usr/local/bin/mados-installer|' "/usr/share/applications/${installer_name}.desktop"
        echo "  → Updated desktop Exec to run with sudo"
    fi
    
    echo "✓ ${installer_name} installed to ${install_path}"
    return 0
}

install_updater() {
    clone_and_install_app "${UPDATER_GITHUB_REPO}/${UPDATER_APP}" "$UPDATER_APP"
}

install_oh_my_zsh() {
    local omz_dir="/usr/share/oh-my-zsh"
    
    if [[ -d "$omz_dir" ]]; then
        return 0
    fi
    
    echo "Installing Oh My Zsh..."
    
    local build_dir="${BUILD_DIR}/ohmyzsh_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --no-tags "https://github.com/ohmyzsh/ohmyzsh.git" "${build_dir}/ohmyzsh"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done
    
    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone oh-my-zsh after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi
    
    mv "${build_dir}/ohmyzsh" "$omz_dir"
    rm -rf "$build_dir"
    
    if [[ -d /home/mados ]]; then
        rm -rf /home/mados/.oh-my-zsh
        ln -sf "$omz_dir" /home/mados/.oh-my-zsh
        chown -h 1000:1000 /home/mados/.oh-my-zsh
    fi
    
    rm -rf /root/.oh-my-zsh
    ln -sf "$omz_dir" /root/.oh-my-zsh
    
    if [[ ! -d /etc/skel/.oh-my-zsh ]]; then
        ln -sf "$omz_dir" /etc/skel/.oh-my-zsh
    fi
    
    echo "✓ Oh My Zsh installed"
    return 0
}

setup_wallpaper_assets() {
    local wallpaper_dir="${INSTALL_DIR}/mados_wallpaper"
    
    if [[ ! -d "$wallpaper_dir" ]]; then
        return 0
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

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mados_apps
    setup_wallpaper_assets
    install_installer
    install_updater
    install_oh_my_zsh
fi
