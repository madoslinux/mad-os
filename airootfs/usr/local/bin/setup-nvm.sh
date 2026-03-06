#!/bin/bash
# setup-nvm.sh - Instala NVM y Node para el usuario actual
# Este script se ejecuta post-instalación para configurar el entorno de desarrollo

set -euo pipefail

NVM_VERSION="v0.39.7"
NODE_VERSION="24"

log_info() {
    echo "  $*"
}

log_ok() {
    echo "  ✓ $*"
}

log_warn() {
    echo "  ⚠ $*"
}

install_nvm() {
    local nvm_dir="$HOME/.nvm"
    
    if [[ -d "$nvm_dir" ]]; then
        log_ok "NVM ya está instalado"
        return 0
    fi
    
    log_info "Instalando NVM..."
    if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash 2>&1; then
        log_ok "NVM instalado"
        return 0
    else
        log_warn "Falló la instalación de NVM"
        return 1
    fi
}

install_node() {
    local nvm_dir="$HOME/.nvm"
    
    if [[ ! -s "$nvm_dir/nvm.sh" ]]; then
        log_warn "NVM no está instalado"
        return 1
    fi
    
    # Source nvm
    # shellcheck source=/dev/null
    source "$nvm_dir/nvm.sh" 2>/dev/null || true
    
    # Check if node is already installed
    if nvm list "$NODE_VERSION" 2>/dev/null | grep -q "$NODE_VERSION"; then
        log_ok "Node ${NODE_VERSION} ya está instalado"
        return 0
    fi
    
    log_info "Instalando Node ${NODE_VERSION}..."
    if nvm install "$NODE_VERSION" 2>&1; then
        nvm alias default "$NODE_VERSION" 2>/dev/null || true
        log_ok "Node ${NODE_VERSION} instalado"
        return 0
    else
        log_warn "Falló la instalación de Node"
        return 1
    fi
}

main() {
    echo ""
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║     NVM y Node - Configurador           ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo ""
    
    # Verificar conexión a internet
    if ! curl -sf --connect-timeout 5 https://github.com/ >/dev/null 2>&1; then
        log_warn "No hay conexión a Internet"
        echo "  Conecta a internet y vuelve a ejecutar: setup-nvm.sh"
        return 1
    fi
    
    if install_nvm; then
        install_node
    fi
    
    echo ""
    echo "  Para usar Node, reinicia tu terminal o ejecuta:"
    echo "    source ~/.nvm/nvm.sh"
    echo ""
    
    return 0
}

main "$@"
