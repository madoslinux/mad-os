#!/bin/bash
# setup-ollama.sh - Instala Ollama (LLM local)
# Requiere conexión a Internet. Instala en persistencia si está disponible,
# de lo contrario instala en /usr/local

set -euo pipefail

OLLAMA_CMD="ollama"
OLLAMA_INSTALL_DIR="/usr/local"
PERSIST_DIR="/mnt/persistence/usr/local"
MEDIA_HELPER="/usr/local/lib/mados-media-helper.sh"

log_info() {
    echo "  $*"
    logger -p user.info -t setup-ollama "$*" 2>/dev/null || true
}

log_warn() {
    echo "  ⚠ $*"
    logger -p user.warning -t setup-ollama "$*" 2>/dev/null || true
}

log_error() {
    echo "  ✗ $*"
    logger -p user.error -t setup-ollama "$*" 2>/dev/null || true
}

log_ok() {
    echo "  ✓ $*"
    logger -p user.info -t setup-ollama "$*" 2>/dev/null || true
}

check_already_installed() {
    if command -v "$OLLAMA_CMD" &>/dev/null; then
        return 0
    fi
    if [[ -x "/usr/bin/$OLLAMA_CMD" ]]; then
        return 0
    fi
    if [[ -x "/usr/local/bin/$OLLAMA_CMD" ]]; then
        return 0
    fi
    if [[ -x "$OLLAMA_INSTALL_DIR/bin/$OLLAMA_CMD" ]]; then
        return 0
    fi
    if [[ -x "$PERSIST_DIR/bin/$OLLAMA_CMD" ]]; then
        return 0
    fi
    return 1
}

copy_from_live() {
    local live_bin=""
    
    if [[ -x "/usr/bin/$OLLAMA_CMD" ]]; then
        live_bin="/usr/bin/$OLLAMA_CMD"
    elif [[ -x "/usr/local/bin/$OLLAMA_CMD" ]]; then
        live_bin="/usr/local/bin/$OLLAMA_CMD"
    fi
    
    if [[ -n "$live_bin" ]]; then
        log_info "Copiando binario de live USB..."
        
        local target_dir="$OLLAMA_INSTALL_DIR"
        local using_persistence=false
        
        if [[ -d "/mnt/persistence" ]] && [[ -w "/mnt/persistence/usr/local" ]]; then
            target_dir="$PERSIST_DIR"
            using_persistence=true
            mkdir -p "$target_dir/bin"
        elif [[ -d "/mnt/persistence" ]] && [[ -w "/mnt/persistence" ]]; then
            target_dir="$PERSIST_DIR"
            using_persistence=true
            mkdir -p "$target_dir/bin"
        fi
        
        mkdir -p "$target_dir/bin"
        cp "$live_bin" "$target_dir/bin/$OLLAMA_CMD"
        chmod +x "$target_dir/bin/$OLLAMA_CMD"
        
        if [[ "$using_persistence" == true ]]; then
            ln -sf "$target_dir/bin/$OLLAMA_CMD" "$OLLAMA_INSTALL_DIR/bin/$OLLAMA_CMD" 2>/dev/null || true
        fi
        
        return 0
    fi
    
    return 1
}

install_ollama() {
    log_info "Instalando Ollama..."

    local target_dir="$OLLAMA_INSTALL_DIR"
    local using_persistence=false

    if [[ -d "/mnt/persistence" ]] && [[ -w "/mnt/persistence/usr/local" ]]; then
        target_dir="$PERSIST_DIR"
        using_persistence=true
        mkdir -p "$target_dir/bin"
    elif [[ -d "/mnt/persistence" ]] && [[ -w "/mnt/persistence" ]]; then
        target_dir="$PERSIST_DIR"
        using_persistence=true
        mkdir -p "$target_dir/bin"
    fi

    if curl -fsSL https://ollama.com/install.sh | OLLAMA_INSTALL_DIR="$target_dir" sh 2>&1; then
        if [[ -x "$target_dir/bin/$OLLAMA_CMD" ]] || command -v "$OLLAMA_CMD" &>/dev/null; then
            log_ok "Ollama instalado"

            if [[ "$using_persistence" == true ]]; then
                ln -sf "$target_dir/bin/$OLLAMA_CMD" "$OLLAMA_INSTALL_DIR/bin/$OLLAMA_CMD" 2>/dev/null || true
            fi
            return 0
        fi
    fi

    return 1
}

main() {
    echo ""
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║         Ollama - Instalador             ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo ""

    if check_already_installed; then
        local version
        version=$("$OLLAMA_CMD" --version 2>/dev/null || echo "desconocida")
        log_ok "Ollama ya está instalado (versión: $version)"
        return 0
    fi

    if [[ -f "$MEDIA_HELPER" ]]; then
        source "$MEDIA_HELPER"
        if ! can_install_software; then
            log_warn "Medio óptico (DVD/CD) detectado."
            log_info "No se puede instalar Ollama en medio de solo lectura."
            log_info "Instala madOS en disco con: sudo /opt/mados-installer/mados-installer"
            return 0
        fi
    fi

    log_info "Buscando binario en live USB..."
    if copy_from_live; then
        log_ok "Ollama copiado del live USB"
    else
        log_info "No se encontró binario en live. Descargando..."
        
        if ! curl -sf --connect-timeout 5 https://ollama.com/ >/dev/null 2>&1; then
            log_warn "No hay conexión a Internet."
            log_info "Conecta a la red primero:"
            log_info "  WiFi:     nmtui  o  iwctl station wlan0 connect <SSID>"
            log_info "  Ethernet: debería conectarse automáticamente"
            log_info ""
            log_info "Luego ejecuta de nuevo: setup-ollama.sh"
            return 0
        fi
        log_ok "Conexión a Internet disponible."

        if install_ollama; then
            :
        else
            log_error "No se pudo instalar Ollama."
            log_info "Intenta instalar manualmente:"
            log_info "  curl -fsSL https://ollama.com/install.sh | sh"
            log_info ""
            log_info "Y reporta el error."
            return 1
        fi
    fi

    echo ""
    local final_version
    final_version=$("$OLLAMA_CMD" --version 2>/dev/null || echo "desconocida")
    log_ok "Ollama instalado correctamente (versión: $final_version)"
    echo ""
    log_info "Para usar Ollama, ejecuta: ollama"
    echo ""

    return 0
}

main "$@"
