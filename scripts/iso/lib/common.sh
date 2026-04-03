#!/usr/bin/env bash

set -euo pipefail

log() {
    printf "  %s\n" "$*"
}

step() {
    printf "\n  [%s] %s\n" "$1" "$2"
}

fail() {
    printf "\n  ✗ %s\n" "$*" >&2
    exit 1
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        fail "Run as root: sudo ./build-limine-iso.sh"
    fi
}

require_cmd() {
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || fail "$cmd not found"
    done
}

resolve_iso_version() {
    local repo_dir="$1"
    local version

    version=$(git -C "$repo_dir" tag -l --sort=-version:refname 'v*' 2>/dev/null | head -1)
    version="${version:-dev}"
    echo "${version#v}"
}
