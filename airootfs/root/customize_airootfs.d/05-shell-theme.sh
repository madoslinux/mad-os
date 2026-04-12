#!/usr/bin/env bash
# 05-shell-theme.sh - Validate imperative-dots theme installed from repository
set -euo pipefail

THEME_INSTALL_DIR="/usr/share/mados/themes/imperative-dots"

validate_shell_theme() {
    if [[ ! -d "$THEME_INSTALL_DIR" ]]; then
        echo "WARNING: Missing theme directory at ${THEME_INSTALL_DIR}"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/start/start.sh" ]]; then
        echo "WARNING: Theme is missing start.sh"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/quickshell/Main.qml" ]]; then
        echo "WARNING: Theme is missing scripts/quickshell/Main.qml"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/quickshell/TopBar.qml" ]]; then
        echo "WARNING: Theme is missing scripts/quickshell/TopBar.qml"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/quickshell/widgets/notifications/NotificationPopup.qml" ]]; then
        echo "WARNING: Theme is missing scripts/quickshell/widgets/notifications/NotificationPopup.qml"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/quickshell/lib/I18n.qml" ]]; then
        echo "WARNING: Theme is missing scripts/quickshell/lib/I18n.qml"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/quickshell/widgets/launcher/list_apps.py" ]]; then
        echo "WARNING: Theme is missing scripts/quickshell/widgets/launcher/list_apps.py"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/quickshell/widgets/network/wifi_panel_logic.sh" ]]; then
        echo "WARNING: Theme is missing scripts/quickshell/widgets/network/wifi_panel_logic.sh"
        return 0
    fi

    if [[ ! -f "${THEME_INSTALL_DIR}/scripts/quickshell/scripts/sys_info.sh" ]]; then
        echo "WARNING: Theme is missing scripts/quickshell/scripts/sys_info.sh"
        return 0
    fi

    if [[ ! -x "${THEME_INSTALL_DIR}/config/hypr/scripts/init.sh" ]]; then
        echo "WARNING: Theme is missing executable config/hypr/scripts/init.sh"
        return 0
    fi

    echo "✓ imperative-dots theme validated"
    return 0
}

install_shell_theme_module() {
    validate_shell_theme
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS Shell Theme Validation ==="
    install_shell_theme_module
    echo "=== Shell theme validation complete ==="
fi
