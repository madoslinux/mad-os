#!/usr/bin/env bash
# run-parts.sh - Execute all customize_airootfs.d modules in order
# This script runs each module in lexical order
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$(dirname "$SCRIPT_DIR")"
MODULE_PREFIX="customize_airootfs.d"
LOG_FILE="/var/log/customize_airootfs.log"

# Source all functions from modules
for module in "$SCRIPT_DIR"/*.sh; do
    if [[ -f "$module" && -r "$module" ]]; then
        # shellcheck source=/dev/null
        source "$module"
    fi
done

run_all_modules() {
    echo "=== Running all customization modules ==="
    echo "Started at: $(date)"
    
    local failed=0
    local module_num=0
    
    for module in "$SCRIPT_DIR"/[0-9][0-9]-*.sh; do
        if [[ ! -f "$module" ]]; then
            continue
        fi
        
        module_num=$((module_num + 1))
        local module_name=$(basename "$module")
        
        echo ""
        echo "=== [$module_num] Running: $module_name ==="
        
        # Source the module to get its functions
        # shellcheck source=/dev/null
        source "$module" 2>/dev/null || true
        
        # Determine the main function to call
        local module_base=$(basename "$module" .sh)
        local main_func=""
        
        case "$module_base" in
            00-kernel)
                main_func="install_mados_kernel"
                ;;
            01-initramfs)
                main_func="generate_initramfs"
                ;;
            02-themes)
                main_func="install_themes"
                ;;
            03-apps)
                main_func="install_mados_apps"
                ;;
            04-cleanup)
                main_func="cleanup_all"
                ;;
        esac
        
        if [[ -n "$main_func" && $(type -t "$main_func" 2>/dev/null) == "function" ]]; then
            if ! "$main_func"; then
                echo "ERROR: $module_name failed"
                failed=$((failed + 1))
            fi
        else
            # Try to execute the module directly if no main function found
            if ! bash "$module"; then
                echo "ERROR: $module_name failed"
                failed=$((failed + 1))
            fi
        fi
    done
    
    echo ""
    echo "=== All modules completed ==="
    echo "Finished at: $(date)"
    
    if [[ $failed -gt 0 ]]; then
        echo "WARNING: $failed module(s) failed"
        return 1
    fi
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if ! run_all_modules; then
        echo "FATAL: Some modules failed"
        exit 1
    fi
fi
