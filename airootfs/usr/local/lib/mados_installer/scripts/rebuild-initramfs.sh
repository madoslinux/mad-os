#!/bin/bash
# madOS Initramfs Rebuild Script
set -e

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms plymouth block filesystems keyboard fsck)/' /etc/mkinitcpio.conf

cat > /etc/mkinitcpio.d/linux.preset <<'EOFPRESET'
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default' 'fallback')

default_image="/boot/initramfs-linux.img"

fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
EOFPRESET

rm -f /etc/mkinitcpio.conf.d/archiso.conf

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

mkinitcpio -P
echo "  Initramfs rebuilt successfully"
