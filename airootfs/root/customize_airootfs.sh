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

# Source all modules
for module in "${MODULES_DIR}"/*.sh; do
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

# Execute modules in order
failed=0

# 00-kernel.sh - Install madOS kernel
if ! run_module "00-kernel.sh" "install_mados_kernel"; then
    echo "FATAL: Kernel installation failed"
    failed=1
fi

# 01-initramfs.sh - Generate initramfs  
if ! run_module "01-initramfs.sh" "generate_initramfs"; then
    echo "FATAL: Initramfs generation failed"
    failed=1
fi

# 02-themes.sh - Install themes
if ! run_module "02-themes.sh" "install_themes"; then
    echo "WARNING: Themes installation had issues"
fi

# 03-apps.sh - Install applications
if ! run_module "03-apps.sh" "install_mados_apps"; then
    echo "WARNING: Apps installation had issues"
fi

# 04-cleanup.sh - Cleanup
if ! run_module "04-cleanup.sh" "cleanup_all"; then
    echo "WARNING: Cleanup had issues"
fi

echo ""
echo "=== madOS: Post-installation complete ==="
echo "Finished at: $(date '+%Y-%m-%d %H:%M:%S')"

if [[ $failed -eq 1 ]]; then
    exit 1
fi

exit 0
