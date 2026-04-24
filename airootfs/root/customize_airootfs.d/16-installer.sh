#!/usr/bin/env bash
# 16-installer.sh - Install mados-installer
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

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

    if [[ -f "${install_path}/scripts/setup-plymouth.sh" ]]; then
        sed -i 's/logo.image = Image("logo.png");/logo.image = Image("logo.png");\nlogo.image = logo.image.Scale(250, 250);/' "${install_path}/scripts/setup-plymouth.sh"
        if ! grep -q 'logo.image = logo.image.Scale(250, 250);' "${install_path}/scripts/setup-plymouth.sh"; then
            echo "ERROR: Failed to enforce Plymouth logo scale"
            return 1
        fi
        echo "  → Synced installer Plymouth logo scale with live ISO"
    fi

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
rm -f /etc/sddm.conf.d/90-disable-autologin.conf
systemctl enable mados-sddm-env.service
EOSDDM
        fi
        echo "  → Removed installer iwd backend override line"
    fi

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

sanitize_calls = '''sanitize_grub_cmdline_key "GRUB_CMDLINE_LINUX"
sanitize_grub_cmdline_key "GRUB_CMDLINE_LINUX_DEFAULT"
'''

if "sanitize_grub_cmdline_key \"GRUB_CMDLINE_LINUX\"" not in t and "ensure_btrfs_rootflags" in t:
    t = t.replace('ensure_btrfs_rootflags\n', 'ensure_btrfs_rootflags\n' + sanitize_calls, 1)
    changed = True

if 'ensure_btrfs_rootflags\n' in t:
    t = t.replace('ensure_btrfs_rootflags\n', '', 1)
    changed = True

if "ensure_btrfs_rootflags()" in t:
    start = t.find("ensure_btrfs_rootflags() {")
    if start != -1:
        end = t.find("\n}\n", start)
        if end != -1:
            t = t[:start] + t[end + 3 :]
            changed = True

if 'ensure_cmdline_token "splash"\n' in t:
    t = t.replace('ensure_cmdline_token "splash"\n', '', 1)
    changed = True

if 'ensure_cmdline_token "quiet"\n' in t:
    t = t.replace('ensure_cmdline_token "quiet"\n', '', 1)
    changed = True

cfg_sanitize_fn = '''sanitize_generated_grub_cfg() {
    local cfg="/boot/grub/grub.cfg"
    [[ -f "$cfg" ]] || return 0

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

    cat > "$bin_path" << 'INSTALLER_WRAPPER'
#!/bin/bash
INSTALL_DIR="/opt/mados"
INSTALL_PATH="/opt/mados/mados_installer"
LOG_FILE="/var/log/mados-installer.log"

if [[ "$EUID" -ne 0 ]]; then
    exec sudo -E "$0" "$@"
fi

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
        sed -i 's|^Exec=.*|Exec=sudo /usr/local/bin/mados-installer|' "/usr/share/applications/${installer_name}.desktop"
        echo "  → Updated desktop Exec to run with sudo"
    fi

    echo "✓ ${installer_name} installed to ${install_path}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_installer
fi
