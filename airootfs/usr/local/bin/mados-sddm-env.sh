#!/usr/bin/env bash
set -o pipefail

detect_legacy() {
    if /usr/local/bin/detect-legacy-hardware 2>/dev/null; then
        return 0
    fi
    return 1
}

create_minimal_soft_theme() {
    local theme_dir="/usr/share/sddm/themes/minimal-soft"
    mkdir -p "$theme_dir"

    cat > "${theme_dir}/Main.qml" << 'QML'
import QtQuick 2.0
Rectangle {
    id: root
    width: Screen.width || 800
    height: Screen.height || 600
    color: "#060810"
    Text {
        anchors.centerIn: parent
        color: "#e8e4f0"
        font.pixelSize: 24
        text: "Loading..."
    }
}
QML

    cat > "${theme_dir}/theme.conf" << 'EOF'
[Theme]
Current=minimal-soft
EOF
}

create_xvfb_service() {
    local svc_dir="/etc/systemd/system"
    local xvfb_svc="${svc_dir}/xvfb.service"

    cat > "$xvfb_svc" << 'EOF'
[Unit]
Description=X Virtual Framebuffer
After=local-fs.target
Before=sddm.service
PartOf=sddm.service

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "$xvfb_svc"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload 2>/dev/null || true
        systemctl enable xvfb.service 2>/dev/null || true
    fi
}

create_sddm_dropin() {
    local dropin_dir="/etc/systemd/system/sddm.service.d"
    local dropin_file="${dropin_dir}/software-render.conf"

    mkdir -p "$dropin_dir"

    cat > "$dropin_file" << 'EOF'
[Service]
Environment="LIBGL_ALWAYS_SOFTWARE=1"
Environment="QT_QUICK_BACKEND=software"
Environment="QSG_RENDER_LOOP=basic"
Environment="MESA_GL_VERSION_OVERRIDE=3.3"
Environment="QT_WAYLAND_DISABLE_HARDWARE=1"
Environment="DISPLAY=:0"
Environment="WAYLAND_DISPLAY="
EOF

    cat > "${dropin_dir}/x11-backend.conf" << 'EOF'
[General]
Backend=X11
SessionExec=/usr/bin/Xvfb :0 -nolisten local
EOF

    chmod 644 "$dropin_file"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload 2>/dev/null || true
    fi
}

remove_xvfb_service() {
    local svc_dir="/etc/systemd/system/xvfb.service"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl stop xvfb.service 2>/dev/null || true
        systemctl disable xvfb.service 2>/dev/null || true
    fi
    rm -f "$svc_dir"
}

remove_sddm_dropin() {
    local dropin_dir="/etc/systemd/system/sddm.service.d"
    local dropin_file="${dropin_dir}/software-render.conf"
    local x11_file="${dropin_dir}/x11-backend.conf"

    rm -f "$dropin_file" "$x11_file"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload 2>/dev/null || true
    fi
}

switch_theme_to_soft() {
    local sddm_conf_dir="/etc/sddm.conf.d"
    local theme_conf="${sddm_conf_dir}/theme.conf"

    mkdir -p "$sddm_conf_dir"

    cat > "$theme_conf" << 'EOF'
[Theme]
Current=minimal-soft

[General]
InputMethod=
EOF
}

switch_theme_to_hardware() {
    local sddm_conf_dir="/etc/sddm.conf.d"
    local theme_conf="${sddm_conf_dir}/theme.conf"

    cat > "$theme_conf" << 'EOF'
[Theme]
Current=pixel-night-city

[General]
InputMethod=
EOF
}

main() {
    if detect_legacy; then
        echo "Legacy hardware detected: enabling SDDM software rendering"
        create_minimal_soft_theme
        create_xvfb_service
        create_sddm_dropin
        switch_theme_to_soft
    else
        echo "Modern hardware detected: SDDM will use hardware rendering"
        remove_xvfb_service
        remove_sddm_dropin
        switch_theme_to_hardware
    fi
}

main "$@"
