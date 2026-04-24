#!/usr/bin/env bash
# 18-oh-my-zsh.sh - Install Oh My Zsh
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

install_oh_my_zsh() {
    local omz_dir="/usr/share/oh-my-zsh"

    if [[ -d "$omz_dir" ]]; then
        return 0
    fi

    echo "Installing Oh My Zsh..."

    local build_dir="${BUILD_DIR}/ohmyzsh_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"

    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --no-tags "https://github.com/ohmyzsh/ohmyzsh.git" "${build_dir}/ohmyzsh"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone oh-my-zsh after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi

    mv "${build_dir}/ohmyzsh" "$omz_dir"
    rm -rf "$build_dir"

    if [[ -d /home/mados ]]; then
        rm -rf /home/mados/.oh-my-zsh
        ln -sf "$omz_dir" /home/mados/.oh-my-zsh
        chown -h 1000:1000 /home/mados/.oh-my-zsh
    fi

    rm -rf /root/.oh-my-zsh
    ln -sf "$omz_dir" /root/.oh-my-zsh

    if [[ ! -d /etc/skel/.oh-my-zsh ]]; then
        ln -sf "$omz_dir" /etc/skel/.oh-my-zsh
    fi

    echo "✓ Oh My Zsh installed"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_oh_my_zsh
fi
