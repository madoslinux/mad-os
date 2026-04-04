#!/usr/bin/env bash
# 01-initramfs.sh - Generate initramfs for madOS kernel
# Atomic module for initramfs generation
set -euo pipefail

detect_mados_kernel_version() {
    local kver
    kver=$(ls /lib/modules/ 2>/dev/null | grep -E "mados$" | head -1 || true)
    if [[ -z "$kver" ]]; then
        echo "ERROR: No linux-mados kernel found in /lib/modules"
        return 1
    fi
    echo "$kver"
    return 0
}

setup_mkinitcpio_presets() {
    local kver="$1"
    local preset_file="/etc/mkinitcpio.d/linux-mados.preset"
    
    # Remove any existing presets
    rm -f /etc/mkinitcpio.d/linux.preset
    rm -f /etc/mkinitcpio.d/linux-zen.preset
    rm -f /etc/mkinitcpio.d/linux-lts.preset
    rm -f /etc/mkinitcpio.d/linux-mados.preset
    
    # Create preset for madOS kernel
    cat > "$preset_file" << EOF
# mkinitcpio preset file for madOS kernel
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-mados"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux-mados.img"
default_options=""
fallback_image="/boot/initramfs-linux-mados-fallback.img"
fallback_options="-S autodetect"
EOF
    
    chmod 644 "$preset_file"
    echo "Created mkinitcpio preset: $preset_file"
}

generate_initramfs() {
    local kver="${1:-$(detect_mados_kernel_version)}"
    
    if [[ -z "$kver" ]]; then
        echo "ERROR: No kernel version provided and could not detect"
        return 1
    fi
    
    echo "Generating initramfs for kernel: $kver"
    
    # Ensure vmlinuz exists
    if [[ ! -f /boot/vmlinuz-linux-mados ]]; then
        echo "ERROR: /boot/vmlinuz-linux-mados not found"
        return 1
    fi
    
    # Setup presets
    setup_mkinitcpio_presets "$kver"
    
    # Generate initramfs
    if ! mkinitcpio -k "$kver" -g /boot/initramfs-linux-mados.img 2>&1; then
        echo "ERROR: mkinitcpio failed"
        return 1
    fi
    
    # Verify
    if [[ ! -f /boot/initramfs-linux-mados.img ]]; then
        echo "ERROR: initramfs not created"
        return 1
    fi
    
    local size=$(du -h /boot/initramfs-linux-mados.img | cut -f1)
    echo "✓ Initramfs created: /boot/initramfs-linux-mados.img (${size})"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS Initramfs Generation ==="

    kver=""
    kver=$(detect_mados_kernel_version) || {
        echo "FATAL: Could not detect kernel version"
        exit 1
    }
    
    if ! generate_initramfs "$kver"; then
        echo "FATAL: Initramfs generation failed"
        exit 1
    fi
    
    echo "=== Initramfs generation complete ==="
fi
