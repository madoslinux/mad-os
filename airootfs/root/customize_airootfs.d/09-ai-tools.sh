#!/usr/bin/env bash
# 09-ai-tools.sh - Install AI tools from AUR (OpenClaw, ForgeCode)
# Runs after 04-cleanup.sh so yay is available
set -euo pipefail

install_openclaw_fallback() {
    echo "  Falling back to npm install..."
    if command -v npm &>/dev/null; then
        npm install -g openclaw@latest 2>&1 && echo "✓ OpenClaw installed via npm" || {
            echo "WARNING: OpenClaw npm install also failed"
            echo "  Users can install manually: npm install -g openclaw@latest"
        }
    else
        echo "  npm not available, cannot fallback. Install manually after boot."
    fi
}

install_forgecode_fallback() {
    echo "  Falling back to curl installer..."
    if command -v curl &>/dev/null; then
        curl -fsSL https://forgecode.dev/cli | sh 2>&1 && echo "✓ ForgeCode installed via curl" || {
            echo "WARNING: ForgeCode curl install also failed"
            echo "  Users can install manually: curl -fsSL https://forgecode.dev/cli | sh"
        }
    else
        echo "  curl not available, cannot fallback. Install manually after boot."
    fi
}

install_qwen_fallback() {
    echo "  Installing via official Qwen installer..."
    if command -v curl &>/dev/null; then
        bash -c "$(curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh)" -s --source qwenchat </dev/null 2>&1 && echo "✓ Qwen installed" || {
            echo "WARNING: Qwen install failed"
            echo "  Users can install manually after boot"
        }
    else
        echo "  curl not available, cannot install. Install manually after boot."
    fi
}

install_qwen_npm_fallback() {
    echo "  Falling back to npm install..."
    if command -v npm &>/dev/null; then
        if npm install -g @qwen-code/qwen-code@latest 2>&1; then
            echo "✓ Qwen installed via npm (@qwen-code/qwen-code)"
            return 0
        fi

        if npm install -g qwen-code@latest 2>&1; then
            echo "✓ Qwen installed via npm (qwen-code)"
            return 0
        fi

        echo "WARNING: Qwen npm install also failed"
        echo "  Users can install manually: npm install -g @qwen-code/qwen-code"
    else
        echo "  npm not available, cannot fallback. Install manually after boot."
    fi
    return 1
}

ensure_forge_global_command() {
    local forge_src=""

    if command -v forge &>/dev/null; then
        return 0
    fi

    for candidate in /root/.local/bin/forge /home/liveuser/.local/bin/forge; do
        if [[ -x "$candidate" ]]; then
            forge_src="$candidate"
            break
        fi
    done

    if [[ -z "$forge_src" ]]; then
        echo "  WARNING: forge binary not found after curl install"
        return 1
    fi

    install -m 755 "$forge_src" /usr/local/bin/forge
    echo "  → Installed global forge wrapper: /usr/local/bin/forge"
    return 0
}

ensure_qwen_global_command() {
    local qwen_src=""

    if command -v qwen &>/dev/null; then
        qwen_src="$(command -v qwen)"
    else
        for candidate in /root/.local/bin/qwen /home/liveuser/.local/bin/qwen /root/.qwen/bin/qwen /home/liveuser/.qwen/bin/qwen; do
            if [[ -x "$candidate" ]]; then
                qwen_src="$candidate"
                break
            fi
        done
    fi

    if [[ -z "$qwen_src" ]]; then
        echo "  WARNING: qwen binary not found after install"
        return 1
    fi

    if [[ "$qwen_src" != "/usr/local/bin/qwen" ]]; then
        install -m 755 "$qwen_src" /usr/local/bin/qwen
        echo "  → Installed global qwen wrapper: /usr/local/bin/qwen"
    fi

    return 0
}

install_openclaw() {
    echo "Installing OpenClaw..."

    if command -v openclaw &>/dev/null; then
        echo "openclaw already installed"
        return 0
    fi

    install_openclaw_fallback
}

install_forgecode() {
    echo "Installing ForgeCode..."

    if command -v forge &>/dev/null || command -v forgecode &>/dev/null; then
        echo "forge/forgecode already installed"
        return 0
    fi

    install_forgecode_fallback
    ensure_forge_global_command || true
}

install_qwen() {
    echo "Installing Qwen..."

    if command -v qwen &>/dev/null; then
        echo "qwen already installed"
        return 0
    fi

    install_qwen_fallback

    if ! command -v qwen &>/dev/null; then
        install_qwen_npm_fallback || true
    fi

    ensure_qwen_global_command || true
}

configure_ai_tools_permissions() {
    echo "Configuring AI tools permissions..."

    for bin in openclaw forge forgecode qwen; do
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
    install_qwen
    configure_ai_tools_permissions
    echo "✓ AI tools installation complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS AI Tools Installation ==="
    install_ai_tools
    echo "=== AI Tools installation complete ==="
fi
