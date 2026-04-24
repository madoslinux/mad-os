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

strip_vcs_metadata() {
    local target_dir="$1"

    [[ -d "$target_dir" ]] || return 0

    rm -rf \
        "$target_dir/.git" \
        "$target_dir/.github" \
        "$target_dir/.gitignore" \
        "$target_dir/.gitattributes" \
        "$target_dir/.gitmodules"
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

    if ! grep -q 'Current=pixel-night-city' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh missing SDDM theme pin"
        return 1
    fi

    if grep -q 'systemctl enable getty@tty2.service' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh still enables getty@tty2"
        return 1
    fi

    if grep -q 'systemctl enable getty@tty1.service' "${install_path}/scripts/apply-configuration.sh"; then
        echo "ERROR: Installer contract check failed: apply-configuration.sh still enables getty@tty1 fallback"
        return 1
    fi

    if ! grep -q '"linux-lts"' "${install_path}/installer/steps.py"; then
        echo "ERROR: Installer contract check failed: steps.py missing linux-lts kernel fallback"
        return 1
    fi

    if ! grep -q 'supported kernel not found' "${install_path}/installer/steps.py"; then
        echo "ERROR: Installer contract check failed: steps.py missing generic supported-kernel error path"
        return 1
    fi

    if ! grep -q 'for candidate in linux-lts linux-mados linux linux-zen' "${install_path}/scripts/configure-grub.sh"; then
        echo "ERROR: Installer contract check failed: configure-grub.sh missing kernel fallback candidate detection"
        return 1
    fi

    if ! grep -q 'for candidate in linux-lts linux-mados linux linux-zen' "${install_path}/scripts/rebuild-initramfs.sh"; then
        echo "ERROR: Installer contract check failed: rebuild-initramfs.sh missing kernel fallback candidate detection"
        return 1
    fi

    if ! grep -q '/boot/vmlinuz-linux-lts' "${install_path}/scripts/setup-bootloader.sh"; then
        echo "ERROR: Installer contract check failed: setup-bootloader.sh missing linux-lts signing/validation fallback"
        return 1
    fi

    if ! grep -q 'KERNEL_NAME=""' "${install_path}/scripts/configure-limine.sh"; then
        echo "ERROR: Installer contract check failed: configure-limine.sh missing dynamic kernel detection"
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
    strip_vcs_metadata "$install_path"
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
    strip_vcs_metadata "$install_path"
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
    echo "  ⚠ Some graphical components are missing. Keeping SDDM as primary login path."
fi
'''

if old in t:
    t = t.replace(old, new, 1)
    p.write_text(t, encoding="utf-8")
PY

        if ! grep -q 'madOS: disable live SDDM autologin' "${install_path}/scripts/apply-configuration.sh"; then
            cat >> "${install_path}/scripts/apply-configuration.sh" << 'EOSDDM'

# madOS: preserve SDDM theme and disable live autologin on installed systems
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-mados-theme.conf << 'EOF'
[Theme]
Current=pixel-night-city
EOF
if [ -f /etc/sddm.conf ]; then
    sed -i 's/^Current=.*/Current=pixel-night-city/' /etc/sddm.conf
fi
rm -f /etc/sddm.conf.d/autologin-live.conf
# Do not write an empty [Autologin] block; defaults already keep autologin disabled.
rm -f /etc/sddm.conf.d/90-disable-autologin.conf
EOSDDM
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

    if [[ -f "${install_path}/installer/steps.py" ]]; then
        python3 - "${install_path}/installer/steps.py" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

if "supported kernel not found" not in t:
    new_func = '''def _ensure_kernel_in_target(app):
    """Ensure a supported kernel image exists in target /boot before entering the chroot."""
    os.makedirs("/mnt/boot", exist_ok=True)

    preferred_kernels = [
        "linux-lts",
        "linux-mados",
        "linux",
        "linux-zen",
    ]

    def _target_path(kernel_name):
        return f"/mnt/boot/vmlinuz-{kernel_name}"

    def _copy_kernel(src, kernel_name):
        target = _target_path(kernel_name)
        subprocess.run(["cp", src, target], check=True)
        log_message(app, f"  Copied kernel from {src} -> {target}")

    def _detect_kernel_name_from_module_path(path):
        mod_ver = os.path.basename(os.path.dirname(path)).lower()
        if "lts" in mod_ver:
            return "linux-lts"
        if "mados" in mod_ver:
            return "linux-mados"
        if "zen" in mod_ver:
            return "linux-zen"
        return "linux"

    log_message(app, "  DEBUG: Checking archiso bootmnt kernel paths:")
    for f in sorted(globmod.glob("/run/archiso/bootmnt/arch/boot/x86_64/vmlinuz*")):
        log_message(app, f"    {f}")
    log_message(app, "  DEBUG: Checking live system /boot:")
    for f in sorted(globmod.glob("/boot/vmlinuz*")):
        log_message(app, f"    {f}")
    log_message(app, "  DEBUG: Checking live system /lib/modules:")
    for d in sorted(globmod.glob("/lib/modules/*")):
        log_message(app, f"    {d}")
    log_message(app, "  DEBUG: Checking /usr/lib/modules/*/vmlinuz:")
    for f in sorted(globmod.glob("/usr/lib/modules/*/vmlinuz")):
        log_message(app, f"    {f}")
    log_message(app, "  DEBUG: Checking /lib/modules/*/vmlinuz:")
    for f in sorted(globmod.glob("/lib/modules/*/vmlinuz")):
        log_message(app, f"    {f}")

    for kernel_name in preferred_kernels:
        target = _target_path(kernel_name)
        if os.path.isfile(target) and os.access(target, os.R_OK) and os.path.getsize(target) > 0:
            log_message(app, f"  Kernel already exists in target /boot: {target}")
            return

    log_message(app, "  Kernel not found in target /boot, copying from live system...")

    for kernel_name in preferred_kernels:
        for src in (
            f"/run/archiso/bootmnt/arch/boot/x86_64/vmlinuz-{kernel_name}",
            f"/boot/vmlinuz-{kernel_name}",
        ):
            if os.path.isfile(src) and os.access(src, os.R_OK):
                _copy_kernel(src, kernel_name)
                return

    for search_glob in (
        "/usr/lib/modules/*/vmlinuz",
        "/lib/modules/*/vmlinuz",
        "/mnt/usr/lib/modules/*/vmlinuz",
    ):
        for vmlinuz in sorted(globmod.glob(search_glob), reverse=True):
            if os.path.isfile(vmlinuz) and os.access(vmlinuz, os.R_OK):
                kernel_name = _detect_kernel_name_from_module_path(vmlinuz)
                _copy_kernel(vmlinuz, kernel_name)
                return

    log_message(
        app,
        "  ERROR: Could not find supported kernel (linux-lts/linux-mados/linux/linux-zen) in live system",
    )
    raise RuntimeError("supported kernel not found")
'''

    pattern = re.compile(r"def _ensure_kernel_in_target\(app\):.*?\n\ndef step_partition_disk", re.S)
    if pattern.search(t):
        t = pattern.sub(new_func + "\n\ndef step_partition_disk", t, count=1)
        p.write_text(t, encoding="utf-8")
PY
        if ! grep -q 'supported kernel not found' "${install_path}/installer/steps.py"; then
            echo "ERROR: Failed to add installer kernel fallback support"
            return 1
        fi
        echo "  → Added linux-lts fallback to installer kernel copy step"
    fi

    if [[ -f "${install_path}/scripts/configure-grub.sh" ]]; then
        python3 - "${install_path}/scripts/configure-grub.sh" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

old = '''KERNEL="linux-mados"

if [ ! -f /boot/vmlinuz-${KERNEL} ]; then
    echo "ERROR: No madOS kernel found in /boot"
    exit 1
fi

mkdir -p /etc/default
[ -f /etc/default/grub ] || touch /etc/default/grub

mkdir -p /etc/mados
echo "$KERNEL" > /etc/mados/default-kernel
echo "  Selected default kernel: $KERNEL"
'''

new = '''KERNEL=""
for candidate in linux-lts linux-mados linux linux-zen; do
    if [ -f "/boot/vmlinuz-${candidate}" ]; then
        KERNEL="${candidate}"
        break
    fi
done

if [ -z "$KERNEL" ]; then
    echo "ERROR: No supported kernel found in /boot"
    exit 1
fi

mkdir -p /etc/default
[ -f /etc/default/grub ] || touch /etc/default/grub

mkdir -p /etc/mados
echo "$KERNEL" > /etc/mados/default-kernel
echo "  Selected default kernel: $KERNEL"
'''

changed = False
if "for candidate in linux-lts linux-mados linux linux-zen" not in t and old in t:
    t = t.replace(old, new, 1)
    changed = True

if 'if ! grep -q "vmlinuz-linux-mados" /boot/grub/grub.cfg; then' in t:
    t = t.replace(
        'if ! grep -q "vmlinuz-linux-mados" /boot/grub/grub.cfg; then',
        'if ! grep -q "vmlinuz-${KERNEL}" /boot/grub/grub.cfg; then',
        1,
    )
    changed = True

if 'echo "ERROR: grub.cfg does not contain linux-mados entry"' in t:
    t = t.replace(
        'echo "ERROR: grub.cfg does not contain linux-mados entry"',
        'echo "ERROR: grub.cfg does not contain vmlinuz-${KERNEL} entry"',
        1,
    )
    changed = True

if changed:
    p.write_text(t, encoding="utf-8")
PY
        if ! grep -q 'for candidate in linux-lts linux-mados linux linux-zen' "${install_path}/scripts/configure-grub.sh"; then
            echo "ERROR: Failed to add kernel fallback detection to configure-grub.sh"
            return 1
        fi
        echo "  → Added linux-lts fallback to installer GRUB configuration"
    fi

    if [[ -f "${install_path}/scripts/rebuild-initramfs.sh" ]]; then
        python3 - "${install_path}/scripts/rebuild-initramfs.sh" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

old_kernel_select = '''KERNEL="linux-mados"
if [ ! -s /boot/vmlinuz-${KERNEL} ] || [ ! -r /boot/vmlinuz-${KERNEL} ]; then
    echo "  ERROR: Could not find kernel image. Reinstalling ${KERNEL} package..."
    $PACMAN -Sy --noconfirm ${KERNEL} || { echo "FATAL: Failed to install kernel"; exit 1; }
fi
'''

new_kernel_select = '''KERNEL=""
for candidate in linux-lts linux-mados linux linux-zen; do
    if [ -s "/boot/vmlinuz-${candidate}" ] && [ -r "/boot/vmlinuz-${candidate}" ]; then
        KERNEL="${candidate}"
        break
    fi
done

if [ -z "$KERNEL" ]; then
    KERNEL="linux-lts"
    echo "  WARNING: Could not find kernel image in /boot. Installing ${KERNEL} package..."
    $PACMAN -Sy --noconfirm ${KERNEL} || { echo "FATAL: Failed to install kernel"; exit 1; }
fi

if [ ! -s "/boot/vmlinuz-${KERNEL}" ] || [ ! -r "/boot/vmlinuz-${KERNEL}" ]; then
    echo "  ERROR: Could not find readable kernel image: /boot/vmlinuz-${KERNEL}"
    exit 1
fi
'''

old_modules_detect = '''TARGET_KVER=""
for kver in /lib/modules/*/; do
    kver_name=$($BASENAME "$kver")
    if [[ "$kver_name" == *"mados"* ]]; then
        TARGET_KVER="$kver_name"
        echo "  Found target kernel: $TARGET_KVER"
        break
    fi
done

if [ -z "$TARGET_KVER" ]; then
    echo "  ERROR: No madOS kernel modules found in /lib/modules"
    echo "  Available kernels:"
    $LS /lib/modules/ 2>/dev/null || echo "  (none)"
    exit 1
fi
'''

new_modules_detect = '''TARGET_KVER=""
for kver in /lib/modules/*/; do
    kver_name=$($BASENAME "$kver")
    case "$KERNEL" in
        linux-lts)
            [[ "$kver_name" == *"lts"* ]] || continue
            ;;
        linux-mados)
            [[ "$kver_name" == *"mados"* ]] || continue
            ;;
        linux-zen)
            [[ "$kver_name" == *"zen"* ]] || continue
            ;;
        linux)
            [[ "$kver_name" == *"arch"* || "$kver_name" == *"linux"* ]] || continue
            ;;
    esac
    TARGET_KVER="$kver_name"
    echo "  Found target kernel: $TARGET_KVER"
    break
done

if [ -z "$TARGET_KVER" ]; then
    echo "  WARNING: No matching kernel modules found for ${KERNEL}; using first available module tree"
    for kver in /lib/modules/*/; do
        TARGET_KVER=$($BASENAME "$kver")
        break
    done
fi

if [ -z "$TARGET_KVER" ]; then
    echo "  ERROR: No kernel modules found in /lib/modules"
    echo "  Available kernels:"
    $LS /lib/modules/ 2>/dev/null || echo "  (none)"
    exit 1
fi
'''

changed = False
if "for candidate in linux-lts linux-mados linux linux-zen" not in t and old_kernel_select in t:
    t = t.replace(old_kernel_select, new_kernel_select, 1)
    changed = True

if old_modules_detect in t:
    t = t.replace(old_modules_detect, new_modules_detect, 1)
    changed = True

if changed:
    p.write_text(t, encoding="utf-8")
PY
        if ! grep -q 'for candidate in linux-lts linux-mados linux linux-zen' "${install_path}/scripts/rebuild-initramfs.sh"; then
            echo "ERROR: Failed to add kernel fallback detection to rebuild-initramfs.sh"
            return 1
        fi
        echo "  → Added linux-lts fallback to installer initramfs rebuild"
    fi

    if [[ -f "${install_path}/scripts/setup-bootloader.sh" ]]; then
        python3 - "${install_path}/scripts/setup-bootloader.sh" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

old_sign_loop = '''    for path in \
        /boot/EFI/BOOT/BOOTX64.EFI \
        /boot/EFI/BOOT/grubx64.efi \
        /boot/EFI/madOS/grubx64.efi \
        /boot/vmlinuz-linux-mados; do
        if [ -f "$path" ]; then
            artifacts+=("$path")
        fi
    done
'''

new_sign_loop = '''    for path in \
        /boot/EFI/BOOT/BOOTX64.EFI \
        /boot/EFI/BOOT/grubx64.efi \
        /boot/EFI/madOS/grubx64.efi; do
        if [ -f "$path" ]; then
            artifacts+=("$path")
        fi
    done

    for path in \
        /boot/vmlinuz-linux-lts \
        /boot/vmlinuz-linux-mados \
        /boot/vmlinuz-linux \
        /boot/vmlinuz-linux-zen; do
        if [ -f "$path" ]; then
            artifacts+=("$path")
        fi
    done
'''

new_validate_fn = '''validate_boot_artifacts() {
    local required_paths=(
        "/boot/EFI/BOOT/BOOTX64.EFI"
        "/boot/EFI/madOS/grubx64.efi"
    )

    local path
    for path in "${required_paths[@]}"; do
        if [ ! -s "$path" ]; then
            echo "ERROR: Required boot artifact missing: $path"
            exit 1
        fi
    done

    local kernel_found=0
    local kernel_path
    for kernel_path in \
        /boot/vmlinuz-linux-lts \
        /boot/vmlinuz-linux-mados \
        /boot/vmlinuz-linux \
        /boot/vmlinuz-linux-zen; do
        if [ -s "$kernel_path" ]; then
            kernel_found=1
            break
        fi
    done

    if [ "$kernel_found" -ne 1 ]; then
        echo "ERROR: Required kernel artifact missing: expected one of /boot/vmlinuz-linux-lts|linux-mados|linux|linux-zen"
        exit 1
    fi
}
'''

changed = False
if old_sign_loop in t:
    t = t.replace(old_sign_loop, new_sign_loop, 1)
    changed = True

validate_pattern = re.compile(r"validate_boot_artifacts\(\) \{.*?\n\}\n\nrequire_cmd", re.S)
if validate_pattern.search(t):
    t = validate_pattern.sub(new_validate_fn + "\nrequire_cmd", t, count=1)
    changed = True

if changed:
    p.write_text(t, encoding="utf-8")
PY
        if ! grep -q '/boot/vmlinuz-linux-lts' "${install_path}/scripts/setup-bootloader.sh"; then
            echo "ERROR: Failed to add linux-lts boot artifact fallback to setup-bootloader.sh"
            return 1
        fi
        echo "  → Added linux-lts fallback to installer bootloader setup"
    fi

    if [[ -f "${install_path}/scripts/configure-limine.sh" ]]; then
        python3 - "${install_path}/scripts/configure-limine.sh" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")

if 'KERNEL_NAME=""' not in t:
    marker = "mkdir -p /boot/EFI/BOOT\n\n"
    insert = '''KERNEL_NAME=""
for candidate in linux-lts linux-mados linux linux-zen; do
    if [ -f "/boot/vmlinuz-${candidate}" ] && [ -f "/boot/initramfs-${candidate}.img" ]; then
        KERNEL_NAME="${candidate}"
        break
    fi
done

if [ -z "$KERNEL_NAME" ]; then
    echo "ERROR: No supported kernel/initramfs pair found in /boot"
    exit 1
fi

'''
    if marker in t:
        t = t.replace(marker, marker + insert, 1)

    t = t.replace("path: boot():/vmlinuz-linux-mados-zen", "path: boot():/vmlinuz-${KERNEL_NAME}")
    t = t.replace(
        "module_path: boot():/initramfs-linux-mados-zen.img",
        "module_path: boot():/initramfs-${KERNEL_NAME}.img",
    )
    p.write_text(t, encoding="utf-8")
PY
        if ! grep -q 'KERNEL_NAME=""' "${install_path}/scripts/configure-limine.sh"; then
            echo "ERROR: Failed to add dynamic kernel detection to configure-limine.sh"
            return 1
        fi
        echo "  → Added linux-lts fallback to installer Limine configuration"
    fi

    if [[ -f "${install_path}/scripts/enable-services.sh" ]]; then
        sed -i '/enable_service iwd/d' "${install_path}/scripts/enable-services.sh"
        if ! grep -q 'enable_service sshd' "${install_path}/scripts/enable-services.sh"; then
            printf '\nenable_service sshd\n' >> "${install_path}/scripts/enable-services.sh"
        fi
        if grep -q 'enable_service iwd' "${install_path}/scripts/enable-services.sh"; then
            echo "ERROR: Failed to remove iwd enable from installer services"
            return 1
        fi
        if ! grep -q 'enable_service sshd' "${install_path}/scripts/enable-services.sh"; then
            echo "ERROR: Failed to enforce sshd enable in installer services"
            return 1
        fi
        echo "  → Removed installer iwd service enable"
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
    strip_vcs_metadata "$omz_dir"
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

SKWD_WALL_REPO="madkoding/skwd-wall"
SKWD_WALL_INSTALL_DIR="/usr/local/share/skwd-wall"
SKWD_WALL_COMPAT_DIR="/opt/mados/skwd-wall"
SKWD_WALL_BIN="/usr/local/bin/skwd-wall"

install_skwd_wall_legacy() {
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

    mkdir -p "$INSTALL_DIR" "/usr/local/share" "/opt/mados"
    rm -rf "$SKWD_WALL_INSTALL_DIR"
    mv "${build_dir}/skwd-wall" "$SKWD_WALL_INSTALL_DIR"
    strip_vcs_metadata "$SKWD_WALL_INSTALL_DIR"

    rm -rf "$SKWD_WALL_COMPAT_DIR"
    ln -s "$SKWD_WALL_INSTALL_DIR" "$SKWD_WALL_COMPAT_DIR"

    mkdir -p /etc/skel/.config/skwd-wall /etc/skel/.config/systemd/user

    cat > /etc/skel/.config/systemd/user/skwd-wall.service << 'SKWD_WALL_SERVICE'
[Unit]
Description=skwd-wall wallpaper selector daemon
Documentation=https://github.com/madkoding/skwd-wall
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mados-skwd-wall-daemon
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
SKWD_WALL_SERVICE

    if [[ -f "$SKWD_WALL_INSTALL_DIR/data/config.json.example" ]]; then
        cp "$SKWD_WALL_INSTALL_DIR/data/config.json.example" /etc/skel/.config/skwd-wall/config.json
    fi

    if [[ -f /etc/skel/.config/skwd-wall/config.json ]]; then
        sed -i 's/"compositor":[[:space:]]*"[^"]*"/"compositor": "hyprland"/' /etc/skel/.config/skwd-wall/config.json
    fi

    if [[ -d /home/mados ]]; then
        mkdir -p /home/mados/.config/skwd-wall /home/mados/.config/systemd/user
        cp /etc/skel/.config/systemd/user/skwd-wall.service /home/mados/.config/systemd/user/skwd-wall.service

        if [[ -f /etc/skel/.config/skwd-wall/config.json ]]; then
            cp /etc/skel/.config/skwd-wall/config.json /home/mados/.config/skwd-wall/config.json
        fi

        chown -R 1000:1000 /home/mados/.config/skwd-wall /home/mados/.config/systemd
    fi

    rm -rf "$build_dir"

    cat > "$SKWD_WALL_BIN" << 'SKWD_WALL_WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    exec /usr/local/bin/mados-wallpaper-picker toggle
fi

exec /usr/local/bin/mados-wallpaper-picker "$@"
SKWD_WALL_WRAPPER
    chmod +x "$SKWD_WALL_BIN"

    cat > /usr/local/bin/mados-skwd-wall-sources << 'MADOS_SKWD_WALL_SOURCES'
#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path

DEFAULT_SOURCES = [
    "~/.local/share/mados/wallpapers",
    "~/Pictures/Wallpapers",
    "/usr/share/backgrounds",
    "/usr/share/wallpapers",
    "/usr/share/mados/wallpapers",
    "/opt/mados/mados_wallpaper",
]

EXCLUDED_SOURCE_PATHS = [
    "/usr/share/backgrounds/sway",
]

IMAGE_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".gif",
    ".bmp",
    ".tif",
    ".tiff",
}

VIDEO_EXTENSIONS = {
    ".mp4",
    ".mkv",
    ".mov",
    ".webm",
    ".avi",
}


def home() -> Path:
    return Path.home()


def config_file() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME", str(home() / ".config"))
    return Path(xdg) / "skwd-wall" / "config.json"


def cache_root() -> Path:
    xdg = os.environ.get("XDG_CACHE_HOME", str(home() / ".cache"))
    return Path(xdg) / "skwd-wall"


def union_dir() -> Path:
    return cache_root() / "wallpaper-union"


def normalize(path: str) -> str:
    value = os.path.expandvars(path.strip())
    value = os.path.expanduser(value)
    return str(Path(value).resolve())


def ensure_config() -> dict:
    path = config_file()
    path.parent.mkdir(parents=True, exist_ok=True)

    if not path.is_file():
        install_dir = Path("/usr/local/share/skwd-wall")
        example = install_dir / "data" / "config.json.example"
        if example.is_file():
            data = json.loads(example.read_text())
        else:
            data = {}
    else:
        try:
            data = json.loads(path.read_text())
        except json.JSONDecodeError:
            data = {}

    if not isinstance(data, dict):
        data = {}

    paths = data.get("paths")
    if not isinstance(paths, dict):
        paths = {}
    data["paths"] = paths

    sources = paths.get("wallpaperSources")
    if not isinstance(sources, list):
        sources = []

    merged = []
    seen = set()

    legacy = paths.get("wallpaper")
    if isinstance(legacy, str) and legacy.strip():
        legacy_norm = normalize(legacy)
        if legacy_norm not in seen and not legacy_norm.endswith("/wallpaper-union"):
            merged.append(legacy_norm)
            seen.add(legacy_norm)

    for item in sources:
        if isinstance(item, str) and item.strip():
            norm = normalize(item)
            if norm not in seen:
                merged.append(norm)
                seen.add(norm)

    for item in DEFAULT_SOURCES:
        norm = normalize(item)
        if norm not in seen:
            merged.append(norm)
            seen.add(norm)

    paths["wallpaperSources"] = merged
    paths["wallpaper"] = str(union_dir())
    if not isinstance(paths.get("videoWallpaper"), str) or not str(paths["videoWallpaper"]).strip():
        paths["videoWallpaper"] = str(union_dir())

    data["compositor"] = "hyprland"
    save_config(data)
    return data


def save_config(data: dict) -> None:
    path = config_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")


def iter_files(source: Path):
    excluded_paths = [Path(item) for item in EXCLUDED_SOURCE_PATHS]
    for path in source.rglob("*"):
        if path.is_file():
            if any(path.is_relative_to(excluded) for excluded in excluded_paths):
                continue
            ext = path.suffix.lower()
            if ext in IMAGE_EXTENSIONS or ext in VIDEO_EXTENSIONS:
                yield path


def build_union_from_sources(sources: list[str]) -> None:
    target = union_dir()
    parent = target.parent
    temp = parent / (target.name + ".tmp")
    old = parent / (target.name + ".old")

    shutil.rmtree(temp, ignore_errors=True)
    temp.mkdir(parents=True, exist_ok=True)

    for src in sources:
        source = Path(src)
        if not source.is_dir():
            continue

        for item in iter_files(source):
            digest = hashlib.sha1(str(item).encode("utf-8")).hexdigest()[:10]
            stem = item.stem or "wallpaper"
            safe = "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in stem)[:80]
            name = f"{safe}__{digest}{item.suffix.lower()}"
            link = temp / name
            if not link.exists():
                try:
                    link.symlink_to(item)
                except OSError:
                    pass

    shutil.rmtree(old, ignore_errors=True)
    if target.exists() or target.is_symlink():
        target.rename(old)
    temp.rename(target)
    shutil.rmtree(old, ignore_errors=True)


def load_sources() -> list[str]:
    data = ensure_config()
    paths = data.get("paths", {})
    sources = paths.get("wallpaperSources", [])
    return [s for s in sources if isinstance(s, str)]


def cmd_sync() -> int:
    sources = load_sources()
    build_union_from_sources(sources)
    return 0


def cmd_list() -> int:
    for entry in load_sources():
        print(entry)
    return 0


def cmd_add(path: str) -> int:
    data = ensure_config()
    paths = data["paths"]
    sources = [s for s in paths.get("wallpaperSources", []) if isinstance(s, str)]
    norm = normalize(path)
    if norm not in sources:
        sources.append(norm)
        paths["wallpaperSources"] = sources
        save_config(data)
    build_union_from_sources(sources)
    return 0


def cmd_remove(path: str) -> int:
    data = ensure_config()
    paths = data["paths"]
    sources = [s for s in paths.get("wallpaperSources", []) if isinstance(s, str)]
    norm = normalize(path)
    sources = [s for s in sources if s != norm]
    paths["wallpaperSources"] = sources
    save_config(data)
    build_union_from_sources(sources)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage skwd-wall wallpaper sources")
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("sync")
    sub.add_parser("list")
    add_p = sub.add_parser("add")
    add_p.add_argument("path")
    rm_p = sub.add_parser("remove")
    rm_p.add_argument("path")

    args = parser.parse_args()
    if args.cmd in {None, "sync"}:
        return cmd_sync()
    if args.cmd == "list":
        return cmd_list()
    if args.cmd == "add":
        return cmd_add(args.path)
    if args.cmd == "remove":
        return cmd_remove(args.path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
MADOS_SKWD_WALL_SOURCES
    chmod +x /usr/local/bin/mados-skwd-wall-sources

    cat > /usr/local/bin/mados-skwd-wall-daemon << 'MADOS_SKWD_WALL_DAEMON'
#!/usr/bin/env bash
set -euo pipefail

export SKWD_WALL_INSTALL="/usr/local/share/skwd-wall"
export SKWD_WALL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/skwd-wall"

/usr/local/bin/mados-skwd-wall-sources sync >/dev/null 2>&1 || true

exec quickshell -p /usr/local/share/skwd-wall/daemon.qml
MADOS_SKWD_WALL_DAEMON
    chmod +x /usr/local/bin/mados-skwd-wall-daemon

    cat > /usr/local/bin/mados-skwd-wall-doctor << 'MADOS_SKWD_WALL_DOCTOR'
#!/usr/bin/env bash
set -euo pipefail

echo "== skwd-wall doctor =="

check_cmd() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "[ok] $cmd"
    else
        echo "[missing] $cmd"
    fi
}

check_cmd quickshell
check_cmd awww
check_cmd matugen
check_cmd ffmpeg
check_cmd magick
check_cmd sqlite3
check_cmd inotifywait

if [[ -f /usr/local/share/skwd-wall/daemon.qml ]]; then
    echo "[ok] daemon.qml"
else
    echo "[missing] /usr/local/share/skwd-wall/daemon.qml"
fi

if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/skwd-wall/config.json" ]]; then
    echo "[ok] config.json"
else
    echo "[missing] ~/.config/skwd-wall/config.json"
fi

echo "-- systemd user --"
systemctl --user is-enabled skwd-wall.service 2>/dev/null || true
systemctl --user is-active skwd-wall.service 2>/dev/null || true

echo "-- ipc --"
quickshell ipc -p /usr/local/share/skwd-wall/daemon.qml show 2>/dev/null || true

echo "-- recent logs --"
journalctl --user -u skwd-wall.service -n 40 --no-pager 2>/dev/null || true
MADOS_SKWD_WALL_DOCTOR
    chmod +x /usr/local/bin/mados-skwd-wall-doctor

    echo "✓ skwd-wall installed to ${SKWD_WALL_INSTALL_DIR}"
    return 0
}

# Canonical skwd-wall installer (overrides legacy wrapper-heavy flow)
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

    mkdir -p "$INSTALL_DIR" "/usr/local/share" "/opt/mados" /etc/skel/.config/skwd-wall /etc/skel/.config/systemd/user
    rm -rf "$SKWD_WALL_INSTALL_DIR"
    mv "${build_dir}/skwd-wall" "$SKWD_WALL_INSTALL_DIR"
    strip_vcs_metadata "$SKWD_WALL_INSTALL_DIR"

    rm -rf "$SKWD_WALL_COMPAT_DIR"
    ln -s "$SKWD_WALL_INSTALL_DIR" "$SKWD_WALL_COMPAT_DIR"

    if [[ ! -e "$SKWD_WALL_INSTALL_DIR/scripts" && -d "$SKWD_WALL_INSTALL_DIR/data/scripts" ]]; then
        ln -s "$SKWD_WALL_INSTALL_DIR/data/scripts" "$SKWD_WALL_INSTALL_DIR/scripts"
    fi

    if [[ -f "$SKWD_WALL_INSTALL_DIR/data/config.json.example" ]]; then
        cp "$SKWD_WALL_INSTALL_DIR/data/config.json.example" /etc/skel/.config/skwd-wall/config.json
        sed -i 's/"compositor":[[:space:]]*"[^"]*"/"compositor": "hyprland"/' /etc/skel/.config/skwd-wall/config.json
    fi

    if [[ ! -f /etc/skel/.config/systemd/user/skwd-wall.service ]]; then
        cat > /etc/skel/.config/systemd/user/skwd-wall.service << 'SKWD_WALL_SERVICE_FALLBACK'
[Unit]
Description=skwd-wall wallpaper selector daemon
Documentation=https://github.com/madkoding/skwd-wall
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mados-skwd-wall-daemon
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
SKWD_WALL_SERVICE_FALLBACK
    fi

    if [[ -d /home/mados ]]; then
        mkdir -p /home/mados/.config/skwd-wall /home/mados/.config/systemd/user
        if [[ -f /etc/skel/.config/skwd-wall/config.json ]]; then
            cp /etc/skel/.config/skwd-wall/config.json /home/mados/.config/skwd-wall/config.json
        fi
        if [[ -f /etc/skel/.config/systemd/user/skwd-wall.service ]]; then
            cp /etc/skel/.config/systemd/user/skwd-wall.service /home/mados/.config/systemd/user/skwd-wall.service
        fi
        chown -R 1000:1000 /home/mados/.config/skwd-wall /home/mados/.config/systemd
    fi

    for helper in /usr/local/bin/mados-wallpaper-picker /usr/local/bin/skwd-wall /usr/local/bin/mados-skwd-wall-daemon /usr/local/bin/mados-skwd-wall-sources /usr/local/bin/mados-skwd-wall-doctor; do
        if [[ -f "$helper" ]]; then
            chmod +x "$helper"
        fi
    done

    rm -rf "$build_dir"

    echo "✓ skwd-wall installed to ${SKWD_WALL_INSTALL_DIR}"
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

setup_wallpaper_assets() {
    local wallpaper_dir="${INSTALL_DIR}/mados_wallpaper"
    
    if [[ ! -d "$wallpaper_dir" ]]; then
        return 0
    fi
    
    if [[ -f "$wallpaper_dir/mados-wallpaper.svg" ]]; then
        mkdir -p /usr/share/icons/hicolor/scalable/apps
        cp "$wallpaper_dir/mados-wallpaper.svg" /usr/share/icons/hicolor/scalable/apps/
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
    strip_vcs_metadata "$IMPERATIVE_DOTS_INSTALL_DIR"
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
    setup_wallpaper_assets
    install_skwd_wall
    restrict_wallpaper_desktop_to_sway
    install_installer
    install_updater
    install_oh_my_zsh
fi
