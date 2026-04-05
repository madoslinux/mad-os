#!/usr/bin/env bash
# 05-shell-theme.sh - Validate imperative-dots theme shipped in the repository
set -euo pipefail

THEME_INSTALL_DIR="/usr/share/mados/themes/imperative-dots"

create_theme_launcher_stub() {
    local start_script="$THEME_INSTALL_DIR/start.sh"
    local healthcheck_script="$THEME_INSTALL_DIR/healthcheck.sh"

    if [[ -f "$start_script" ]]; then
        return 0
    fi

    cat > "$start_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if command -v waybar >/dev/null 2>&1; then
    exec waybar
fi

exit 1
EOF
    chmod +x "$start_script"

    cat > "$healthcheck_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

pgrep -x waybar >/dev/null 2>&1
EOF
    chmod +x "$healthcheck_script"

    echo "WARNING: Theme has no start.sh. Stub launcher created to preserve fallback behavior"
    return 0
}

install_shell_theme_module() {
    if [[ ! -d "$THEME_INSTALL_DIR" ]]; then
        echo "WARNING: Missing theme directory at ${THEME_INSTALL_DIR}"
        return 0
    fi

    echo "Preparing imperative-dots theme from local repository files..."
    chown -R root:root "$THEME_INSTALL_DIR"
    create_theme_launcher_stub
    chmod +x "$THEME_INSTALL_DIR/start.sh"
    chmod +x "$THEME_INSTALL_DIR/healthcheck.sh"
    echo "✓ imperative-dots theme prepared from repository"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS Shell Theme Installation ==="
    install_shell_theme_module
    echo "=== Shell theme installation complete ==="
fi
