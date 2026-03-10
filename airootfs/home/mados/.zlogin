# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

~/.automated_script.sh

# Auto-start compositor on TTY1 for live environment
# Uses Hyprland on modern hardware, Sway on legacy/software-rendering hardware
# Boot parameters to control behavior:
#   mados_safe_mode - Force Sway with maximum compatibility
#   mados_no_graphic - Skip auto-start of graphical session (debug mode)
#   nomodeset - Force safe graphics mode (kernel parameter)
if [ -z "${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
    # Debug mode: skip graphical session auto-start
    if grep -q 'mados_no_graphic' /proc/cmdline 2>/dev/null; then
        echo "mados_no_graphic detected - skipping graphical session auto-start" >&2
        logger -p user.info -t mados-session "Debug mode: graphical session disabled"
        echo "To start manually, run: sway" >&2
        return 0
    fi
    
    # Check for safe mode boot parameter
    if grep -q 'mados_safe_mode' /proc/cmdline 2>/dev/null; then
        echo "Safe mode requested - launching Sway directly" >&2
        logger -p user.info -t mados-session "Safe mode requested via kernel parameter"
        exec /usr/local/bin/mados-safe-mode
    fi
    # Copy skel configs to home on first boot (if not already present)
    # This ensures all config files and directories exist
    if [ -d /etc/skel ]; then
        for item in /etc/skel/.*; do
            item_name=$(basename "$item")
            # Skip . and .. and hidden directories starting with .
            if [ "$item_name" = "." ] || [ "$item_name" = ".." ]; then
                continue
            fi
            # Don't overwrite if already exists
            dest="$HOME/$item_name"
            if [ ! -e "$dest" ]; then
                cp -r "$item" "$dest" 2>/dev/null && chown -R 1000:1000 "$dest"
            fi
        done
    fi
    if [ ! -d ~/Pictures ]; then
        cp -r /etc/skel/Pictures ~/ 2>/dev/null
    fi
    # Export environment for Wayland
    export XDG_SESSION_TYPE=wayland
    export MOZ_ENABLE_WAYLAND=1

    # Select compositor based on hardware capabilities
    COMPOSITOR="hyprland"
    if [ -x /usr/local/bin/select-compositor ]; then
        COMPOSITOR=$(/usr/local/bin/select-compositor)
    fi

    if [ "$COMPOSITOR" = "sway" ]; then
        # Software rendering: use Sway with pixman renderer
        export XDG_CURRENT_DESKTOP=sway
        echo "Software rendering enabled - using Sway" >&2
        logger -p user.info -t mados-session "Compositor selected: sway (software rendering)"
        export WLR_RENDERER=pixman
        export WLR_NO_HARDWARE_CURSORS=1
        export LIBGL_ALWAYS_SOFTWARE=1
        export MESA_GL_VERSION_OVERRIDE=3.3
        # GTK: disable Vulkan renderer to avoid GPU probe errors
        export GSK_RENDERER=cairo
        # Chromium: force software rendering on legacy hardware
        export CHROMIUM_FLAGS="${CHROMIUM_FLAGS:-} --disable-gpu"

        # VM DRM workarounds
        if systemd-detect-virt --vm --quiet 2>/dev/null; then
            export WLR_DRM_NO_ATOMIC=1
            export WLR_DRM_NO_MODIFIERS=1
            export WLR_NO_HARDWARE_CURSORS=1
            # VM performance: generate optimized sway config drop-in
            VM_CONF="/etc/sway/config.d/99-vm-performance.conf"
            if [ ! -f "$VM_CONF" ]; then
                sudo mkdir -p /etc/sway/config.d
                sudo tee "$VM_CONF" > /dev/null << 'VMCONF'
# Auto-generated VM performance optimizations
# Note: wallpaper is managed by mados-sway-wallpapers, not here
gaps inner 0
gaps outer 0
VMCONF
            fi
        fi

        exec sway
    else
        # Hardware rendering: use Hyprland
        export XDG_CURRENT_DESKTOP=Hyprland
        echo "Hardware rendering enabled - using Hyprland" >&2
        logger -p user.info -t mados-session "Compositor selected: hyprland (hardware rendering)"
        # VM with 3D acceleration: generate Hyprland optimizations for smoother input
        if systemd-detect-virt --vm --quiet 2>/dev/null; then
            cat > ~/.config/hypr/vm-performance.conf << 'VMCONF'
# Auto-generated VM performance optimizations
# Disables animations and effects for smoother mouse/input in VirtualBox/VMware/QEMU
cursor {
    no_hardware_cursors = true
}
animations {
    enabled = false
}
decoration {
    blur {
        enabled = false
    }
    shadow {
        enabled = false
    }
    rounding = 0
}
misc {
    vfr = true
}
render {
    direct_scanout = false
}
VMCONF
        fi
        # Try Hyprland via start-hyprland wrapper, fall back to Sway if it fails
        start-hyprland || {
            logger -p user.warning -t mados-session "Hyprland failed, falling back to Sway"
            echo "Hyprland failed - falling back to Sway with software rendering" >&2
            export XDG_CURRENT_DESKTOP=sway
            export WLR_RENDERER=pixman
            export WLR_NO_HARDWARE_CURSORS=1
            export LIBGL_ALWAYS_SOFTWARE=1
            export MESA_GL_VERSION_OVERRIDE=3.3
            # GTK: disable Vulkan renderer to avoid GPU probe errors
            export GSK_RENDERER=cairo
            export CHROMIUM_FLAGS="${CHROMIUM_FLAGS:-} --disable-gpu"
            if systemd-detect-virt --vm --quiet 2>/dev/null; then
                export WLR_DRM_NO_ATOMIC=1
                export WLR_DRM_NO_MODIFIERS=1
                # VM performance: generate optimized sway config drop-in
                VM_CONF="/etc/sway/config.d/99-vm-performance.conf"
                if [ ! -f "$VM_CONF" ]; then
                    sudo mkdir -p /etc/sway/config.d
                    sudo tee "$VM_CONF" > /dev/null << 'VMCONF'
# Auto-generated VM performance optimizations
# Note: wallpaper is managed by mados-sway-wallpapers, not here
gaps inner 0
gaps outer 0
VMCONF
                fi
            fi
            exec sway
        }
    fi
fi
