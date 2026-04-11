#!/usr/bin/env bash
# 04-sddm-qylock.sh - Install SDDM with Qylock themes (build time)
set -euo pipefail

QYLOCK_REPO="https://github.com/DarkKal44/qylock"
QYLOCK_DIR="/root/build_tmp/qylock"
QYLOCK_SHARE_DIR="/usr/local/share/qylock"
SYSTEM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="${SDDM_CONF_DIR}/theme.conf"
SDDM_AUTOLOGIN_CONF="${SDDM_CONF_DIR}/autologin-live.conf"
SELECTED_THEME="pixel-night-city"
DISTRO_FONT="Michroma"

mkdir -p "$SDDM_CONF_DIR"

clone_qylock() {
    echo "Cloning Qylock repository..."

    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --branch main --no-tags "$QYLOCK_REPO" "$QYLOCK_DIR"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone Qylock after $retries attempts"
        return 1
    fi

    return 0
}

install_sddm_theme() {
    echo "Installing SDDM theme: ${SELECTED_THEME}..."

    if [ ! -d "$QYLOCK_DIR/themes/${SELECTED_THEME}" ]; then
        echo "ERROR: Theme '${SELECTED_THEME}' not found in Qylock repository"
        return 1
    fi

    mkdir -p "$SYSTEM_THEMES_DIR"
    rm -rf "${SYSTEM_THEMES_DIR}/${SELECTED_THEME}"
    cp -r "$QYLOCK_DIR/themes/${SELECTED_THEME}" "${SYSTEM_THEMES_DIR}/"

    local theme_dir="${SYSTEM_THEMES_DIR}/${SELECTED_THEME}"
    python3 - "$theme_dir" <<'PY'
from pathlib import Path
import sys

theme_dir = Path(sys.argv[1])
replacements = {
    "Connectiong...": "Enter password...",
    "Connecting...": "Enter password...",
    "CONNECTING...": "Enter password...",
    "Password...": "Enter password...",
}

updated_files = []
for qml in theme_dir.rglob("*.qml"):
    text = qml.read_text(encoding="utf-8", errors="ignore")
    new_text = text
    for old, new in replacements.items():
        new_text = new_text.replace(old, new)
    if new_text != text:
        qml.write_text(new_text, encoding="utf-8")
        updated_files.append(str(qml.name))

if updated_files:
    print("  → Updated password prompt text in:", ", ".join(sorted(set(updated_files))))
else:
    print("  → Password prompt text did not need changes")
PY

    echo "  → Copied theme to ${SYSTEM_THEMES_DIR}/${SELECTED_THEME}"
    return 0
}

enforce_theme_font() {
    local theme_dir="${SYSTEM_THEMES_DIR}/${SELECTED_THEME}"

    if [ ! -d "$theme_dir" ]; then
        echo "ERROR: Theme directory not found for font replacement: $theme_dir"
        return 1
    fi

    python3 - "$theme_dir" "$DISTRO_FONT" <<'PY'
from pathlib import Path
import re
import sys

theme_dir = Path(sys.argv[1])
font_name = sys.argv[2]

patterns = [
    # QML/Qt style
    (re.compile(r'font\\.family\\s*:\\s*"[^"]*"'), f'font.family: "{font_name}"'),
    (re.compile(r"font\\.family\\s*:\\s*'[^']*'"), f'font.family: "{font_name}"'),
    (re.compile(r'font\\.family\\s*:\\s*[A-Za-z_][A-Za-z0-9_]*\\.name'), f'font.family: "{font_name}"'),
    (re.compile(r'fontFamily\\s*:\\s*"[^"]*"'), f'fontFamily: "{font_name}"'),
    (re.compile(r"fontFamily\\s*:\\s*'[^']*'"), f'fontFamily: "{font_name}"'),

    # INI/desktop-like keys occasionally used by themes
    (re.compile(r'^\\s*Font\\s*=\\s*.+$', re.MULTILINE), f'Font={font_name}'),

    # CSS/SVG snippets embedded in theme assets
    (re.compile(r'font-family\\s*:\\s*[^;\\n]+;'), f'font-family: "{font_name}";'),
]

changed_files = []
for file_path in list(theme_dir.rglob("*.qml")) + list(theme_dir.rglob("*.conf")) + list(theme_dir.rglob("*.ini")) + list(theme_dir.rglob("*.desktop")) + list(theme_dir.rglob("*.css")) + list(theme_dir.rglob("*.svg")):
    text = file_path.read_text(encoding="utf-8", errors="ignore")
    new_text = text
    for pattern, replacement in patterns:
        new_text = pattern.sub(replacement, new_text)
    if new_text != text:
        file_path.write_text(new_text, encoding="utf-8")
        changed_files.append(file_path.relative_to(theme_dir).as_posix())

if changed_files:
    print(f"  → Enforced distro font '{font_name}' in {len(changed_files)} files")
else:
    print(f"  → No explicit font declarations found; theme will use system default '{font_name}'")
PY

    return 0
}

configure_sddm() {
    echo "Configuring SDDM..."

    cat > "$SDDM_CONF" << EOF
[Theme]
Current=${SELECTED_THEME}

[General]
InputMethod=
EOF

    cat > "$SDDM_AUTOLOGIN_CONF" << 'EOF'
[Autologin]
User=mados
Session=mados-auto.desktop
EOF

    mkdir -p /etc/systemd/system
    ln -sf /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service

    echo "  → Created ${SDDM_CONF}"
    echo "  → Created ${SDDM_AUTOLOGIN_CONF}"
    return 0
}

prepare_quickshell_lockscreen() {
    echo "Preparing Quickshell lockscreen for post-install..."

    if [ ! -d "$QYLOCK_DIR/quickshell-lockscreen" ]; then
        echo "WARNING: quickshell-lockscreen not found in Qylock repository"
        return 0
    fi

    mkdir -p "$QYLOCK_SHARE_DIR"
    rm -rf "$QYLOCK_SHARE_DIR/quickshell-lockscreen" "$QYLOCK_SHARE_DIR/themes"

    cp -r "$QYLOCK_DIR/quickshell-lockscreen" "$QYLOCK_SHARE_DIR/quickshell-lockscreen"
    chmod +x "$QYLOCK_SHARE_DIR/quickshell-lockscreen/lock.sh"

    cp -r "$QYLOCK_DIR/themes" "$QYLOCK_SHARE_DIR/themes"

    echo "  → Quickshell lockscreen prepared at ${QYLOCK_SHARE_DIR}/quickshell-lockscreen"
    return 0
}

install_theme_fonts() {
    local theme_fonts_dir="${SYSTEM_THEMES_DIR}/${SELECTED_THEME}/font"
    local font_install_dir="/usr/share/fonts/${SELECTED_THEME}"

    if [ ! -d "$theme_fonts_dir" ]; then
        return 0
    fi

    mkdir -p "$font_install_dir"
    cp "$theme_fonts_dir"/*.{ttf,otf} "$font_install_dir/" 2>/dev/null || true

    echo "  → Installed theme fonts"
    return 0
}

install_sddm_qylock() {
    clone_qylock
    install_sddm_theme
    enforce_theme_font
    install_theme_fonts
    configure_sddm
    prepare_quickshell_lockscreen
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_sddm_qylock
fi
