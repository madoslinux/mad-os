#!/usr/bin/env bash
# create-kernel-symlinks.sh
# Deprecated helper kept for compatibility.
# mkinitcpio generation is handled inside customize_airootfs modules.

set -euo pipefail

echo "This helper is deprecated and no longer required."
echo "Use: airootfs/root/customize_airootfs.d/01-initramfs.sh"
