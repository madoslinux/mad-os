#!/bin/bash
# madOS System Configuration Script
# This script is executed inside the chroot environment during installation
set -euo pipefail

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo '  Initializing pacman keyring...'
[ -d /etc/pacman.d/gnupg ] && rm -rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
echo '  Pacman keyring initialized'

"$SCRIPT_DIR/setup-locale.sh" "$TIMEZONE" "$LOCALE"
"$SCRIPT_DIR/setup-user.sh" "$USERNAME" "$HOSTNAME"
"$SCRIPT_DIR/clean-live-artifacts.sh" "$USERNAME"
"$SCRIPT_DIR/setup-bootloader.sh" "$DISK"
"$SCRIPT_DIR/configure-grub.sh"
"$SCRIPT_DIR/setup-plymouth.sh"
"$SCRIPT_DIR/rebuild-initramfs.sh"
"$SCRIPT_DIR/enable-services.sh"
"$SCRIPT_DIR/apply-configuration.sh" "$USERNAME" "$LOCALE" "$VENTOY_PERSIST_SIZE"

echo "System configuration complete."
