#!/bin/bash
# madOS Post-Install System-wide Launcher
# Runs once on first user login after system installation

MARKER_FILE="/var/lib/mados/post-install-pending"
DONE_FLAG="/var/lib/mados/post-install-done"
USER_MARKERSHA="$HOME/.cache/mados-post-install-check"

# Check if system-wide post-install is pending
if [ ! -f "$MARKER_FILE" ]; then
    exit 0
fi

# Check if already done system-wide
if [ -f "$DONE_FLAG" ]; then
    rm -f "$MARKER_FILE" 2>/dev/null
    exit 0
fi

# Check if GUI environment
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
    exit 0
fi

# Check if already tried for this user
if [ -f "$USER_MARKERSHA" ]; then
    exit 0
fi

# Create user marker to prevent running for this user again
touch "$USER_MARKERSHA" 2>/dev/null

# Remove system marker so next user won't trigger (only first user runs it)
rm -f "$MARKER_FILE" 2>/dev/null || true

# Small delay to ensure compositor is ready
sleep 3

# Launch post-install in background
/usr/local/bin/mados-post-install &

# Create done flag when process succeeds
wait $!
if [ $? -eq 0 ]; then
    mkdir -p "$(dirname "$DONE_FLAG")" 2>/dev/null
    touch "$DONE_FLAG" 2>/dev/null || true
fi
