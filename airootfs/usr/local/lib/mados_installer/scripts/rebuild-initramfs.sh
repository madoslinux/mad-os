#!/bin/bash
# madOS Initramfs Rebuild Script
set -e

if grep -q '^HOOKS=.*systemd.*plymouth' /etc/mkinitcpio.conf; then
    echo "  HOOKS already contain systemd and plymouth"
else
    sed -i 's/^HOOKS=(base systemd udev/HOOKS=(base systemd udev/' /etc/mkinitcpio.conf 2>/dev/null || true
    sed -i 's/^HOOKS=(base udev /HOOKS=(base systemd udev /' /etc/mkinitcpio.conf
    sed -i 's/plymouth block filesystems keyboard/plymouth block filesystems keyboard fsck/' /etc/mkinitcpio.conf
fi

if [ ! -s /boot/vmlinuz-linux ] || [ ! -r /boot/vmlinuz-linux ]; then
    echo '  Kernel missing before mkinitcpio! Recovering...'
    for kdir in /usr/lib/modules/*/; do
        if [ -r "${kdir}vmlinuz" ]; then
            cp "${kdir}vmlinuz" /boot/vmlinuz-linux
            echo "  Recovered kernel from ${kdir}vmlinuz"
            break
        fi
    done
fi

if [ ! -s /boot/vmlinuz-linux ] || [ ! -r /boot/vmlinuz-linux ]; then
    echo '  ERROR: Could not find kernel image. Reinstalling linux package...'
    pacman -Sy --noconfirm linux || { echo 'FATAL: Failed to install kernel'; exit 1; }
fi

rm -f /etc/mkinitcpio.conf.d/archiso.conf

mkinitcpio -P
echo "  Initramfs rebuilt successfully"
