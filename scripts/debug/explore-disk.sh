#!/usr/bin/env bash
# Recovery script to explore installed disk

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DISK_FILE="${REPO_ROOT}/out/madOS-test.qcow2"

if [ ! -f "$DISK_FILE" ]; then
    echo "Disk not found: $DISK_FILE"
    exit 1
fi

echo "=== Exploring installed disk ==="

# Check partition layout
echo -e "\n=== Partition table ==="
fdisk -l "$DISK_FILE" 2>/dev/null || parted -s "$DISK_FILE" print

# Mount partitions using guestfish or fallback to manual
echo -e "\n=== Checking for mountable partitions ==="

# Try to mount using guestfish if available
if command -v guestfish &>/dev/null; then
    echo "Using guestfish to explore..."
    guestfish --ro -a "$DISK_FILE" run : list-partitions
else
    echo "guestfish not available, trying nbdkit..."
    if command -v nbdkit &>/dev/null; then
        echo "Using nbdkit..."
        sudo nbdkit -f file "$DISK_FILE" --readonly &
        NBD_PID=$!
        sleep 2
        # Try to list partitions
        lsblk /dev/nbd0 2>/dev/null || echo "Could not list nbd devices"
        kill $NBD_PID 2>/dev/null
    else
        echo "Neither guestfish nor nbdkit available"
        echo "Install with: pacman -S libguestfs"
    fi
fi

echo -e "\n=== Alternative: check disk image contents ==="
# Check if we can read the filesystem directly
echo "Trying to mount partition 3 (root) directly..."
sudo mkdir -p /mnt/mados-test
sudo nbdkit -f file "$DISK_FILE" --readonly -s &
NBD_PID=$!
sleep 2

if [ -b /dev/nbd0p3 ]; then
    echo "Mounting /dev/nbd0p3..."
    sudo mount /dev/nbd0p3 /mnt/mados-test
    echo "=== /boot contents ==="
    ls -la /mnt/mados-test/boot/ 2>/dev/null || echo "No /boot"
    echo "=== /boot/EFI contents ==="
    ls -la /mnt/mados-test/boot/EFI/ 2>/dev/null || echo "No /boot/EFI"
    echo "=== Log file ==="
    cat /mnt/mados-test/var/log/mados-install.log 2>/dev/null || echo "No log found"
    sudo umount /mnt/mados-test
else
    echo "Partition /dev/nbd0p3 not found, trying other partitions..."
    for p in /dev/nbd0p*; do
        [ -b "$p" ] && echo "Found: $p"
    done
fi

kill $NBD_PID 2>/dev/null
sudo rmdir /mnt/mados-test 2>/dev/null

echo "=== Done ==="
