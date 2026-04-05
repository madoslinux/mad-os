#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Auto-start compositor on TTY1 (live ISO only — installed system uses lightdm)
# Uses Hyprland on modern hardware, Sway on legacy/software-rendering hardware
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && [ -d /run/archiso ]; then
  SESSION_LOG="$HOME/.cache/mados-session.log"
  mkdir -p "$HOME/.cache"
  {
    printf '\n[%s] tty1 autostart begin\n' "$(date -Iseconds)"
  } >> "$SESSION_LOG"

  export XDG_SESSION_TYPE=wayland
  export MOZ_ENABLE_WAYLAND=1
  export XCURSOR_THEME=Adwaita
  export XCURSOR_SIZE=16

  # Hardware policy:
  # - Hyprland only on hardware-accelerated systems
  # - Sway on legacy / software-rendering systems
  COMPOSITOR="hyprland"
  if [ -x /usr/local/bin/select-compositor ]; then
      COMPOSITOR=$(/usr/local/bin/select-compositor)
      logger -p user.info -t mados-session "Detected compositor: ${COMPOSITOR}"
  fi

  if [ "$COMPOSITOR" = "sway" ]; then
      # Software rendering: use Sway with pixman renderer
      export XDG_CURRENT_DESKTOP=sway
      echo "Software rendering enabled - using Sway"
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

      echo "[$(date -Iseconds)] launching sway-session (software path)" >> "$SESSION_LOG"
      if /usr/local/bin/sway-session; then
          exit 0
      fi
      logger -p user.err -t mados-session "sway-session failed on software path; keeping tty shell"
      echo "[$(date -Iseconds)] sway-session failed on software path" >> "$SESSION_LOG"
      echo "Failed to launch Sway session; staying in TTY shell for debugging"
      return 0
  else
      # Hardware rendering: use Hyprland
      export XDG_CURRENT_DESKTOP=Hyprland
      echo "Hardware rendering enabled - using Hyprland"
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
      # Try Hyprland via start-hyprland wrapper, fall back to Sway only on runtime failure
      echo "[$(date -Iseconds)] launching start-hyprland" >> "$SESSION_LOG"
      start-hyprland || {
          logger -p user.warning -t mados-session "Hyprland failed, falling back to Sway"
          echo "Hyprland failed - falling back to Sway with software rendering"
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
          echo "[$(date -Iseconds)] launching sway-session fallback" >> "$SESSION_LOG"
          if /usr/local/bin/sway-session; then
              exit 0
          fi
          logger -p user.err -t mados-session "sway-session fallback failed; keeping tty shell"
          echo "[$(date -Iseconds)] sway-session fallback failed" >> "$SESSION_LOG"
          echo "Failed to launch fallback Sway session; staying in TTY shell for debugging"
          return 0
      }
  fi
fi
