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
