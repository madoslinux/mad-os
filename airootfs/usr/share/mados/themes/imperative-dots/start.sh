#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="imperative-dots"
XDG_CONF_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME_ROOT="/usr/share/mados/themes/imperative-dots"

THEME_HYPR_SCRIPTS="${THEME_ROOT}/.config/hypr/scripts"
TARGET_HYPR_SCRIPTS="${XDG_CONF_HOME}/hypr/scripts"
THEME_MATUGEN="${THEME_ROOT}/.config/matugen"
TARGET_MATUGEN="${XDG_CONF_HOME}/matugen"
THEME_ROFI="${THEME_ROOT}/.config/rofi"
TARGET_ROFI="${XDG_CONF_HOME}/rofi"
THEME_SWAYNC="${THEME_ROOT}/.config/swaync"
TARGET_SWAYNC="${XDG_CONF_HOME}/swaync"
THEME_WOFI="${THEME_ROOT}/.config/wofi"
TARGET_WOFI="${XDG_CONF_HOME}/wofi"
THEME_KITTY="${THEME_ROOT}/.config/kitty"
TARGET_KITTY="${XDG_CONF_HOME}/kitty"

OWNERSHIP_MARKER="${XDG_CONF_HOME}/imperative-dots/managed-hypr-scripts"

log_info() {
    logger -p user.info -t "${LOG_TAG}" "$1"
}

log_warn() {
    logger -p user.warning -t "${LOG_TAG}" "$1"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_warn "Missing required command: $1"
        return 1
    fi
}

ensure_hyprland_session() {
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        log_warn "Not running under Hyprland session"
        return 1
    fi

    if ! hyprctl monitors >/dev/null 2>&1; then
        log_warn "Hyprland control socket is not available"
        return 1
    fi

    return 0
}

prepare_user_runtime() {
    mkdir -p "${XDG_CONF_HOME}/imperative-dots"

    if [[ -e "${TARGET_HYPR_SCRIPTS}" && ! -f "${OWNERSHIP_MARKER}" ]]; then
        log_warn "Refusing to override existing ${TARGET_HYPR_SCRIPTS}"
        return 1
    fi

    mkdir -p "${XDG_CONF_HOME}/hypr"
    rm -rf "${TARGET_HYPR_SCRIPTS}"
    cp -a "${THEME_HYPR_SCRIPTS}" "${TARGET_HYPR_SCRIPTS}"
    find "${TARGET_HYPR_SCRIPTS}" -type f -name "*.sh" -exec chmod +x {} +

    mkdir -p "${XDG_CONF_HOME}"
    rm -rf "${TARGET_MATUGEN}"
    cp -a "${THEME_MATUGEN}" "${TARGET_MATUGEN}"

    rm -rf "${TARGET_ROFI}"
    cp -a "${THEME_ROFI}" "${TARGET_ROFI}"

    rm -rf "${TARGET_WOFI}"
    mkdir -p "${TARGET_WOFI}"
    if [[ -f "${THEME_WOFI}/config" ]]; then
        cp -a "${THEME_WOFI}/config" "${TARGET_WOFI}/config"
    fi

    rm -rf "${TARGET_SWAYNC}"
    cp -a "${THEME_SWAYNC}" "${TARGET_SWAYNC}"

    rm -rf "${TARGET_KITTY}"
    cp -a "${THEME_KITTY}" "${TARGET_KITTY}"

    mkdir -p "${XDG_CONF_HOME}/gtk-3.0" "${XDG_CONF_HOME}/gtk-4.0" "${XDG_CONF_HOME}/qt5ct/colors" "${XDG_CONF_HOME}/qt6ct/colors" "${XDG_CONF_HOME}/mako"

    if [[ ! -f "${XDG_CONF_HOME}/qt5ct/qt5ct.conf" ]]; then
        cat > "${XDG_CONF_HOME}/qt5ct/qt5ct.conf" <<EOF
[Appearance]
color_scheme_path=${XDG_CONF_HOME}/qt5ct/colors/matugen.conf
custom_palette=true
standard_dialogs=default
style=Fusion
EOF
    fi

    if [[ ! -f "${XDG_CONF_HOME}/qt6ct/qt6ct.conf" ]]; then
        cat > "${XDG_CONF_HOME}/qt6ct/qt6ct.conf" <<EOF
[Appearance]
color_scheme_path=${XDG_CONF_HOME}/qt6ct/colors/matugen.conf
custom_palette=true
standard_dialogs=default
style=Fusion
EOF
    fi

    if [[ ! -f "${XDG_CONF_HOME}/hypr/matugen-colors.conf" ]]; then
        cat > "${XDG_CONF_HOME}/hypr/matugen-colors.conf" <<'EOF'
general {
    col.active_border = rgba(00ffffee) rgba(ff00ffee) 45deg
    col.inactive_border = rgba(595959aa)
}

decoration {
    shadow {
        color = rgba(00000088)
        color_inactive = rgba(00000055)
    }
}

group {
    col.border_active = rgba(00ffffee) rgba(ff00ffee) 45deg
    col.border_inactive = rgba(595959aa)
    col.border_locked_active = rgba(00ffddee) rgba(00ffffee) 45deg
    col.border_locked_inactive = rgba(5f5f5f88)

    groupbar {
        col.active = rgba(00ffffcc)
        col.inactive = rgba(30303acc)
        text_color = rgba(ffffffff)
    }
}
EOF
    fi

    if [[ ! -f "${TARGET_ROFI}/theme.rasi" ]]; then
        cat > "${TARGET_ROFI}/theme.rasi" <<'EOF'
* {
    bg: #1e1e2ecc;
    bg-alt: #313244cc;
    fg: #cdd6f4;
    selected: #89b4fa;
    active: #a6e3a1;
    urgent: #f38ba8;
}

window {
    transparency: "real";
    background-color: @bg;
    border: 2px;
    border-color: @selected;
    border-radius: 14px;
    padding: 18px;
}

mainbox {
    spacing: 10px;
}

inputbar {
    background-color: @bg-alt;
    text-color: @fg;
    border-radius: 10px;
    padding: 10px;
}

listview {
    lines: 10;
    columns: 1;
    spacing: 6px;
    background-color: transparent;
}

element {
    background-color: transparent;
    text-color: @fg;
    border-radius: 8px;
    padding: 8px 10px;
}

element selected {
    background-color: @selected;
    text-color: #11111b;
}
EOF
    fi

    touch "${OWNERSHIP_MARKER}"
    return 0
}

seed_runtime_state() {
    mkdir -p "${HOME}/.cache/quickshell/weather"
    mkdir -p "${HOME}/.cache/wallpaper_picker/thumbs"
    : > /tmp/qs_active_widget
    : > /tmp/qs_widget_state
}

ensure_wallpaper_dir() {
    if [[ -d "${HOME}/.local/share/mados/wallpapers" ]]; then
        export WALLPAPER_DIR="${HOME}/.local/share/mados/wallpapers"
    else
        export WALLPAPER_DIR="${HOME}/Images/Wallpapers"
        mkdir -p "${WALLPAPER_DIR}"
    fi
}

launch_quickshell() {
    local main_qml="${TARGET_HYPR_SCRIPTS}/quickshell/Main.qml"
    local bar_qml="${TARGET_HYPR_SCRIPTS}/quickshell/TopBar.qml"

    pkill -f "quickshell.*Main.qml" >/dev/null 2>&1 || true
    pkill -f "quickshell.*TopBar.qml" >/dev/null 2>&1 || true

    quickshell -p "${main_qml}" >/dev/null 2>&1 &
    quickshell -p "${bar_qml}" >/dev/null 2>&1 &

    if [[ -x "${TARGET_HYPR_SCRIPTS}/volume_listener.sh" ]]; then
        pkill -f "volume_listener.sh" >/dev/null 2>&1 || true
        "${TARGET_HYPR_SCRIPTS}/volume_listener.sh" >/dev/null 2>&1 &
    fi

    if [[ -f "${TARGET_HYPR_SCRIPTS}/quickshell/focustime/focus_daemon.py" ]]; then
        pkill -f "focus_daemon.py" >/dev/null 2>&1 || true
        python3 "${TARGET_HYPR_SCRIPTS}/quickshell/focustime/focus_daemon.py" >/dev/null 2>&1 &
    fi

    if command -v awww-daemon >/dev/null 2>&1; then
        pgrep -x awww-daemon >/dev/null 2>&1 || awww-daemon >/dev/null 2>&1 &
    fi

    if [[ -x "${TARGET_HYPR_SCRIPTS}/init.sh" ]]; then
        "${TARGET_HYPR_SCRIPTS}/init.sh" >/dev/null 2>&1 &
    fi

    if command -v swaync >/dev/null 2>&1; then
        pgrep -x swaync >/dev/null 2>&1 || swaync -c "${TARGET_SWAYNC}/config.json" >/dev/null 2>&1 &
    fi

    return 0
}

main() {
    require_cmd quickshell
    require_cmd hyprctl
    require_cmd jq
    require_cmd nmcli
    require_cmd swaync-client

    ensure_hyprland_session
    prepare_user_runtime
    seed_runtime_state
    ensure_wallpaper_dir
    launch_quickshell

    log_info "imperative-dots started successfully"
    return 0
}

main "$@"
