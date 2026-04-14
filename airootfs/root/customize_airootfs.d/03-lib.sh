#!/usr/bin/env bash
# 03-lib.sh - Shared variables and helper functions for app installation
# This file should be sourced by all app installation scripts
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

NUCLEAR_GITHUB_REPO="madoslinux"
NUCLEAR_INSTALL_DIR="/opt/nuclear"
NUCLEAR_BIN="/usr/local/bin/nuclear"

GITHUB_REPO="madoslinux"
INSTALLER_APP="mados-installer"
INSTALLER_GITHUB_REPO="madoslinux"
INSTALLER_TAG_PATTERN="v*"
UPDATER_APP="mados-updater"
UPDATER_GITHUB_REPO="madkoding"

INSTALL_DIR="/opt/mados"
BIN_DIR="/usr/local/bin"
BUILD_DIR="/root/build_tmp"

IMPERATIVE_DOTS_REPO="madkoding/theme-imperative-dots"
IMPERATIVE_DOTS_INSTALL_DIR="/usr/share/mados/themes/imperative-dots"

SKWD_WALL_REPO="madkoding/skwd-wall"
SKWD_WALL_INSTALL_DIR="/usr/local/share/skwd-wall"
SKWD_WALL_COMPAT_DIR="/opt/mados/skwd-wall"
SKWD_WALL_BIN="/usr/local/bin/skwd-wall"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

clone_latest_main() {
    local repo_url="$1"
    local dest_dir="$2"
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --branch main --no-tags "$repo_url" "$dest_dir"
}

resolve_latest_tag() {
    local repo_url="$1"
    local pattern="$2"
    git ls-remote --refs --tags "$repo_url" "$pattern" | awk -F/ 'NF {print $NF}' | sort -V | awk 'END {print}'
}

clone_latest_tag() {
    local repo_url="$1"
    local dest_dir="$2"
    local latest_tag=""
    latest_tag=$(resolve_latest_tag "$repo_url" "$INSTALLER_TAG_PATTERN")
    if [[ -z "$latest_tag" ]]; then
        echo "ERROR: Could not resolve latest tag (${INSTALLER_TAG_PATTERN}) from ${repo_url}"
        return 1
    fi
    echo "  → Resolved installer tag: ${latest_tag}"
    GIT_TERMINAL_PROMPT=0 git init -q "$dest_dir"
    git -C "$dest_dir" remote add origin "$repo_url"
    GIT_TERMINAL_PROMPT=0 git -C "$dest_dir" fetch --depth=1 origin "refs/tags/${latest_tag}:refs/tags/${latest_tag}"
    git -C "$dest_dir" checkout --detach -q FETCH_HEAD
    return 0
}

assert_installer_contract() {
    local install_path="$1"
    local required_files=(
        "${install_path}/__main__.py"
        "${install_path}/installer/steps.py"
        "${install_path}/scripts/configure-grub.sh"
        "${install_path}/scripts/setup-bootloader.sh"
        "${install_path}/scripts/apply-configuration.sh"
        "${install_path}/scripts/enable-services.sh"
    )
    local f
    for f in "${required_files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: Installer contract missing required file: $f"
            return 1
        fi
    done
    if grep -q 'ensure_btrfs_rootflags()' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh still defines ensure_btrfs_rootflags"
        return 1
    fi
    if ! grep -q 'Drop malformed bare subvol= tokens' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing bare subvol token sanitizer"
        return 1
    fi
    if grep -q 'ensure_cmdline_token "subvol=' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh still injects bare subvol= kernel args"
        return 1
    fi
    if grep -q '^ensure_btrfs_rootflags$' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh still calls ensure_btrfs_rootflags"
        return 1
    fi
    if grep -q '^ensure_cmdline_token "splash"$' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh still injects splash in GRUB_CMDLINE_LINUX"
        return 1
    fi
    if grep -q '^ensure_cmdline_token "quiet"$' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh still injects quiet in GRUB_CMDLINE_LINUX"
        return 1
    fi
    if ! grep -q 'sanitize_grub_cmdline_key "GRUB_CMDLINE_LINUX"' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing GRUB_CMDLINE_LINUX sanitizer call"
        return 1
    fi
    if ! grep -q 'sanitize_grub_cmdline_key "GRUB_CMDLINE_LINUX_DEFAULT"' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing GRUB_CMDLINE_LINUX_DEFAULT sanitizer call"
        return 1
    fi
    if ! grep -q 'sanitize_generated_grub_cfg()' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing grub.cfg sanitizer"
        return 1
    fi
    if ! grep -q 'grub.cfg still contains invalid rootflag= token' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing grub.cfg rootflag assertion"
        return 1
    fi
    if ! grep -q 'grub.cfg still contains invalid bare subvol= token' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing grub.cfg bare subvol assertion"
        return 1
    fi
    if grep -q 'ensure_cmdline_token "rootflag=' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh still injects legacy rootflag= token"
        return 1
    fi
    if grep -q 'rootflags=subvol=@' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh still forces rootflags=subvol=@"
        return 1
    fi
    if ! grep -q 'retrying without ACL/xattr' "${install_path}/installer/steps.py"; then
        echo "ERROR: Installer contract check failed: steps.py missing rsync metadata fallback"
        return 1
    fi
    if grep -q 'wifi.backend=iwd' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh still forces iwd backend"
        return 1
    fi
    if grep -q 'enable_service iwd' "${install_path}/scripts/enable-services.sh"; then
        echo "ERROR: Installer contract check failed: enable-services.sh still enables iwd"
        return 1
    fi
    if grep -q 'Current=sddm-astron_theme' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh still sets astron SDDM theme"
        return 1
    fi
    if ! grep -q 'autologin-live.conf' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh missing SDDM autologin cleanup"
        return 1
    fi
    return 0
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
    if [[ "$app_name" != "mados-wallpaper" ]]; then
        if [[ -f "${install_path}/${app_name}" && "$app_name" == "mados-installer" ]]; then
            :
        else
            if [[ "$app_name" == "mados-updater" ]]; then
                cat > "$bin_path" << 'EOF'
#!/bin/bash
if [[ "$EUID" -ne 0 ]]; then
    exec sudo -E "$0" "$@"
fi
export PYTHONPATH="${INSTALL_DIR}:${PYTHONPATH:-}"
cd "${install_path}"
exec python3 -m "${module_name}" "$@"
EOF
            else
                cat > "$bin_path" << EOF
#!/bin/bash
export PYTHONPATH="${INSTALL_DIR}:\${PYTHONPATH:-}"
cd "${install_path}"
exec python3 -m "${module_name}" "\$@"
EOF
            fi
            chmod +x "$bin_path"
        fi
    fi
    if [[ "$app_name" != "mados-wallpaper" && -f "${install_path}/${app_name}.desktop" ]]; then
        cp "${install_path}/${app_name}.desktop" /usr/share/applications/
        echo "  → Installed desktop file"
    fi
    echo "✓ ${app_name} installed to ${install_path}"
    return 0
}
