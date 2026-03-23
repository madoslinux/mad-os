#!/bin/bash
# madOS - Create User Account
set -euo pipefail

USERNAME="${1:-}"
HOSTNAME="${2:-}"

if [ -z "$USERNAME" ] || [ -z "$HOSTNAME" ]; then
    echo "ERROR: USERNAME and HOSTNAME arguments required"
    exit 1
fi

echo "[2/8] Creating user account..."

echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

useradd -m -G wheel,audio,video,storage -s /usr/bin/zsh "$USERNAME"
passwd -d "$USERNAME" 2>/dev/null || true

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: /usr/local/bin/opencode,/usr/local/bin/ollama,/usr/bin/pacman,/usr/bin/systemctl,/usr/bin/usbguard" > /etc/sudoers.d/opencode-nopasswd
chmod 440 /etc/sudoers.d/opencode-nopasswd

echo "  User account created: $USERNAME"
