#!/usr/bin/env bash
# 10-imperative-dots.sh - Install imperative-dots shell theme
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

install_imperative_dots() {
    echo "Installing imperative-dots..."
    local build_dir="${BUILD_DIR}/imperative-dots_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"

    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --branch main --no-tags "https://github.com/${IMPERATIVE_DOTS_REPO}.git" "$build_dir/imperative-dots"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone imperative-dots after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi

    mkdir -p "$IMPERATIVE_DOTS_INSTALL_DIR"
    rm -rf "$IMPERATIVE_DOTS_INSTALL_DIR"
    mv "$build_dir/imperative-dots" "$IMPERATIVE_DOTS_INSTALL_DIR"
    rm -rf "$build_dir"

    echo "✓ imperative-dots installed to ${IMPERATIVE_DOTS_INSTALL_DIR}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_imperative_dots
fi
