#!/usr/bin/env bash
# Show madOS welcome info on first login

WELCOME_INFO_SHOWN="/tmp/.mados-welcome-info-shown"
PACMAN_DB_FIXED="/tmp/.mados-pacman-db-fixed"

# Fix pacman db warnings on live environment (only once, as root)
if [[ -d /run/archiso ]] && [[ ! -f "$PACMAN_DB_FIXED" ]]; then
    if command -v pacman-db-upgrade &>/dev/null; then
        # Run directly as root in live environment (su without password)
        su -c "pacman-db-upgrade" root &>/dev/null || true
        touch "$PACMAN_DB_FIXED"
    fi
fi

# Only show once per boot
if [[ -f "$WELCOME_INFO_SHOWN" ]]; then
    return 0
fi

if [[ ! -d /run/archiso ]]; then
    return 0
fi

if [[ -t 0 && -t 1 ]]; then
    cat << 'INNER_EOF'

╔════════════════════════════════════════════════════════════════╗
║                    madOS Live Environment                      ║
╚════════════════════════════════════════════════════════════════╝

🔧 Quick Commands:
   • Install madOS:     sudo install-mados
   • AI Assistant:      opencode
   • Package Manager:   sudo pacman -S <package>

INNER_EOF
    
    # Mark as shown
    touch "$WELCOME_INFO_SHOWN"
fi
