#!/usr/bin/env bash
# 04-sddm-qylock.sh - Install SDDM with Qylock themes (build time)
set -euo pipefail

QYLOCK_REPO="https://github.com/DarkKal44/qylock"
QYLOCK_DIR="/root/build_tmp/qylock"
SYSTEM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="${SDDM_CONF_DIR}/theme.conf"
SELECTED_THEME="pixel-night-city"

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

    echo "  → Copied theme to ${SYSTEM_THEMES_DIR}/${SELECTED_THEME}"
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

    echo "  → Created ${SDDM_CONF}"
    return 0
}

prepare_quickshell_lockscreen() {
    echo "Preparing Quickshell lockscreen for post-install..."

    if [ ! -d "$QYLOCK_DIR/quickshell-lockscreen" ]; then
        echo "WARNING: quickshell-lockscreen not found in Qylock repository"
        return 0
    fi

    cp -r "$QYLOCK_DIR/quickshell-lockscreen" "/root/quickshell-lockscreen"
    chmod +x "/root/quickshell-lockscreen/lock.sh"

    cp -r "$QYLOCK_DIR/themes" "/root/qylock-themes"

    echo "  → Quickshell lockscreen prepared at /root/quickshell-lockscreen"
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    clone_qylock
    install_sddm_theme
    install_theme_fonts
    configure_sddm
    prepare_quickshell_lockscreen
fi