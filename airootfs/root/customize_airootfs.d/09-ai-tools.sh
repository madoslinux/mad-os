#!/usr/bin/env bash
# 09-ai-tools.sh - Install AI tools from AUR (OpenClaw, ForgeCode)
# Runs after 04-cleanup.sh so yay is available
set -euo pipefail

install_openclaw() {
    echo "Installing OpenClaw from AUR..."

    if command -v openclaw &>/dev/null; then
        echo "openclaw already installed"
        return 0
    fi

    if ! command -v yay &>/dev/null && [[ ! -x /usr/local/bin/yay ]]; then
        echo "WARNING: yay not found, skipping openclaw AUR install"
        echo "  Users can install manually: yay -S openclaw-git"
        return 0
    fi

    local yay_cmd="yay"
    if [[ -x /usr/local/bin/yay ]]; then
        yay_cmd="/usr/local/bin/yay"
    fi

    if ! "$yay_cmd" --version &>/dev/null; then
        echo "WARNING: yay found but not runnable (libalpm mismatch), skipping AUR install"
        echo "  Falling back to npm install..."
        if command -v npm &>/dev/null; then
            npm install -g openclaw@latest 2>&1 && echo "✓ OpenClaw installed via npm" || {
                echo "WARNING: OpenClaw npm install also failed"
                echo "  Users can install manually: npm install -g openclaw@latest"
            }
        else
            echo "  npm not available, cannot fallback. Install manually after boot."
        fi
        return 0
    fi

    if $yay_cmd -S --noconfirm --needed openclaw-git 2>&1; then
        echo "✓ OpenClaw installed from AUR"
    else
        echo "WARNING: openclaw-git AUR build failed"
        echo "  Falling back to npm install..."
        if command -v npm &>/dev/null; then
            npm install -g openclaw@latest 2>&1 && echo "✓ OpenClaw installed via npm" || {
                echo "WARNING: OpenClaw npm install also failed"
                echo "  Users can install manually: npm install -g openclaw@latest"
            }
        else
            echo "  npm not available, cannot fallback. Install manually after boot."
        fi
    fi
}

install_forgecode() {
    echo "Installing ForgeCode from AUR..."

    if command -v forge &>/dev/null || command -v forgecode &>/dev/null; then
        echo "forge/forgecode already installed"
        return 0
    fi

    if ! command -v yay &>/dev/null && [[ ! -x /usr/local/bin/yay ]]; then
        echo "WARNING: yay not found, skipping forgecode AUR install"
        echo "  Users can install manually: yay -S forgecode"
        return 0
    fi

    local yay_cmd="yay"
    if [[ -x /usr/local/bin/yay ]]; then
        yay_cmd="/usr/local/bin/yay"
    fi

    if ! "$yay_cmd" --version &>/dev/null; then
        echo "WARNING: yay found but not runnable (libalpm mismatch), skipping AUR install"
        echo "  Falling back to curl installer..."
        if command -v curl &>/dev/null; then
            curl -fsSL https://forgecode.dev/cli | sh 2>&1 && echo "✓ ForgeCode installed via curl" || {
                echo "WARNING: ForgeCode curl install also failed"
                echo "  Users can install manually: curl -fsSL https://forgecode.dev/cli | sh"
            }
        else
            echo "  curl not available, cannot fallback. Install manually after boot."
        fi
        return 0
    fi

    if $yay_cmd -S --noconfirm --needed forgecode 2>&1; then
        echo "✓ ForgeCode installed from AUR"
    else
        echo "WARNING: forgecode AUR build failed"
        echo "  Falling back to curl installer..."
        if command -v curl &>/dev/null; then
            curl -fsSL https://forgecode.dev/cli | sh 2>&1 && echo "✓ ForgeCode installed via curl" || {
                echo "WARNING: ForgeCode curl install also failed"
                echo "  Users can install manually: curl -fsSL https://forgecode.dev/cli | sh"
            }
        else
            echo "  curl not available, cannot fallback. Install manually after boot."
        fi
    fi
}

configure_ai_tools_permissions() {
    echo "Configuring AI tools permissions..."

    for bin in openclaw forge forgecode; do
        for path in /usr/bin/$bin /usr/local/bin/$bin; do
            if [[ -f "$path" ]]; then
                chown root:wheel "$path" 2>/dev/null || true
                chmod 755 "$path"
                echo "  → Configured: $path"
            fi
        done
    done

    if command -v forge &>/dev/null; then
        echo "  → Forge command available: forge"
    elif command -v forgecode &>/dev/null; then
        echo "  → Forge command available: forgecode"
    else
        echo "  → WARNING: ForgeCode CLI not found after install"
    fi
    echo "✓ AI tools permissions configured"
}

install_ai_tools() {
    install_openclaw
    install_forgecode
    configure_ai_tools_permissions
    echo "✓ AI tools installation complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS AI Tools Installation ==="
    install_ai_tools
    echo "=== AI Tools installation complete ==="
fi
