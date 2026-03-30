#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="madOS"
iso_label="MADOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="madOS Project"
iso_application="madOS - AI-Orchestrated Arch Linux"
_iso_tag="$(git -C "$(dirname "$0")" tag -l --sort=-version:refname 'v*' 2>/dev/null | head -1)"
_iso_tag="${_iso_tag:-dev}"
iso_version="${_iso_tag}"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
            'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '17')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '-zstd-level=17')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/profile.d/mados-welcome.sh"]="0:0:755"
  ["/etc/profile.d/mados-media-links.sh"]="0:0:755"
  ["/etc/sudoers.d/99-opencode-nopasswd"]="0:0:440"
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/root/customize_airootfs.sh.bak"]="0:0:644"
  ["/root/customize_airootfs.d/"]="0:0:755"
  ["/root/customize_airootfs.d/00-kernel.sh"]="0:0:755"
  ["/root/customize_airootfs.d/01-initramfs.sh"]="0:0:755"
  ["/root/customize_airootfs.d/02-themes.sh"]="0:0:755"
  ["/root/customize_airootfs.d/03-apps.sh"]="0:0:755"
  ["/root/customize_airootfs.d/04-cleanup.sh"]="0:0:755"
  ["/root/customize_airootfs.d/run-parts.sh"]="0:0:755"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.zlogin"]="0:0:644"
  ["/root/.gnupg"]="0:0:700"
  ["/home/mados"]="1000:1000:750"
  ["/home/mados/.zlogin"]="1000:1000:644"
  ["/home/mados/.automated_script.sh"]="1000:1000:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/mados-fb-resolution.sh"]="0:0:755"
  ["/usr/local/bin/mados-audio-init.sh"]="0:0:755"
  ["/usr/local/bin/mados-audio-quality.sh"]="0:0:755"
  ["/usr/local/bin/setup-opencode.sh"]="0:0:755"
  ["/usr/local/bin/setup-nvm.sh"]="0:0:755"
  ["/usr/local/bin/setup-ollama.sh"]="0:0:755"
  ["/usr/local/bin/toggle-demo-mode.sh"]="0:0:755"

  ["/usr/local/bin/mados-debug"]="0:0:755"
  ["/usr/local/bin/detect-legacy-hardware"]="0:0:755"
  ["/usr/local/bin/cage-greeter"]="0:0:755"
  ["/usr/local/bin/sway-session"]="0:0:755"
  ["/usr/local/bin/hyprland-session"]="0:0:755"
  ["/usr/local/bin/start-hyprland"]="0:0:755"
  ["/usr/local/bin/select-compositor"]="0:0:755"
  ["/usr/local/bin/mados-logs"]="0:0:755"
  ["/usr/local/bin/mados-install-yay"]="0:0:755"
  ["/usr/local/bin/mados-wallpaper-hyprland"]="0:0:755"
  ["/usr/local/bin/mados-hyprland-wallpaper"]="0:0:755"
  ["/usr/local/bin/mados-sway-wallpaper"]="0:0:755"
  ["/usr/local/bin/mados-sway-wallpapers"]="0:0:755"
  ["/usr/local/bin/mados-sway-wallpaper-set"]="0:0:755"
  ["/usr/local/bin/mados-sway-workspace-cycle"]="0:0:755"
  ["/usr/local/bin/mados-hyprland-wallpaper-set"]="0:0:755"
  ["/usr/local/bin/mados-hyprland-workspace-cycle"]="0:0:755"
  ["/usr/local/lib/mados-media-helper.sh"]="0:0:755"
  ["/usr/local/bin/mados-persistence"]="0:0:755"
  ["/usr/local/bin/mados-installer-autostart"]="0:0:755"

  # XDG autostart for desktop environments
  ["/etc/xdg/autostart/nm-applet.desktop"]="0:0:644"

  ["/usr/local/bin/mados-vbox-guest"]="0:0:755"
  ["/usr/local/bin/mados-persist-sync.sh"]="0:0:755"
  ["/usr/local/bin/mados-persist-detect.sh"]="0:0:755"
  ["/usr/local/bin/mados-ventoy-setup.sh"]="0:0:755"
  ["/usr/local/bin/mados-timezone-detect.sh"]="0:0:755"
  ["/usr/local/bin/mados-gamepad-wm"]="0:0:755"
  ["/usr/local/bin/mados-squeekboard"]="0:0:755"
  ["/usr/local/bin/mados-firstboot-recover"]="0:0:755"
  ["/usr/local/bin/mados-health-check"]="0:0:755"
  ["/usr/local/bin/mados-hide-steam"]="0:0:755"
  ["/usr/local/bin/mados-help"]="0:0:755"
  ["/usr/local/bin/mados-power"]="0:0:755"
  ["/usr/local/bin/mados-logs"]="0:0:755"

  # mados-chwd (hardware detection)
  ["/usr/local/bin/mados-chwd"]="0:0:755"
  ["/usr/local/bin/mados-kernel-select"]="0:0:755"
  ["/usr/local/bin/mados-gpu-detect"]="0:0:755"

  # mados-welcome and tools
  ["/usr/local/bin/mados-welcome"]="0:0:755"
  ["/usr/local/bin/mados-rate-mirrors"]="0:0:755"
  ["/usr/local/bin/mados-select-desktop"]="0:0:755"

  # mados-updater (installed dynamically from github.com/madkoding/mados-updater)
  ["/usr/share/libalpm/hooks/pre-update.hook"]="0:0:644"
  ["/usr/local/bin/snapper-pre-update"]="0:0:755"

  ["/etc/mados/"]="0:0:755"
  ["/usr/share/grub/themes/mados/theme.txt"]="0:0:644"
  ["/usr/share/grub/themes/mados/logo.png"]="0:0:644"
  ["/usr/share/icons/hicolor/48x48/apps/mados-wallpaper.png"]="0:0:644"

  # UFW Firewall
  ["/etc/ufw/ufw.conf"]="0:0:644"
  ["/etc/ufw/user.rules"]="0:0:600"
  ["/etc/ufw/user6.rules"]="0:0:600"
  ["/etc/systemd/system/ufw.service"]="0:0:644"
  ["/etc/systemd/system/multi-user.target.wants/ufw.service"]="0:0:644"

  # Sudoers configuration
  ["/etc/sudoers"]="0:0:440"
  ["/etc/sudoers.d/gufw"]="0:0:440"

  # GUFW Firewall GUI
  ["/usr/local/bin/gufw"]="0:0:755"
  ["/usr/local/bin/gufw-pkexec"]="0:0:755"
  ["/etc/polkit-1/rules.d/49-nopasswd_gufw.rules"]="0:0:644"
  ["/usr/share/applications/gufw-sudo.desktop"]="0:0:644"
  ["/usr/share/polkit-1/actions/org.archlinux.pkexec.gufw.policy"]="0:0:644"

  # UFW enable at login
  ["/etc/profile.d/mados-ufw-enable.sh"]="0:0:755"

  # Security hardening
  ["/etc/sysctl.d/99-security.conf"]="0:0:644"

  # USBGuard
  ["/etc/usbguard/usbguard-daemon.conf"]="0:0:644"
  ["/etc/usbguard/rules.conf"]="0:0:600"
  ["/etc/usbguard/usbguard-notify.sh"]="0:0:755"
  ["/etc/systemd/system/usbguard.service"]="0:0:644"

  # RKHunter (disabled by default)
  ["/etc/rkhunter.conf"]="0:0:644"
  ["/etc/systemd/system/rkhunter.service"]="0:0:644"
  ["/etc/systemd/system/rkhunter.timer"]="0:0:644"
  ["/etc/systemd/system/rkhunter.timer.d/"]="0:0:755"
  ["/etc/systemd/system/rkhunter.timer.d/skip-live.conf"]="0:0:644"
  ["/etc/systemd/system/rkhunter.service.d/"]="0:0:755"
  ["/etc/systemd/system/rkhunter.service.d/skip-live.conf"]="0:0:644"

  # USBGuard (disabled by default)
  ["/etc/systemd/system/usbguard.service.d/"]="0:0:755"
  ["/etc/systemd/system/usbguard.service.d/skip-live.conf"]="0:0:644"

  # Fail2Ban
  ["/etc/fail2ban/jail.local"]="0:0:644"

  # Security notifications
  ["/etc/profile.d/mados-security-notify.sh"]="0:0:755"

  # Framebuffer and GPU early services
  ["/etc/systemd/system/mados-gpu-wait.service"]="0:0:644"
  ["/usr/local/bin/mados-gpu-wait.sh"]="0:0:755"
  ["/etc/systemd/system/mados-fb-resolution.service"]="0:0:644"

  # Btrfs Snapper
  ["/usr/local/bin/mados-snapper"]="0:0:755"
  ["/usr/local/bin/mados-autoinstall"]="0:0:755"
  ["/etc/systemd/system/mados-snapper.service"]="0:0:644"
  ["/etc/systemd/system/mados-snapper.timer"]="0:0:644"
  ["/etc/snapper/configs/root"]="0:0:644"

  # Network wait service
  ["/usr/local/bin/mados-network-wait.sh"]="0:0:755"
  ["/etc/systemd/system/network-wait-online.service"]="0:0:644"
)
