#!/bin/bash
# madOS - Clean Live ISO Artifacts
# Removes live-specific services, users, and files during installation
set -euo pipefail

USERNAME="${1:-}"

echo "Cleaning live ISO artifacts..."

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

if [ -n "$USERNAME" ] && id "$USERNAME" &>/dev/null; then
    userdel -r "$USERNAME" 2>/dev/null || userdel "$USERNAME" 2>/dev/null || true
    rm -rf "/home/$USERNAME"
fi

rm -f /etc/sudoers.d/99-opencode-nopasswd

echo "  Live artifacts cleaned"
