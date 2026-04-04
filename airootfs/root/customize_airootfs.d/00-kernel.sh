#!/usr/bin/env bash
# 00-kernel.sh - Install madOS custom kernel
# Atomic module for kernel installation
set -euo pipefail

MADOS_KERNEL_VERSION=""
MADOS_KERNEL_URL=""
MADOS_HEADERS_URL=""
MADOS_KERNEL_VERSION_FILE="/etc/mados/kernel-version"

verify_mados_kernel() {
    local kver="$1"
    local status=0
    
    if [[ ! -f "/boot/vmlinuz-linux-mados" ]]; then
        echo "ERROR: /boot/vmlinuz-linux-mados not found"
        status=1
    fi
    
    if [[ ! -d "/lib/modules/${kver}" ]]; then
        echo "ERROR: /lib/modules/${kver} not found"
        status=1
    fi
    
    return $status
}

fetch_latest_kernel_version() {
    local release_json
    release_json=$(curl -fsSL "https://api.github.com/repos/madoslinux/mados-kernel/releases/latest")

    MADOS_KERNEL_VERSION=$(echo "$release_json" | jq -r '.tag_name // empty' | sed 's/^v//')
    if [[ -z "$MADOS_KERNEL_VERSION" ]]; then
        echo "ERROR: Failed to fetch latest kernel version from GitHub"
        return 1
    fi

    MADOS_KERNEL_URL=$(echo "$release_json" | jq -r '.assets[]? | select(.name | test("^linux-mados-[0-9].*\\.pkg\\.tar\\.(zst|xz)$")) | .browser_download_url' | head -1)
    MADOS_HEADERS_URL=$(echo "$release_json" | jq -r '.assets[]? | select(.name | test("^linux-mados-headers-[0-9].*\\.pkg\\.tar\\.(zst|xz)$")) | .browser_download_url' | head -1)

    if [[ -z "$MADOS_KERNEL_URL" || -z "$MADOS_HEADERS_URL" ]]; then
        echo "ERROR: Could not find linux-mados and linux-mados-headers assets in latest release"
        return 1
    fi

    echo "Latest madOS kernel: ${MADOS_KERNEL_VERSION}"
    return 0
}

install_mados_kernel() {
    local kernel_tmp="/tmp/linux-mados.pkg.tar"
    
    # Fetch version
    if ! fetch_latest_kernel_version; then
        echo "ERROR: Failed to get kernel version"
        return 1
    fi
    
    # Save version for reference
    echo "${MADOS_KERNEL_VERSION}" > "$MADOS_KERNEL_VERSION_FILE"
    
    # Download kernel
    echo "Downloading madOS kernel v${MADOS_KERNEL_VERSION}..."
    if ! curl -fsSL -o "$kernel_tmp" "$MADOS_KERNEL_URL"; then
        echo "ERROR: Failed to download kernel from ${MADOS_KERNEL_URL}"
        rm -f "$kernel_tmp"
        return 1
    fi
    
    local size=$(stat -c%s "$kernel_tmp" 2>/dev/null || echo "0")
    echo "Downloaded kernel: ${size} bytes"
    
    # Extract kernel
    if ! tar -xf "$kernel_tmp" -C /; then
        echo "ERROR: Failed to extract kernel package"
        rm -f "$kernel_tmp"
        return 1
    fi
    rm -f "$kernel_tmp"
    
    # Remove conflicting symlinks in modules directory
    local kver_full
    kver_full=$(ls /lib/modules/ 2>/dev/null | grep -E "mados$" | head -1 || true)
    if [[ -n "$kver_full" && -L "/lib/modules/${kver_full}/build" ]]; then
        rm -f "/lib/modules/${kver_full}/build"
    fi
    
    # Verify installation
    if ! verify_mados_kernel "$kver_full"; then
        return 1
    fi
    
    echo "✓ Kernel v${MADOS_KERNEL_VERSION} installed successfully"
    echo "  vmlinuz: /boot/vmlinuz-linux-mados"
    echo "  modules: /lib/modules/${kver_full}"
    
    # Download and install headers
    install_kernel_headers "$kver_full"
    
    return 0
}

install_kernel_headers() {
    local kver_full="${1:-$(ls /lib/modules/ 2>/dev/null | grep -E "mados$" | head -1 || true)}"
    local headers_tmp="/tmp/linux-mados-headers.pkg.tar"
    local headers_path="/usr/src/linux-${kver_full}"
    
    echo "Downloading madOS kernel headers..."
    if ! curl -fsSL -o "$headers_tmp" "$MADOS_HEADERS_URL"; then
        echo "WARNING: Failed to download kernel headers"
        rm -f "$headers_tmp"
        return 1
    fi
    
    if ! tar -xf "$headers_tmp" -C /; then
        echo "WARNING: Failed to extract kernel headers"
        rm -f "$headers_tmp"
        return 1
    fi
    rm -f "$headers_tmp"
    
    if [[ ! -d "$headers_path" ]]; then
        echo "WARNING: Headers not found at ${headers_path}"
        return 1
    fi
    
    echo "✓ Headers installed to ${headers_path}"
    return 0
}

remove_arch_kernel() {
    local removed=0
    
    # Remove Arch's default linux kernel
    if [[ -f /boot/vmlinuz-linux ]]; then
        echo "Removing Arch's default linux kernel..."
        rm -f /boot/vmlinuz-linux
        rm -f /boot/initramfs-linux.img
        rm -f /boot/initramfs-linux-fallback.img
        rm -f /boot/System.map-linux
        rm -f /boot/config-linux
        removed=1
    fi
    
    # Remove linux kernel modules
    if [[ -d /lib/modules ]]; then
        for mod_dir in /lib/modules/*; do
            local basename=$(basename "$mod_dir")
            if [[ "$basename" != *"-mados" && "$basename" != *"-cachyos"* ]]; then
                rm -rf "$mod_dir"
                echo "  Removed: $mod_dir"
                removed=1
            fi
        done
    fi
    
    if [[ $removed -eq 1 ]]; then
        echo "✓ Arch kernel removed"
    fi
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS Kernel Installation ==="
    
    # Install madOS kernel
    if ! install_mados_kernel; then
        echo "FATAL: Kernel installation failed"
        exit 1
    fi
    
    # Remove Arch kernel
    remove_arch_kernel
    
    echo "=== Kernel installation complete ==="
fi
