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
INSTALLER_REF_TAG="v1.0.4"
INSTALLER_REF_COMMIT="259d14cb722f86ef17aa6a8e5f265ea88020ee38"
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

clone_ref_verified() {
    local repo_url="$1"
    local dest_dir="$2"
    local ref="$3"
    local expected_commit="$4"

    local resolved_tag_commit=""
    resolved_tag_commit=$(git ls-remote "$repo_url" "refs/tags/${ref}^{}" | awk 'NR==1 {print $1}')
    if [[ -z "$resolved_tag_commit" ]]; then
        resolved_tag_commit=$(git ls-remote "$repo_url" "refs/tags/${ref}" | awk 'NR==1 {print $1}')
    fi
    if [[ -z "$resolved_tag_commit" ]]; then
        echo "ERROR: Could not resolve tag ${ref} from ${repo_url}"
        return 1
    fi
    if [[ "$resolved_tag_commit" != "$expected_commit" ]]; then
        echo "ERROR: ${repo_url} tag ${ref} resolves to ${resolved_tag_commit}, expected ${expected_commit}"
        return 1
    fi

    GIT_TERMINAL_PROMPT=0 git init -q "$dest_dir"
    git -C "$dest_dir" remote add origin "$repo_url"
    GIT_TERMINAL_PROMPT=0 git -C "$dest_dir" fetch --depth=1 origin "$expected_commit"
    git -C "$dest_dir" checkout --detach -q FETCH_HEAD

    local actual_commit
    actual_commit=$(git -C "$dest_dir" rev-parse HEAD)
    if [[ "$actual_commit" != "$expected_commit" ]]; then
        echo "ERROR: ${repo_url} ref ${ref} resolved to ${actual_commit}, expected ${expected_commit}"
        return 1
    fi

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

    if ! grep -q 'ensure_btrfs_rootflags' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing ensure_btrfs_rootflags"
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
    
    # Keep mados-wallpaper as assets-only package (no executable wrappers)
    if [[ "$app_name" != "mados-wallpaper" ]]; then
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
    fi
    
    # Copy desktop file if exists (except assets-only wallpaper package)
    if [[ "$app_name" != "mados-wallpaper" && -f "${install_path}/${app_name}.desktop" ]]; then
        cp "${install_path}/${app_name}.desktop" /usr/share/applications/
        echo "  → Installed desktop file"
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
        if clone_ref_verified \
            "https://github.com/${INSTALLER_GITHUB_REPO}/${installer_name}.git" \
            "${build_dir}/${installer_module}" \
            "$INSTALLER_REF_TAG" \
            "$INSTALLER_REF_COMMIT"; then
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

    # Keep installed-system Plymouth logo size identical to live ISO theme.
    if [[ -f "${install_path}/scripts/setup-plymouth.sh" ]]; then
        sed -i 's/logo.image = Image("logo.png");/logo.image = Image("logo.png");\nlogo.image = logo.image.Scale(250, 250);/' "${install_path}/scripts/setup-plymouth.sh"
        if ! grep -q 'logo.image = logo.image.Scale(250, 250);' "${install_path}/scripts/setup-plymouth.sh"; then
            echo "ERROR: Failed to enforce Plymouth logo scale"
            return 1
        fi
        echo "  → Synced installer Plymouth logo scale with live ISO"
    fi

    # Keep installed system on NetworkManager-only (no iwd backend override).
    # Avoid deleting heredoc blocks (can break script syntax); drop only the iwd line.
    if [[ -f "${install_path}/scripts/apply-configuration.sh" ]]; then
        sed -i '/wifi\.backend=iwd/d' "${install_path}/scripts/apply-configuration.sh"
        if grep -q 'wifi.backend=iwd' "${install_path}/scripts/apply-configuration.sh"; then
            echo "ERROR: Failed to remove installer iwd backend override"
            return 1
        fi
        echo "  → Removed installer iwd backend override line"
    fi

    # Harden GRUB cmdline handling: never pass bare subvol= to kernel.
    # If root is Btrfs with subvol option in fstab, translate it to rootflags=subvol=... .
    if [[ -f "${install_path}/scripts/configure-grub.sh" ]]; then
        python3 - "${install_path}/scripts/configure-grub.sh" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
changed = False

legacy_non_btrfs_fallback = '''    if [[ -n "$root_subvol" ]]; then
        ensure_cmdline_token "rootflags=${root_subvol}"
    else
        ensure_cmdline_token "rootflags=subvol=@"
    fi
'''

strict_btrfs_only = '''    if [[ -n "$root_subvol" ]]; then
        ensure_cmdline_token "rootflags=${root_subvol}"
    fi
'''

if legacy_non_btrfs_fallback in t:
    t = t.replace(legacy_non_btrfs_fallback, strict_btrfs_only, 1)
    changed = True

inject_after = '    set_grub_key "GRUB_CMDLINE_LINUX" "\\"$current\\""\n'
block = """
    # Drop malformed bare subvol= tokens (invalid as kernel args).
    current=$(printf '%s' "$current" | sed -E 's/(^|[[:space:]])subvol=[^[:space:]]+([[:space:]]|$)/ /g; s/[[:space:]]+/ /g; s/^ //; s/ $//')
    set_grub_key "GRUB_CMDLINE_LINUX" "\"$current\""
}

ensure_btrfs_rootflags() {
    local root_subvol=""
    if [[ -f /etc/fstab ]]; then
        root_subvol=$(awk '$2 == "/" && $3 == "btrfs" { n=split($4, opts, ","); for (i=1; i<=n; i++) if (opts[i] ~ /^subvol=/) { print opts[i]; exit } }' /etc/fstab)
    fi

    if [[ -n "$root_subvol" ]]; then
        ensure_cmdline_token "rootflags=${root_subvol}"
    fi
"""

if inject_after in t and "ensure_btrfs_rootflags()" not in t:
    t = t.replace(inject_after, block, 1)
    t = t.replace('ensure_cmdline_token "plymouth.use-simpledrm=0"\n', 'ensure_cmdline_token "plymouth.use-simpledrm=0"\nensure_btrfs_rootflags\n', 1)

    changed = True

if changed:
    p.write_text(t, encoding="utf-8")
PY
        if ! grep -q 'ensure_btrfs_rootflags' "${install_path}/scripts/configure-grub.sh"; then
            echo "ERROR: Failed to harden installer GRUB cmdline handling"
            return 1
        fi
        echo "  → Hardened installer GRUB cmdline subvol/rootflags handling"
    fi

    # Make rsync stage resilient when /boot is VFAT (no ACL/xattr support).
    # Retry rsync without ACL/xattr preservation only if the first pass fails.
    if [[ -f "${install_path}/installer/steps.py" ]]; then
        python3 - "${install_path}/installer/steps.py" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

old = '''    proc.wait()
    if proc.returncode not in (0, 24):
        raise subprocess.CalledProcessError(proc.returncode, "rsync")
    if proc.returncode == 24:
        log_message(
            app,
            "  WARNING: rsync reported vanished source files (normal on live system)",
        )
'''

new = '''    proc.wait()
    if proc.returncode not in (0, 24):
        if proc.returncode == 23:
            log_message(
                app,
                "  WARNING: rsync metadata copy failed on some filesystems; retrying without ACL/xattr...",
            )
            retry_cmd = [
                "rsync",
                "-aHWS",
                "--info=progress2",
                "--no-inc-recursive",
                "--numeric-ids",
            ]
            for exc in RSYNC_EXCLUDES:
                retry_cmd.extend(["--exclude", exc])
            retry_cmd.extend(["/", "/mnt/"])

            retry = subprocess.run(
                retry_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )

            for line in retry.stdout.splitlines():
                line = line.rstrip()
                if line.startswith("rsync:") or line.startswith("sent "):
                    log_message(app, f"  {line}")

            if retry.returncode not in (0, 24):
                raise subprocess.CalledProcessError(retry.returncode, "rsync")
            if retry.returncode == 24:
                log_message(
                    app,
                    "  WARNING: rsync reported vanished source files (normal on live system)",
                )
        else:
            raise subprocess.CalledProcessError(proc.returncode, "rsync")
    elif proc.returncode == 24:
        log_message(
            app,
            "  WARNING: rsync reported vanished source files (normal on live system)",
        )
'''

if old in t and "retrying without ACL/xattr" not in t:
    t = t.replace(old, new, 1)
    p.write_text(t, encoding="utf-8")
PY
        if ! grep -q 'retrying without ACL/xattr' "${install_path}/installer/steps.py"; then
            echo "ERROR: Failed to harden installer rsync metadata fallback"
            return 1
        fi
        echo "  → Hardened installer rsync for VFAT /boot metadata limitations"
    fi

    if [[ -f "${install_path}/scripts/enable-services.sh" ]]; then
        sed -i '/enable_service iwd/d' "${install_path}/scripts/enable-services.sh"
        if grep -q 'enable_service iwd' "${install_path}/scripts/enable-services.sh"; then
            echo "ERROR: Failed to remove iwd enable from installer services"
            return 1
        fi
        echo "  → Removed installer iwd service enable"
    fi

    if ! assert_installer_contract "$install_path"; then
        return 1
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

SKWD_WALL_REPO="liixini/skwd-wall"
SKWD_WALL_INSTALL_DIR="/opt/mados/skwd-wall"
SKWD_WALL_BIN="/usr/local/bin/skwd-wall"

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

    mkdir -p "$INSTALL_DIR"
    rm -rf "$SKWD_WALL_INSTALL_DIR"
    mv "${build_dir}/skwd-wall" "$SKWD_WALL_INSTALL_DIR"
    rm -rf "$build_dir"

    cat > "$SKWD_WALL_BIN" << 'SKWD_WALL_WRAPPER'
#!/bin/bash
set -euo pipefail

SKWD_DAEMON="/opt/mados/skwd-wall/daemon.qml"
SKWD_PATTERN="quickshell.*${SKWD_DAEMON}"

start_daemon() {
    if pgrep -f "$SKWD_PATTERN" >/dev/null 2>&1; then
        return 0
    fi

    quickshell -p "$SKWD_DAEMON" >/dev/null 2>&1 &

    local tries=0
    while [ $tries -lt 25 ]; do
        if pgrep -f "$SKWD_PATTERN" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
        tries=$((tries + 1))
    done

    return 1
}

if [[ "$1" == "daemon" ]]; then
    exec quickshell -p "$SKWD_DAEMON"
elif [[ "$1" == "toggle" ]]; then
    start_daemon || exit 1
    exec quickshell ipc -p "$SKWD_DAEMON" call wallpaper toggle
else
    start_daemon || exit 1
    exec quickshell ipc -p "$SKWD_DAEMON" call wallpaper toggle
fi
SKWD_WALL_WRAPPER
    chmod +x "$SKWD_WALL_BIN"

    echo "✓ skwd-wall installed to ${SKWD_WALL_INSTALL_DIR}"
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
    mkdir -p /etc/skel/Pictures/Wallpapers
    cp "$wallpaper_dir"/*.png /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.png /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    
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
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mados_apps
    setup_wallpaper_assets
    install_skwd_wall
    install_installer
    install_updater
    install_oh_my_zsh
fi
