#!/bin/bash
# madOS Final Configuration Script
set -e

USERNAME="${1:-}"
LOCALE="${2:-}"
VENTOY_PERSIST_SIZE="${3:-4096}"

if [[ -z "$USERNAME" ]]; then
    echo "ERROR: Username not provided" >&2
    exit 1
fi

LOCALE_KB_MAP=(
    ["en_US.UTF-8"]="us"
    ["es_AR.UTF-8"]="latam"
    ["es_ES.UTF-8"]="es"
    ["pt_BR.UTF-8"]="br"
    ["fr_FR.UTF-8"]="fr"
    ["de_DE.UTF-8"]="de"
    ["it_IT.UTF-8"]="it"
)

KB_LAYOUT="${LOCALE_KB_MAP[$LOCALE]:-us}"

cat > /etc/os-release <<EOF
NAME="madOS"
PRETTY_NAME="madOS (Arch Linux)"
ID=mados
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
HOME_URL="https://github.com/madkoding/mad-os"
DOCUMENTATION_URL="https://wiki.archlinux.org/"
SUPPORT_URL="https://bbs.archlinux.org/"
BUG_REPORT_URL="https://gitlab.archlinux.org/groups/archlinux/-/issues"
PRIVACY_POLICY_URL="https://terms.archlinux.org/docs/privacy-policy/"
LOGO=archlinux-logo
EOF

mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/wifi-backend.conf <<EOF
[device]
wifi.backend=iwd
EOF

cat > /etc/sysctl.d/99-extreme-low-ram.conf <<EOF
vm.vfs_cache_pressure = 200
vm.swappiness = 5
vm.dirty_ratio = 5
vm.dirty_background_ratio = 3
vm.min_free_kbytes = 16384
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.core.rmem_max = 262144
net.core.wmem_max = 262144
EOF

cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<'EOFGREETD'
[terminal]
vt = 1

[default_session]
command = "/usr/local/bin/cage-greeter"
user = "greeter"
EOFGREETD

# Create PAM configuration for greetd
mkdir -p /etc/pam.d
cat > /etc/pam.d/greetd <<'EOFPAM'
#%PAM-1.0

auth     requisite     pam_nologin.so
auth     required      pam_succeed_if.so user != root quiet_success
auth     substack      password-auth

account  substack      password-auth
account  required      pam_nologin.so

password substack      password-auth

session  optional      pam_keyinit.so force revoke
session  required      pam_loginuid.so
session  substack      password-auth
session  optional      pam_systemd.so
session  required      pam_env.so
EOFPAM

cat > /etc/greetd/regreet.toml <<'EOFREGREET'
[background]
path = "/usr/share/backgrounds/mad-os-wallpaper.png"
fit = "Cover"

[env]
LIBSEAT_BACKEND = "logind"

[GTK]
application_prefer_dark_theme = true
theme_name = "Nordic"
cursor_theme_name = "Nordzy-dark"
icon_theme_name = "Nordzy-dark"
font_name = "Cantarell 11"

[commands]
reboot = [ "systemctl", "reboot" ]
poweroff = [ "systemctl", "poweroff" ]

[sessions]
available = [
    "/usr/share/wayland-sessions/sway.desktop",
    "/usr/share/wayland-sessions/hyprland.desktop"
]
default = "/usr/share/wayland-sessions/sway.desktop"

[css]
path = "/etc/greetd/regreet.css"
EOFREGREET

if [ -f /etc/greetd/regreet.css ]; then
    cp /etc/greetd/regreet.css /etc/greetd/regreet.css.installed
    chown greeter:greeter /etc/greetd/regreet.css.installed
fi

chown -R greeter:greeter /etc/greetd
chmod 755 /etc/greetd
chmod 644 /etc/greetd/config.toml /etc/greetd/regreet.toml
chmod 644 /etc/greetd/regreet.css 2>/dev/null || true

usermod -aG video,input greeter 2>/dev/null || echo "Note: greeter user group modification skipped"

mkdir -p /var/cache/regreet
chown greeter:greeter /var/cache/regreet
chmod 750 /var/cache/regreet
mkdir -p /var/lib/greetd
chown greeter:greeter /var/lib/greetd

# Disable getty@tty1 to avoid conflict with greetd
systemctl disable getty@tty1.service 2>/dev/null || true

mkdir -p /etc/systemd/system/greetd.service.d
cat > /etc/systemd/system/greetd.service.d/override.conf <<'EOFOVERRIDE'
[Unit]
After=plymouth-quit-wait.service systemd-logind.service
Wants=plymouth-quit-wait.service

[Service]
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_CURRENT_DESKTOP=sway
Stdout=null
Stderr=journal
EOFOVERRIDE

install -d -o "$USERNAME" -g "$USERNAME" /home/"$USERNAME"/.config/{sway,hypr,waybar,foot,wofi,gtk-3.0,gtk-4.0}
install -d -o "$USERNAME" -g "$USERNAME" /home/"$USERNAME"/{Documents,Downloads,Music,Videos,Desktop,Templates,Public}
install -d -o "$USERNAME" -g "$USERNAME" /home/"$USERNAME"/Pictures/{Wallpapers,Screenshots}
cp -r /etc/skel/.config/* /home/"$USERNAME"/.config/ 2>/dev/null || true
cp -r /etc/skel/Pictures/* /home/"$USERNAME"/Pictures/ 2>/dev/null || true
cp /etc/skel/.gtkrc-2.0 /home/"$USERNAME"/.gtkrc-2.0 2>/dev/null || true

mkdir -p /usr/share/music /usr/share/video
cp /usr/share/music/* /home/"$USERNAME"/Music/ 2>/dev/null || true
cp /usr/share/video/* /home/"$USERNAME"/Videos/ 2>/dev/null || true

cp /etc/profile.d/mados-media-links.sh /etc/profile.d/ 2>/dev/null || true

chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

if [[ -f /home/"$USERNAME"/.config/sway/config ]]; then
    sed -i "s/xkb_layout \"es\"/xkb_layout \"$KB_LAYOUT\"/" /home/"$USERNAME"/.config/sway/config
elif [[ -f /etc/skel/.config/sway/config ]]; then
    sed -i "s/xkb_layout \"es\"/xkb_layout \"$KB_LAYOUT\"/" /etc/skel/.config/sway/config
fi

if [[ -f /home/"$USERNAME"/.config/hypr/hyprland.conf ]]; then
    sed -i "s/kb_layout = es/kb_layout = $KB_LAYOUT/" /home/"$USERNAME"/.config/hypr/hyprland.conf
elif [[ -f /etc/skel/.config/hypr/hyprland.conf ]]; then
    sed -i "s/kb_layout = es/kb_layout = $KB_LAYOUT/" /etc/skel/.config/hypr/hyprland.conf
fi

if [[ ! -f /home/"$USERNAME"/.bash_profile ]]; then
    cp /etc/skel/.bash_profile /home/"$USERNAME"/.bash_profile 2>/dev/null || true
fi
chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.bash_profile

if [ -f /etc/skel/.zshrc ]; then
    cp /etc/skel/.zshrc /home/"$USERNAME"/.zshrc 2>/dev/null || true
    chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.zshrc
fi

mkdir -p /etc/mados
cat > /etc/mados/ventoy-persist.conf << EOFVENTOY
# madOS Persistence Configuration
# Read by persistence detection at boot

# Preferred persistence size in MB (used as reference for Ventoy .dat files)
VENTOY_PERSIST_SIZE_MB=$VENTOY_PERSIST_SIZE

# Minimum free space required on USB in MB
MIN_FREE_SPACE_MB=512
EOFVENTOY
chmod 644 /etc/mados/ventoy-persist.conf

rm -f /root/.automated_script.sh /root/.zlogin

mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/sway-desktop-override.hook <<'EOFHOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = sway

[Action]
Description = Customizing Sway session for madOS...
When = PostTransaction
Depends = sed
Exec = /usr/bin/sed -i -e 's|^Exec=.*|Exec=/usr/local/bin/sway-session|' -e 's|^Comment=.*|Comment=madOS Sway session with hardware detection|' /usr/share/wayland-sessions/sway.desktop
EOFHOOK

cat > /etc/pacman.d/hooks/hyprland-desktop-override.hook <<'EOFHOOK2'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyprland

[Action]
Description = Customizing Hyprland session for madOS...
When = PostTransaction
Depends = sed
Exec = /usr/bin/sed -i -e 's|^Exec=.*|Exec=/usr/local/bin/hyprland-session|' -e 's|^Comment=.*|Comment=madOS Hyprland session|' /usr/share/wayland-sessions/hyprland.desktop
EOFHOOK2

echo "Verifying graphical environment components..."
GRAPHICAL_OK=1
for bin in cage regreet sway; do
    if command -v "$bin" &>/dev/null; then
        echo "  ✓ $bin found: $(command -v "$bin")"
    else
        echo "  ✗ $bin NOT found — graphical login may fail"
        GRAPHICAL_OK=0
    fi
done

for script in /usr/local/bin/cage-greeter /usr/local/bin/sway-session /usr/local/bin/hyprland-session /usr/local/bin/start-hyprland /usr/local/bin/select-compositor; do
    if [ -x "$script" ]; then
        echo "  ✓ $script is executable"
    elif [ -f "$script" ]; then
        echo "  ✗ $script exists but is not executable — fixing..."
        chmod +x "$script"
    else
        echo "  ✗ $script NOT found — graphical login may fail"
        GRAPHICAL_OK=0
    fi
done

if [ -f /etc/greetd/config.toml ]; then
    echo "  ✓ greetd config exists"
else
    echo "  ✗ greetd config NOT found — graphical login may fail"
    GRAPHICAL_OK=0
fi

if [ -f /etc/greetd/regreet.toml ]; then
    echo "  ✓ regreet config exists"
else
    echo "  ✗ regreet.toml NOT found — greeter UI may fail"
    GRAPHICAL_OK=0
fi

for session_file in /usr/share/wayland-sessions/sway.desktop /usr/share/wayland-sessions/hyprland.desktop; do
    if [ -f "$session_file" ]; then
        if grep -q "/usr/local/bin/" "$session_file"; then
            echo "  ✓ $session_file has madOS session script"
        else
            echo "  ⚠ $session_file exists but Exec= may not point to madOS script — fixing..."
            session_name=$(basename "$session_file" .desktop)
            if [ -x "/usr/local/bin/${session_name}-session" ]; then
                sed -i "s|^Exec=.*|Exec=/usr/local/bin/${session_name}-session|" "$session_file"
                echo "    Fixed: Exec=/usr/local/bin/${session_name}-session"
            fi
        fi
    else
        echo "  ✗ $session_file NOT found — session may not appear in greeter"
    fi
done

if systemctl is-enabled greetd.service &>/dev/null; then
    echo "  ✓ greetd.service is enabled"
else
    echo "  ✗ greetd.service is NOT enabled — enabling..."
    systemctl enable greetd.service 2>/dev/null || true
fi

systemctl enable getty@tty2.service 2>/dev/null || true

systemctl enable mados-post-install.service 2>/dev/null || true
echo "  ✓ mados-post-install.service enabled (first boot only)"

if [ "$GRAPHICAL_OK" -eq 0 ]; then
    echo "  ⚠ Some graphical components are missing. Enabling getty@tty1 as fallback..."
    systemctl enable getty@tty1.service 2>/dev/null || true
fi
