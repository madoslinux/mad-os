#!/usr/bin/env bash
# customize_airootfs.sh - madOS ISO customization
# 
# This script is executed by mkarchiso inside the chroot after packages are
# installed. It delegates to atomic modules in customize_airootfs.d/
#
# Each module is atomic and can be tested independently.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/customize_airootfs.d"

echo "=== madOS: Running post-installation customizations ==="
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Source all modules in order
for module in "${MODULES_DIR}"/[0-9][0-9]-*.sh; do
    if [[ -f "$module" && -r "$module" ]]; then
        echo "Loading: $(basename "$module")"
        # shellcheck source=/dev/null
        source "$module"
    fi
done

# Run modules in order
run_module() {
    local module_name="$1"
    local func_name="$2"
    
    echo ""
    echo "=== Running: $module_name ==="
    
    if [[ "$(type -t "$func_name" 2>/dev/null)" == "function" ]]; then
        if ! "$func_name"; then
            echo "ERROR: $module_name failed"
            return 1
        fi
    else
        echo "ERROR: Function $func_name not found in $module_name"
        return 1
    fi
    
    echo "✓ $module_name completed"
    return 0
}

# Execute modules in order - stop on first failure
# 00-kernel.sh - Install madOS kernel
if ! run_module "00-kernel.sh" "install_mados_kernel"; then
    echo "FATAL: Kernel installation failed"
    exit 1
fi

# 01-initramfs.sh - Generate initramfs  
if ! run_module "01-initramfs.sh" "generate_initramfs"; then
    echo "FATAL: Initramfs generation failed"
    exit 1
fi

# 02-themes.sh - Install themes
if ! run_module "02-themes.sh" "install_themes"; then
    echo "FATAL: Themes installation failed"
    exit 1
fi

# 03-apps.sh - Install applications
if ! run_module "03-apps.sh" "install_mados_apps"; then
    echo "FATAL: Apps installation failed"
    exit 1
fi

# 03-apps.sh - Setup wallpaper assets for legacy compatibility
if ! run_module "03-apps.sh" "setup_wallpaper_assets"; then
    echo "FATAL: Wallpaper assets setup failed"
    exit 1
fi

# 03-apps.sh - Install skwd-wall selector
if ! run_module "03-apps.sh" "install_skwd_wall"; then
    echo "FATAL: skwd-wall installation failed"
    exit 1
fi

# Install mados-installer
if ! run_module "03-apps.sh" "install_installer"; then
    echo "FATAL: Installer installation failed"
    exit 1
fi

# Install mados-updater
if ! run_module "03-apps.sh" "install_updater"; then
    echo "FATAL: Updater installation failed"
    exit 1
fi

# Install Oh My Zsh
if ! run_module "03-apps.sh" "install_oh_my_zsh"; then
    echo "FATAL: Oh My Zsh installation failed"
    exit 1
fi

# 04-sddm-qylock.sh - Install SDDM and qylock theme assets
if ! run_module "04-sddm-qylock.sh" "install_sddm_qylock"; then
    echo "FATAL: SDDM qylock setup failed"
    exit 1
fi

# 05-shell-theme.sh - Prepare imperative-dots shell theme
if ! run_module "05-shell-theme.sh" "install_shell_theme_module"; then
    echo "FATAL: Shell theme preparation failed"
    exit 1
fi

# 06-network.sh - Ensure NetworkManager defaults for live ISO
if ! run_module "06-network.sh" "configure_network_services"; then
    echo "FATAL: Network defaults configuration failed"
    exit 1
fi

# 07-pacman-runtime.sh - Set runtime pacman compatibility defaults
if ! run_module "07-pacman-runtime.sh" "configure_runtime_pacman"; then
    echo "FATAL: Runtime pacman configuration failed"
    exit 1
fi

# 08-firefox-defaults.sh - Configure Firefox for low memory
if ! run_module "08-firefox-defaults.sh" "setup_skel_firefox_prefs"; then
    echo "FATAL: Firefox defaults configuration failed"
    exit 1
fi
setup_root_firefox_prefs
setup_firefox_wrapper

# 09-audio-fix.sh - Fix audio "Dummy Output" and enable PipeWire services
if ! run_module "09-audio-fix.sh" "main"; then
    echo "FATAL: Audio fix configuration failed"
    exit 1
fi

# 04-cleanup.sh - Cleanup
if ! run_module "04-cleanup.sh" "cleanup_all"; then
    echo "FATAL: Cleanup failed"
    exit 1
fi

# 09-ai-tools.sh - Install AI tools (OpenClaw, ForgeCode) from AUR
if ! run_module "09-ai-tools.sh" "install_ai_tools"; then
    echo "WARNING: AI tools installation had issues (non-fatal, tools may need manual install)"
fi

echo ""
echo "=== madOS: Post-installation complete ==="
echo "Finished at: $(date '+%Y-%m-%d %H:%M:%S')"

exit 0
