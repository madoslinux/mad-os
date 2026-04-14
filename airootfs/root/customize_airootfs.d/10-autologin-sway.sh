#!/usr/bin/env bash
# 10-autologin-sway.sh - Autologin and desktop launcher for live ISO
set -euo pipefail

install_autologin_sway() {
    echo "Configuring autologin + Sway startup for madOS-lite live..."

    chmod +x /usr/local/bin/mados-*
    chmod +x /opt/mados/*/daemon/__main__.py 2>/dev/null || true

    mkdir -p /run/user/1000
    chown 1000:1000 /run/user/1000
    chmod 700 /run/user/1000

    mkdir -p /etc/X11
    cat > /etc/X11/xorg-fbdev.conf << 'EOF'
Section "Device"
    Identifier "fbdev-card"
    Driver "fbdev"
    Option "fbdev" "/dev/fb0"
EndSection

Section "Screen"
    Identifier "fbdev-screen"
    Device "fbdev-card"
EndSection

Section "ServerLayout"
    Identifier "fbdev-layout"
    Screen 0 "fbdev-screen"
EndSection
EOF

    cat > /usr/local/bin/mados-start-desktop << 'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail

LOG="/var/log/mados-desktop.log"

log() {
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    printf '[%s] %s\n' "$ts" "$1" | tee -a "$LOG"
}

mkdir -p /var/log
touch "$LOG"

log "=== mados-start-desktop BEGIN ==="
log "kernel cmdline: $(cat /proc/cmdline)"
log "user: $(whoami) uid=$(id -u) gid=$(id -g)"
log "tty: $(tty 2>/dev/null || echo none)"
log "uptime: $(cat /proc/uptime)"

log "--- early boot journal snapshot ---"
journalctl -b -o short-monotonic --no-pager >> "$LOG" 2>&1 || true

log "--- environment ---"
log "DISPLAY=${DISPLAY:-unset}"
log "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-unset}"
log "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-unset}"
log "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unset}"
log "HOME=${HOME:-unset}"

log "--- binary checks ---"
for bin in Xorg sway foot waybar wofi swaybg; do
    if command -v "$bin" >/dev/null 2>&1; then
        log "  $bin: $(command -v "$bin")"
    else
        log "  $bin: NOT FOUND"
    fi
done

log "--- display devices ---"
if [ -d /dev/dri ]; then
    log "  /dev/dri: $(ls /dev/dri/ 2>/dev/null || echo empty)"
else
    log "  /dev/dri: not found"
fi
log "  framebuffer devices: $(ls /dev/fb* 2>/dev/null || echo none)"
log "  note: sway cannot run directly on framebuffer; using sway on X11"

log "--- plymouth handoff ---"
if plymouth --ping >/dev/null 2>&1; then
    log "plymouth is active"
    plymouth display-message --text="Starting madOS desktop..." >/dev/null 2>&1 || true
    # Keep splash visible during graphics handoff instead of immediate blink-out.
    plymouth quit --retain-splash >/dev/null 2>&1 || true
    sleep 0.4
else
    log "plymouth not active"
fi

rm -f /tmp/.X0-lock /tmp/.X11-unix/X0 2>/dev/null || true

log "--- starting Xorg ---"
if [ -e /dev/fb0 ]; then
    log "starting Xorg with fbdev config"
    /usr/lib/Xorg :0 vt1 -quiet -nolisten tcp -config /etc/X11/xorg-fbdev.conf >> "$LOG" 2>&1 &
else
    log "starting Xorg with default config (no /dev/fb0)"
    /usr/lib/Xorg :0 vt1 -quiet -nolisten tcp >> "$LOG" 2>&1 &
fi
XORG_PID=$!
log "xorg pid: $XORG_PID"

for wait_s in 0 1 2 3 4 5 6 7 8 9 10; do
    if [ -e /tmp/.X11-unix/X0 ]; then
        log "xorg socket ready after ${wait_s}s"
        break
    fi
    sleep 1
done

if [ ! -e /tmp/.X11-unix/X0 ]; then
    log "ERROR: xorg socket never appeared"
    log "xorg alive: $(kill -0 "$XORG_PID" 2>/dev/null && echo yes || echo no)"
    exit 1
fi

log "--- starting sway on X11 backend ---"
exec runuser -u mados -- env \
    DISPLAY=:0 \
    WLR_BACKENDS=x11 \
    XDG_CURRENT_DESKTOP=sway \
    XDG_SESSION_TYPE=wayland \
    XDG_RUNTIME_DIR=/run/user/1000 \
    HOME=/home/mados \
    USER=mados \
    sway >> "$LOG" 2>&1
LAUNCHER
    chmod +x /usr/local/bin/mados-start-desktop

    cat > /etc/systemd/system/mados-autologin.service << 'EOF'
[Unit]
Description=mados autologin to sway
After=systemd-user-sessions.service
Conflicts=getty@tty1.service
Before=getty@tty1.service

[Service]
Type=simple
ExecStartPre=/usr/bin/systemctl stop getty@tty1.service
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
StandardInput=tty
StandardOutput=journal
StandardError=journal
ExecStart=/usr/local/bin/mados-start-desktop
Restart=on-failure
RestartSec=5
TimeoutStopSec=10s

[Install]
WantedBy=graphical.target
WantedBy=multi-user.target
EOF

    ln -sf /etc/systemd/system/mados-autologin.service /etc/systemd/system/display-manager.service
    systemctl disable getty@tty1.service 2>/dev/null || true
    systemctl mask getty@tty1.service 2>/dev/null || true
    systemctl unmask getty@tty2.service 2>/dev/null || true
    systemctl enable getty@tty2.service
    systemctl enable mados-autologin.service

    echo "  → Configured autologin + desktop startup"
    echo "  → Logs: /var/log/mados-desktop.log"
    echo "  → Sway backend: X11 (no DRM assumption)"
    echo "  → VT policy: tty1=graphics, tty2=system/login"

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_autologin_sway
fi
