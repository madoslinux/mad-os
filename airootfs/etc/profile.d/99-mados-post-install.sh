#!/bin/sh
# Enable madOS post-install service on first login
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    if [ -f "$HOME/.config/systemd/user/mados-post-install.service" ]; then
        # Check if service is already enabled
        if ! systemctl --user is-enabled --quiet mados-post-install.service 2>/dev/null; then
            systemctl --user daemon-reload
            systemctl --user enable mados-post-install.service
            systemctl --user start mados-post-install.service
        fi
    fi
fi
