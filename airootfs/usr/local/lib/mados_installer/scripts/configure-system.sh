#!/bin/bash
# madOS System Configuration Script
# This script is executed inside the chroot environment during installation
set -e

USERNAME="${1:-}"
TIMEZONE="${2:-}"
LOCALE="${3:-}"
HOSTNAME="${4:-}"
DISK="${5:-}"
VENTOY_PERSIST_SIZE="${6:-4096}"

if [ -z "$USERNAME" ] || [ -z "$TIMEZONE" ] || [ -z "$LOCALE" ] || [ -z "$HOSTNAME" ] || [ -z "$DISK" ]; then
    echo "ERROR: Missing required arguments"
    echo "Usage: $0 <username> <timezone> <locale> <hostname> <disk> [ventoy_persist_size]"
    exit 1
fi

# ── Initialize pacman keyring ────────────────────────────────────────────────
echo '  Initializing pacman keyring...'
[ -d /etc/pacman.d/gnupg ] && rm -rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
echo '  Pacman keyring initialized'

echo "[PROGRESS 1/8] Setting timezone and locale..."
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc 2>/dev/null || true

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "$LOCALE" UTF-8 >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

echo '[PROGRESS 2/8] Creating user account...'
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# ── Clean up live ISO artifacts ─────────────────────────────────────────
rm -rf /etc/systemd/system/getty@tty1.service.d

for svc in \
    livecd-talk.service \
    livecd-alsa-unmuter.service \
    pacman-init.service \
    etc-pacman.d-gnupg.mount \
    choose-mirror.service \
    mados-persistence-detect.service \
    mados-persist-sync.service \
    mados-ventoy-setup.service \
    mados-timezone.service \
    mados-installer-autostart.service; do
    systemctl disable "$svc" 2>/dev/null || true
    rm -f "/etc/systemd/system/$svc"
done

find /etc/systemd/system -type l ! -exec test -e {} \; -delete 2>/dev/null || true

if id mados &>/dev/null; then
    userdel -r mados 2>/dev/null || userdel mados 2>/dev/null || true
    rm -rf /home/mados
fi

rm -f /etc/sudoers.d/99-opencode-nopasswd

useradd -m -G wheel,audio,video,storage -s /usr/bin/zsh "$USERNAME"
passwd -d "$USERNAME" 2>/dev/null || true

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: /usr/local/bin/opencode,/usr/local/bin/ollama,/usr/bin/pacman,/usr/bin/systemctl" > /etc/sudoers.d/opencode-nopasswd
chmod 440 /etc/sudoers.d/opencode-nopasswd

echo '[PROGRESS 3/8] Installing GRUB bootloader...'
if [ -d /sys/firmware/efi ]; then
    echo "==> Detected UEFI boot mode"
    
    if ! mountpoint -q /sys/firmware/efi/efivars 2>/dev/null; then
        mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null || true
    fi

    echo 'GRUB_DISABLE_SHIM_LOCK=true' >> /etc/default/grub

    if ! grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=madOS --recheck 2>&1; then
        echo "WARN: grub-install bootloader-id failed (NVRAM may be read-only)"
    fi
    
    if ! grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck 2>&1; then
        echo "ERROR: GRUB UEFI --removable install failed!"
        exit 1
    fi
    
    if [ ! -f /boot/EFI/BOOT/BOOTX64.EFI ]; then
        echo "ERROR: /boot/EFI/BOOT/BOOTX64.EFI was not created!"
        exit 1
    fi

    SECURE_BOOT=0
    if [ -f /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c ]; then
        SB_VAL=$(od -An -t u1 -j4 -N1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null | tr -d ' ')
        [ "$SB_VAL" = "1" ] && SECURE_BOOT=1
    fi

    if [ "$SECURE_BOOT" = "1" ]; then
        echo "==> Secure Boot is ENABLED – setting up sbctl signing"
        sbctl create-keys 2>/dev/null || echo "WARN: sbctl keys may already exist"

        SETUP_MODE=0
        if [ -f /sys/firmware/efi/efivars/SetupMode-8be4df61-93ca-11d2-aa0d-00e098032b8c ]; then
            SM_VAL=$(od -An -t u1 -j4 -N1 /sys/firmware/efi/efivars/SetupMode-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null | tr -d ' ')
            [ "$SM_VAL" = "1" ] && SETUP_MODE=1
        fi

        if [ "$SETUP_MODE" = "1" ]; then
            echo "==> Firmware is in Setup Mode – enrolling Secure Boot keys"
            sbctl enroll-keys --microsoft 2>&1 || echo "WARN: Could not enroll keys automatically"
        else
            echo "==> Firmware is NOT in Setup Mode"
            echo "    After first reboot, enter UEFI firmware settings and either:"
            echo "    1) Disable Secure Boot, or"
            echo "    2) Put firmware in Setup Mode, reboot to madOS, then run: sudo sbctl enroll-keys --microsoft"
        fi

        for f in /boot/EFI/BOOT/BOOTX64.EFI /boot/EFI/madOS/grubx64.efi /boot/vmlinuz-linux; do
            if [ -f "$f" ]; then
                echo "    Signing $f"
                sbctl sign -s "$f" 2>&1 || echo "WARN: Could not sign $f"
            fi
        done

        mkdir -p /etc/pacman.d/hooks
        cat > /etc/pacman.d/hooks/99-sbctl-sign.hook <<'EOFHOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux
Target = linux-lts
Target = linux-zen
Target = grub

[Action]
Description = Signing EFI binaries for Secure Boot...
When = PostTransaction
Exec = /usr/bin/sbctl sign-all
Depends = sbctl
EOFHOOK
    else
        echo "==> Secure Boot is disabled – skipping sbctl signing"
    fi
else
    echo "==> Detected BIOS boot mode"
    if ! grub-install --target=i386-pc --recheck "$DISK" 2>&1; then
        echo "ERROR: GRUB BIOS install failed!"
        exit 1
    fi
fi

echo '[PROGRESS 4/8] Configuring GRUB...'
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="zswap.enabled=0 splash quiet"/' /etc/default/grub
sed -i 's/GRUB_DISTRIBUTOR="Arch"/GRUB_DISTRIBUTOR="madOS"/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

if [ ! -f /boot/grub/grub.cfg ]; then
    echo "ERROR: grub.cfg was not generated!"
    exit 1
fi

echo '[PROGRESS 5/8] Setting up Plymouth boot splash...'
/usr/local/lib/mados_installer/scripts/setup-plymouth.sh

echo '[PROGRESS 6/8] Rebuilding initramfs (this takes a while)...'
/usr/local/lib/mados_installer/scripts/rebuild-initramfs.sh

echo '[PROGRESS 7/8] Enabling essential services...'
passwd -l root

systemctl enable NetworkManager
systemctl enable systemd-resolved
systemctl enable earlyoom
systemctl enable systemd-timesyncd
systemctl enable greetd
systemctl enable bluetooth 2>/dev/null || true
systemctl enable plymouth-quit-wait.service 2>/dev/null || true
systemctl enable mados-hardware-config.service 2>/dev/null || true

systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

echo '[PROGRESS 8/8] Applying system configuration...'
/usr/local/lib/mados_installer/scripts/apply-configuration.sh "$USERNAME" "$LOCALE" "$VENTOY_PERSIST_SIZE"

echo "Graphical environment verification complete."
