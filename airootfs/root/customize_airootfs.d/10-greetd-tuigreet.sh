#!/usr/bin/env bash
# 04-greetd-tuigreet.sh - Install greetd and tuigreet for software rendering
set -euo pipefail

GREETD_CONF="/etc/greetd/config.toml"
GREETD_DIR="/etc/greetd"

install_greetd_tuigreet() {
    echo "Configuring greetd with tuigreet for madOS-lite..."

    mkdir -p "$GREETD_DIR"
    mkdir -p /usr/share/greetd/themes
    mkdir -p /run/greetd
    mkdir -p /run/user/963

    cat > "$GREETD_CONF" << 'EOF'
[default_session]
command = "tuigreet --theme /usr/share/greetd/themes/sugar-dark.css --cmd sway"
user = "greeter"

[initial_session]
command = "sway"
user = "mados"
EOF

    cat > /usr/share/greetd/themes/sugar-dark.css << 'EOF'
* {
    font-family: "Noto Sans", "Segoe UI", sans-serif;
}

window {
    background-color: #1a1a2e;
    color: #e8e4f0;
}

input, button {
    border-radius: 8px;
    padding: 8px 16px;
    margin: 4px;
}

button {
    background-color: #4a4a6a;
    color: #e8e4f0;
    border: none;
}

button:hover {
    background-color: #6a6a8a;
}

#error-message {
    color: #ff6b6b;
}
EOF

    cat > /etc/pam.d/greetd << 'EOF'
#%PAM-1.0
auth       requisite    pam_nologin.so
auth       include      system-local-login
account    include      system-local-login
session    include      system-local-login
EOF

    mkdir -p /etc/systemd/system/greetd.service.d
    cat > /etc/systemd/system/greetd.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/bash -c "while true; do openvt -s -w -- greetd; sleep 1; done"
Restart=no
EOF

    chown greeter:greeter /run/user/963
    chmod 700 /run/user/963
    usermod -a -G tty greeter
    chmod 666 /dev/tty0

    ln -sf /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service
    systemctl enable greetd.service

    echo "  → Configured greetd with tuigreet"
    echo "  → Default session: sway (Wayland compositor)"
    echo "  → Theme: sugar-dark"

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_greetd_tuigreet
fi
