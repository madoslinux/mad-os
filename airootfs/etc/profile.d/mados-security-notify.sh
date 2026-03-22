#!/bin/bash
# /etc/profile.d/mados-security-notify.sh
# Notificaciones de seguridad para madOS

# Notificación de login exitoso
if [ -n "$SSH_CONNECTION" ]; then
    IP=$(echo "$SSH_CONNECTION" | awk '{print $3}')
    notify-send -u normal "🔐 SSH Connection" "New SSH connection from $IP" 2>/dev/null || true
    echo "$(date): SSH login from $IP - User: $USER" >> /var/log/login.log || true
fi

# Verificar fail2ban al iniciar sesión
if command -v fail2ban-client &>/dev/null; then
    BANNED=$(fail2ban-client status 2>/dev/null | grep "Total banned" | awk '{print $NF}' | tr -d ']')
    if [ "$BANNED" -gt 0 ]; then
        notify-send -u critical "⚠️ Fail2Ban Alert" "$BANNED IPs have been banned" 2>/dev/null || true
    fi
fi