#!/bin/bash
# madOS - Configure GRUB
set -euo pipefail

echo "[4/8] Configuring GRUB..."

sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="zswap.enabled=0 splash quiet plymouth.use-simpledrm=0"/' /etc/default/grub
sed -i 's/GRUB_DISTRIBUTOR="Arch"/GRUB_DISTRIBUTOR="madOS"/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

if [ ! -f /boot/grub/grub.cfg ]; then
    echo "ERROR: grub.cfg was not generated!"
    exit 1
fi

echo "  GRUB configured"
