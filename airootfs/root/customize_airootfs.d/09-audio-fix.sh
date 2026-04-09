#!/usr/bin/env bash
# 09-audio-fix.sh - Fix "Dummy Output" and ensure audio services start
set -euo pipefail

# Fixed WirePlumber rule for all sound cards (HDA, AC97, etc)
setup_wireplumber_fix() {
    local config_dir="/etc/wireplumber/wireplumber.conf.d"
    mkdir -p "${config_dir}"

    cat > "${config_dir}/50-audio-profile.conf" << 'EOF'
# Force analog stereo profile for all ALSA cards
# This fixes "Dummy Output" in QEMU and physical hardware
monitor.alsa.rules = [
  {
    matches = [
      { "device.name" = "~alsa_card.*" }
    ]
    actions = {
      update-props = {
        "device.profile-priority" = 3000
        "device.profile" = "output:analog-stereo+input:analog-stereo"
      }
    }
  }
]
EOF
    chmod 644 "${config_dir}/50-audio-profile.conf"

    # Also add to skel for installed systems
    mkdir -p /etc/skel/.config/wireplumber/wireplumber.conf.d
    cp "${config_dir}/50-audio-profile.conf" /etc/skel/.config/wireplumber/wireplumber.conf.d/
}

# Script to restart audio services if Dummy Output is detected
setup_audio_health_check() {
    local health_check_file="/usr/local/bin/mados-audio-health-check"
    
    cat > "${health_check_file}" << 'HEOF'
#!/usr/bin/env bash
set -euo pipefail

log() { echo "[mados-audio] $*" >&2; }

# Wait for audio services to be ready
sleep 3

# Check if we have a real sink (not dummy)
if pactl info 2>/dev/null | grep -q "Dummy Output"; then
    log "Dummy output detected! Attempting to fix audio..."
    
    # Restart audio services
    systemctl --user restart wireplumber 2>/dev/null || true
    sleep 1
    systemctl --user restart pipewire pipewire-pulse 2>/dev/null || true
    sleep 3
    
    # Check if fixed
    if pactl info 2>/dev/null | grep -q "Dummy Output"; then
        log "Audio fix failed. Trying alternative..."
        # Force reload of sound modules
        modprobe -r snd_ac97_codec 2>/dev/null || true
        modprobe snd_ac97_codec 2>/dev/null || true
        sleep 2
        systemctl --user restart wireplumber 2>/dev/null || true
    fi
    
    if pactl info 2>/dev/null | grep -q "Dummy Output"; then
        log "Audio still broken. Check hardware."
    else
        log "Audio fixed!"
    fi
fi
HEOF
    chmod +x "${health_check_file}"
}

# Initialize audio services for the live user
setup_audio_services() {
    # Enable services for all new users (systemd user mode)
    mkdir -p /etc/systemd/user/default.target.wants
    ln -sf /usr/lib/systemd/user/pipewire.service /etc/systemd/user/default.target.wants/pipewire.service
    ln -sf /usr/lib/systemd/user/pipewire-pulse.service /etc/systemd/user/default.target.wants/pipewire-pulse.service
    ln -sf /usr/lib/systemd/user/wireplumber.service /etc/systemd/user/default.target.wants/wireplumber.service

    # Also enable in skel for installed systems
    mkdir -p /etc/skel/.config/systemd/user/default.target.wants
    ln -sf /usr/lib/systemd/user/pipewire.service /etc/skel/.config/systemd/user/default.target.wants/pipewire.service
    ln -sf /usr/lib/systemd/user/pipewire-pulse.service /etc/skel/.config/systemd/user/default.target.wants/pipewire-pulse.service
    ln -sf /usr/lib/systemd/user/wireplumber.service /etc/skel/.config/systemd/user/default.target.wants/wireplumber.service
}

# Force load audio modules at boot
setup_audio_modules() {
    local modprobe_dir="/etc/modprobe.d"
    mkdir -p "${modprobe_dir}"
    
    # Force AC97 codec to load (fixes QEMU audio)
    cat > "${modprobe_dir}/mados-audio.conf" << 'EOF'
# Force loading of AC97 audio codec for QEMU compatibility
options snd-ac97-codec power_save=0 power_save_controller=N
EOF
    
    # Ensure snd_intel8x0 loads for AC97 HDA emulation
    echo "snd_intel8x0" > /etc/modules-load.d/mados-audio.conf
    echo "snd_ac97_codec" >> /etc/modules-load.d/mados-audio.conf
    echo "snd_intel8x0m" >> /etc/modules-load.d/mados-audio.conf 2>/dev/null || true
}

# Create an autostart script that runs health check for all users
setup_autostart() {
    mkdir -p /etc/xdg/autostart
    cat > /etc/xdg/autostart/mados-audio-health.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=madOS Audio Health Check
Comment=Fix audio if Dummy Output detected
Exec=/usr/local/bin/mados-audio-health-check
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
    chmod 644 /etc/xdg/autostart/mados-audio-health.desktop

    # Also add to skel
    mkdir -p /etc/skel/.config/autostart
    cp /etc/xdg/autostart/mados-audio-health.desktop /etc/skel/.config/autostart/
}

main() {
    setup_wireplumber_fix
    setup_audio_health_check
    setup_audio_services
    setup_audio_modules
    setup_autostart
}

main "$@"