#!/usr/bin/env bash
# 03-apps.sh - Install madOS native applications
# Atomic module for apps installation
set -euo pipefail

MADOS_APPS=(
    "mados-audio-player"
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

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

clone_latest_main() {
    local repo_url="$1"
    local dest_dir="$2"

    # Force fresh network clone from main on every build.
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
        echo "ERROR: Installer contract check failed: configure-grub.sh still defines ensure_btrfs_rootflags (duplicates rootflags)"
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
        echo "ERROR: Installer contract check failed: configure-grub.sh still calls ensure_btrfs_rootflags (duplicates rootflags)"
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

    if grep -q 'systemctl enable sddm.service' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh still enables sddm"
        return 1
    fi

    if grep -q 'sddm.service is enabled' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh still treats sddm as active display manager"
        return 1
    fi

    if grep -q 'sddm.service is NOT enabled — enabling' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh still attempts to enable sddm"
        return 1
    fi

    if ! grep -q 'systemctl enable greetd.service' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh missing greetd enable fallback"
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
        if clone_latest_tag \
            "https://github.com/${INSTALLER_GITHUB_REPO}/${installer_name}.git" \
            "${build_dir}/${installer_module}"; then
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
        sed -i 's/^Current=.*/Current=pixel-night-city/' "${install_path}/scripts/apply-configuration.sh"
        sed -i '/systemctl enable getty@tty2.service/d' "${install_path}/scripts/apply-configuration.sh"
        if grep -q 'wifi.backend=iwd' "${install_path}/scripts/apply-configuration.sh"; then
            echo "ERROR: Failed to remove installer iwd backend override"
            return 1
        fi

        python3 - "${install_path}/scripts/apply-configuration.sh" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

old = '''if [ "$GRAPHICAL_OK" -eq 0 ]; then
    echo "  ⚠ Some graphical components are missing. Enabling getty@tty1 as fallback..."
    systemctl enable getty@tty1.service 2>/dev/null || true
fi
'''

new = '''if [ "$GRAPHICAL_OK" -eq 0 ]; then
    echo "  ⚠ Some graphical components are missing. Keeping greetd path for madOS-lite."
fi
'''

if old in t:
    t = t.replace(old, new, 1)
    p.write_text(t, encoding="utf-8")
PY

        python3 - "${install_path}/scripts/apply-configuration.sh" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

old = '''if systemctl is-enabled sddm.service &>/dev/null; then
    echo "  ✓ sddm.service is enabled"
else
    echo "  ✗ sddm.service is NOT enabled — enabling..."
    systemctl enable sddm.service 2>/dev/null || true
fi

'''

new = '''if systemctl is-enabled greetd.service &>/dev/null; then
    echo "  ✓ greetd.service is enabled"
else
    echo "  ✗ greetd.service is NOT enabled — enabling..."
    systemctl enable greetd.service 2>/dev/null || true
fi

if systemctl is-enabled sddm.service &>/dev/null; then
    echo "  ⚠ sddm.service unexpectedly enabled — disabling..."
    systemctl disable sddm.service 2>/dev/null || true
fi

'''

if old in t:
    t = t.replace(old, new, 1)
    p.write_text(t, encoding="utf-8")
PY

        if ! grep -q 'madOS-lite: configure greetd' "${install_path}/scripts/apply-configuration.sh"; then
            cat >> "${install_path}/scripts/apply-configuration.sh" << 'EOGREETD'

# madOS-lite: configure greetd as display manager
mkdir -p /etc/greetd

cat > /usr/local/bin/mados-greetd-login << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

THEME="/usr/share/greetd/themes/sugar-dark.css"
SESSION_CMD="/usr/local/bin/mados-session-launch"

if [ ! -x "${SESSION_CMD}" ]; then
    echo "Missing session launcher: ${SESSION_CMD}" >&2
    exit 1
fi

if [ -r "${THEME}" ]; then
    exec tuigreet --theme "${THEME}" --cmd "${SESSION_CMD}"
fi

exec tuigreet --cmd "${SESSION_CMD}"
EOF
chmod 0755 /usr/local/bin/mados-greetd-login

cat > /usr/local/bin/mados-session-launch << 'EOF'
#!/usr/bin/env bash
set -u

LOG_FILE="/tmp/mados-greetd-session.log"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${LOG_FILE}" 2>/dev/null || true
}

export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export XDG_SESSION_TYPE=x11
export MOZ_ENABLE_WAYLAND=0

if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

if [ ! -d "${XDG_RUNTIME_DIR}" ]; then
    mkdir -p "${XDG_RUNTIME_DIR}" 2>/dev/null || true
fi
chmod 0700 "${XDG_RUNTIME_DIR}" 2>/dev/null || true

export WLR_BACKENDS=x11
export WLR_RENDERER=pixman
export WLR_NO_HARDWARE_CURSORS=1
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_GL_VERSION_OVERRIDE=3.3
export GSK_RENDERER=cairo
export CHROMIUM_FLAGS="${CHROMIUM_FLAGS:-} --disable-gpu"

log "Starting session launcher (user=${USER:-unknown}, uid=$(id -u), tty=$(tty 2>/dev/null || echo unknown), runtime=${XDG_RUNTIME_DIR})"

if [ -x /usr/local/bin/sway-session ]; then
    log "Trying sway-session (DRM -> X11 fallback)"
    if /usr/local/bin/sway-session >>"${LOG_FILE}" 2>&1; then
        exit 0
    fi
    log "sway-session failed with exit code $?"
fi

if [ -x /usr/local/bin/sway-x11-session ]; then
    log "Trying sway-x11-session (X11 -> vesa/fbdev/dummy)"
    if /usr/local/bin/sway-x11-session >>"${LOG_FILE}" 2>&1; then
        exit 0
    fi
    log "sway-x11-session failed with exit code $?"
fi

log "No compatible session launcher found"
echo "No compatible session launcher found" >>"${LOG_FILE}" 2>&1

if command -v openvt >/dev/null 2>&1; then
    log "Starting emergency shell on tty2"
    exec openvt -c 2 -f -- /bin/bash -lc 'echo "madOS session failed. Check /tmp/mados-greetd-session.log"; exec bash'
fi

sleep 2
exit 1
EOF
chmod 0755 /usr/local/bin/mados-session-launch

cat > /etc/greetd/config.toml << 'EOF'
[terminal]
vt = 1

[default_session]
command = "/usr/local/bin/mados-greetd-login"
user = "greeter"
EOF

# Ensure installed system uses greetd, not live autologin service alias.
if systemctl is-enabled mados-autologin.service >/dev/null 2>&1; then
    systemctl disable mados-autologin.service 2>/dev/null || true
fi
if [ -L /etc/systemd/system/display-manager.service ]; then
    dm_target="$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)"
    if [ "${dm_target}" = "/etc/systemd/system/mados-autologin.service" ]; then
        rm -f /etc/systemd/system/display-manager.service
    fi
fi

# Re-enable greetd after cleaning stale live-ISO display-manager alias.
# In some installs, enabling greetd earlier fails while display-manager.service
# still points to mados-autologin.service from the live environment.
if ! systemctl is-enabled greetd.service >/dev/null 2>&1; then
    systemctl enable greetd.service 2>/dev/null || true
fi
EOGREETD
        fi
        echo "  → Configured greetd for installed system"
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

if 'ensure_cmdline_token "subvol=${root_subvol}"' in t:
    t = t.replace(
        'ensure_cmdline_token "subvol=${root_subvol}"',
        'ensure_cmdline_token "rootflags=${root_subvol}"',
    )
    changed = True

sanitize_fn = '''sanitize_grub_cmdline_key() {
    local key="$1"
    local file="/etc/default/grub"
    local raw current

    raw=$(grep -E "^${key}=" "$file" | tail -n1 || true)
    if [[ -z "$raw" ]]; then
        return 0
    fi

    current=${raw#${key}=}
    current=${current#\"}
    current=${current%\"}

    current=$(printf '%s' "$current" | sed -E 's/(^|[[:space:]])subvol=[^[:space:]]+([[:space:]]|$)/ /g; s/(^|[[:space:]])rootflag=[^[:space:]]+([[:space:]]|$)/ /g; s/[[:space:]]+/ /g; s/^ //; s/ $//')
    set_grub_key "$key" "\"$current\""
}

'''

if "sanitize_grub_cmdline_key()" not in t and "ensure_btrfs_rootflags()" in t:
    t = t.replace("ensure_btrfs_rootflags() {\n", sanitize_fn + "ensure_btrfs_rootflags() {\n", 1)
    changed = True

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

sanitize_calls = '''sanitize_grub_cmdline_key "GRUB_CMDLINE_LINUX"
sanitize_grub_cmdline_key "GRUB_CMDLINE_LINUX_DEFAULT"
'''

if "sanitize_grub_cmdline_key \"GRUB_CMDLINE_LINUX\"" not in t and "ensure_btrfs_rootflags" in t:
    t = t.replace('ensure_btrfs_rootflags\n', 'ensure_btrfs_rootflags\n' + sanitize_calls, 1)
    changed = True

# Avoid duplicated rootflags: GRUB's 10_linux already injects btrfs rootflags=subvol=... .
if 'ensure_btrfs_rootflags\n' in t:
    t = t.replace('ensure_btrfs_rootflags\n', '', 1)
    changed = True

# Upstream installer must not define its own ensure_btrfs_rootflags helper;
# grub-mkconfig already manages btrfs rootflags and duplicate helpers can drift.
if "ensure_btrfs_rootflags()" in t:
    start = t.find("ensure_btrfs_rootflags() {")
    if start != -1:
        end = t.find("\n}\n", start)
        if end != -1:
            t = t[:start] + t[end + 3 :]
            changed = True

# Keep quiet/splash only in GRUB_CMDLINE_LINUX_DEFAULT.
if 'ensure_cmdline_token "splash"\n' in t:
    t = t.replace('ensure_cmdline_token "splash"\n', '', 1)
    changed = True

if 'ensure_cmdline_token "quiet"\n' in t:
    t = t.replace('ensure_cmdline_token "quiet"\n', '', 1)
    changed = True

cfg_sanitize_fn = '''sanitize_generated_grub_cfg() {
    local cfg="/boot/grub/grub.cfg"
    [[ -f "$cfg" ]] || return 0

    # Final safety net: strip invalid bare subvol/rootflag tokens from generated menu entries.
    sed -Ei 's/(^|[[:space:]])subvol=[^[:space:]]+([[:space:]]|$)/ /g; s/(^|[[:space:]])rootflag=[^[:space:]]+([[:space:]]|$)/ /g; s/[[:space:]]+/ /g' "$cfg"
}

'''

if "sanitize_generated_grub_cfg()" not in t and "$GRUB_MKCONFIG -o /boot/grub/grub.cfg" in t:
    t = t.replace('$GRUB_MKCONFIG -o /boot/grub/grub.cfg\n', '$GRUB_MKCONFIG -o /boot/grub/grub.cfg\nsanitize_generated_grub_cfg\n', 1)
    changed = True

if "sanitize_generated_grub_cfg()" not in t and "require_cmd \"$BLKID\"\n" in t:
    t = t.replace('require_cmd "$BLKID"\n', 'require_cmd "$BLKID"\n\n' + cfg_sanitize_fn, 1)
    changed = True

if changed:
    p.write_text(t, encoding="utf-8")
PY
        if ! grep -q 'sanitize_generated_grub_cfg' "${install_path}/scripts/configure-grub.sh"; then
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
        sed -i '/enable_service sddm/d' "${install_path}/scripts/enable-services.sh"
        sed -i '/enable_service greetd/d' "${install_path}/scripts/enable-services.sh"
        if ! grep -q 'enable_service sshd' "${install_path}/scripts/enable-services.sh"; then
            printf '\nenable_service sshd\n' >> "${install_path}/scripts/enable-services.sh"
        fi
        printf 'enable_service greetd\n' >> "${install_path}/scripts/enable-services.sh"
        if grep -q 'enable_service iwd' "${install_path}/scripts/enable-services.sh"; then
            echo "ERROR: Failed to remove iwd enable from installer services"
            return 1
        fi
        if grep -q 'enable_service sddm' "${install_path}/scripts/enable-services.sh"; then
            echo "ERROR: Failed to remove installer sddm enable"
            return 1
        fi
        if ! grep -q 'enable_service greetd' "${install_path}/scripts/enable-services.sh"; then
            echo "ERROR: Failed to enforce greetd enable in installer services"
            return 1
        fi
        if ! grep -q 'enable_service sshd' "${install_path}/scripts/enable-services.sh"; then
            echo "ERROR: Failed to enforce sshd enable in installer services"
            return 1
        fi
        echo "  → Removed installer iwd service enable"
        echo "  → Removed installer sddm service enable"
        echo "  → Enforced installer greetd service enable"
        echo "  → Enforced installer sshd service enable"
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

install_nuclear() {
    echo "Installing Nuclear music player..."

    echo "  → Fetching release info from GitHub API..."
    local release_json
    release_json=$(curl -fSL "https://api.github.com/repos/${NUCLEAR_GITHUB_REPO}/nuclear/releases/latest") || {
        echo "ERROR: Failed to fetch releases API (curl failed with $?)"
        return 1
    }

    if [[ -z "$release_json" ]]; then
        echo "ERROR: Empty response from GitHub API"
        return 1
    fi

    local release_tag appimage_url
    release_tag=$(printf '%s' "$release_json" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("tag_name", ""))')
    appimage_url=$(printf '%s' "$release_json" | python3 -c '
import sys, json
for a in json.load(sys.stdin).get("assets", []):
    if a.get("name", "").lower().endswith(".appimage"):
        print(a.get("browser_download_url", ""))
        break
')

    if [[ -z "$release_tag" || -z "$appimage_url" ]]; then
        echo "ERROR: Could not resolve Nuclear release (tag='${release_tag}', url='${appimage_url}')"
        return 1
    fi

    echo "  → Nuclear release: ${release_tag}"
    echo "  → AppImage: ${appimage_url}"

    local appimage_path="${BUILD_DIR}/nuclear.AppImage"
    local retries=5
    local count=0

    while [ $count -lt $retries ]; do
        echo "  → Downloading... (attempt $((count + 1))/$retries)"
        if curl -fSL -o "$appimage_path" "$appimage_url"; then
            echo "  → Download complete"
            break
        fi
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            echo "  → Retrying in 10 seconds..."
            sleep 10
        fi
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to download Nuclear after $retries attempts"
        return 1
    fi

    if [ ! -f "$appimage_path" ] || [ ! -s "$appimage_path" ]; then
        echo "ERROR: Downloaded file is missing or empty"
        return 1
    fi

    echo "  → File size: $(stat -c%s "$appimage_path" 2>/dev/null || echo 'unknown') bytes"

    mkdir -p "${NUCLEAR_INSTALL_DIR}"
    cp "$appimage_path" "${NUCLEAR_INSTALL_DIR}/nuclear.AppImage"
    chmod +x "${NUCLEAR_INSTALL_DIR}/nuclear.AppImage"

    cat > "${NUCLEAR_BIN}" << 'NUCLEAR_WRAPPER'
#!/bin/bash
exec /opt/nuclear/nuclear.AppImage "$@"
NUCLEAR_WRAPPER
    chmod +x "${NUCLEAR_BIN}"

    cat > /usr/share/applications/nuclear.desktop << 'NUCLEAR_DESKTOP'
[Desktop Entry]
Name=Nuclear Music Player
GenericName=Music Player
Comment=Free, open-source music player without ads or tracking
Exec=nuclear %U
Icon=nuclear
Terminal=false
Type=Application
Categories=Audio;Music;Player;AudioVideo;
MimeType=application/ogg;audio/flac;audio/mp3;audio/mpeg;audio/mpegurl;audio/mp4;audio/ogg;audio/vorbis;audio/wav;audio/x-flac;audio/x-mp3;audio/x-mpeg;audio/x-mpegurl;audio/x-ms-wma;audio/x-ogg;audio/x-vorbis;audio/x-wav;x-scheme-handler/nuclear;
Keywords=music;player;audio;streaming;mp3;flac;ogg;
NUCLEAR_DESKTOP

    mkdir -p /etc/skel/.local/share/applications
    cp /usr/share/applications/nuclear.desktop /etc/skel/.local/share/applications/

    echo "✓ Nuclear ${release_tag} installed to ${NUCLEAR_INSTALL_DIR}"
    return 0
}

restrict_wallpaper_desktop_to_sway() {
    local desktop
    local desktop_files=(
        "/usr/share/applications/mados-wallpaper.desktop"
        "/usr/share/applications/mados-wallpaper-picker.desktop"
        "/usr/share/applications/skwd-wall.desktop"
    )

    for desktop in "${desktop_files[@]}"; do
        [[ -f "$desktop" ]] || continue

        if grep -q '^OnlyShowIn=' "$desktop"; then
            sed -i 's/^OnlyShowIn=.*/OnlyShowIn=Sway;/' "$desktop"
        elif grep -q '^\[Desktop Entry\]' "$desktop"; then
            sed -i '/^\[Desktop Entry\]/a OnlyShowIn=Sway;' "$desktop"
        fi

        echo "  → Restricted $(basename "$desktop") to Sway"
    done
}

setup_music_assets() {
    if [[ ! -d /usr/share/music ]] || [[ -z "$(ls -A /usr/share/music 2>/dev/null)" ]]; then
        return 0
    fi

    mkdir -p /etc/skel/Music /home/mados/Music

    for f in /usr/share/music/*; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        if [[ ! -e "/etc/skel/Music/$base" ]]; then
            ln -s "$f" "/etc/skel/Music/$base"
        fi
        if [[ -d /home/mados && ! -e "/home/mados/Music/$base" ]]; then
            ln -s "$f" "/home/mados/Music/$base"
            chown -h 1000:1000 "/home/mados/Music/$base"
        fi
    done

    if [[ -d /home/mados ]]; then
        chown -R 1000:1000 /home/mados/Music
    fi

    echo "  → Music demo files linked to ~/Music"
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
    mkdir -p /usr/share/mados/wallpapers
    cp "$wallpaper_dir"/*.png /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.png /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /etc/skel/Pictures/Wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.png /usr/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpg /usr/share/mados/wallpapers/ 2>/dev/null || true
    cp "$wallpaper_dir"/*.jpeg /usr/share/mados/wallpapers/ 2>/dev/null || true
    
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

IMPERATIVE_DOTS_REPO="madkoding/theme-imperative-dots"
IMPERATIVE_DOTS_INSTALL_DIR="/usr/share/mados/themes/imperative-dots"

install_imperative_dots() {
    echo "Installing imperative-dots theme..."

    if [[ -d "$IMPERATIVE_DOTS_INSTALL_DIR" ]]; then
        if [[ -x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/start.sh" && -x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/healthcheck.sh" ]]; then
            echo "  → imperative-dots already installed, skipping"
            return 0
        fi

        echo "  → Found incomplete imperative-dots install, reinstalling"
        rm -rf "$IMPERATIVE_DOTS_INSTALL_DIR"
    fi

    local build_dir="${BUILD_DIR}/imperative-dots_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$BUILD_DIR"

    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --branch main --no-tags "https://github.com/${IMPERATIVE_DOTS_REPO}.git" "${build_dir}/imperative-dots"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone imperative-dots after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi

    mkdir -p "$(dirname "$IMPERATIVE_DOTS_INSTALL_DIR")"
    mv "${build_dir}/imperative-dots" "$IMPERATIVE_DOTS_INSTALL_DIR"
    rm -rf "$build_dir"

    chmod +x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/start.sh"
    chmod +x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/healthcheck.sh"
    find "${IMPERATIVE_DOTS_INSTALL_DIR}/config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} +

    echo "✓ imperative-dots installed to ${IMPERATIVE_DOTS_INSTALL_DIR}"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_imperative_dots
    install_mados_apps
    setup_music_assets
    setup_wallpaper_assets
    restrict_wallpaper_desktop_to_sway
    install_installer
    install_updater
    install_oh_my_zsh
    install_nuclear
fi
