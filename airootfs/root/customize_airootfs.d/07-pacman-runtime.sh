#!/usr/bin/env bash
# 07-pacman-runtime.sh - Make runtime pacman robust across kernel capabilities
set -euo pipefail

configure_runtime_pacman() {
    local pacman_conf="/etc/pacman.conf"

    [[ -f "$pacman_conf" ]] || return 0

    # Safe default for live/installed systems on kernels without Landlock.
    sed -i 's/^DownloadUser = alpm/#DownloadUser = alpm/' "$pacman_conf"

    if grep -q '^#DisableSandboxFilesystem' "$pacman_conf"; then
        sed -i 's/^#DisableSandboxFilesystem/DisableSandboxFilesystem/' "$pacman_conf"
    elif ! grep -q '^DisableSandboxFilesystem' "$pacman_conf"; then
        printf '\nDisableSandboxFilesystem\n' >>"$pacman_conf"
    fi

    if grep -q '^#DisableSandboxSyscalls' "$pacman_conf"; then
        sed -i 's/^#DisableSandboxSyscalls/DisableSandboxSyscalls/' "$pacman_conf"
    elif ! grep -q '^DisableSandboxSyscalls' "$pacman_conf"; then
        printf 'DisableSandboxSyscalls\n' >>"$pacman_conf"
    fi

    # Normalize older pacman option if present.
    sed -i 's/^#DisableSandbox$/DisableSandbox/' "$pacman_conf"

    echo "Configured runtime pacman sandbox defaults"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_runtime_pacman
fi
