"""
madOS Installer - Disk Partitioning Module

Handles disk partitioning, formatting, and mounting operations.
"""

import glob as globmod
import os
import subprocess
import time

from ..config import DEMO_MODE
from ..utils import log_message, set_progress


def get_partition_prefix(disk):
    """Get partition prefix (nvme/mmcblk use 'p' separator)"""
    return f"{disk}p" if "nvme" in disk or "mmcblk" in disk else disk


def step_partition_disk(app, disk, separate_home, disk_size_gb):
    """Step 1: Partition the disk. Returns (boot_part, root_part, home_part)."""
    set_progress(app, 0.05, "Partitioning disk...")
    log_message(app, f"Partitioning {disk}...")

    if DEMO_MODE:
        for msg in [
            "unmount/swapoff",
            "wipefs",
            "parted mklabel gpt",
            "parted mkpart bios_boot",
            "parted set bios_grub",
            "parted mkpart EFI",
            "parted set esp",
        ]:
            log_message(app, f"[DEMO] Simulating {msg}...")
            time.sleep(0.3)
    else:
        log_message(app, f"Unmounting existing partitions on {disk}...")
        for part in globmod.glob(f"{disk}[0-9]*") + globmod.glob(f"{disk}p[0-9]*"):
            subprocess.run(["swapoff", part], stderr=subprocess.DEVNULL, check=False)
            subprocess.run(["umount", "-l", part], stderr=subprocess.DEVNULL, check=False)
        time.sleep(1)
        subprocess.run(["sgdisk", "--zap-all", disk], check=False)
        subprocess.run(["wipefs", "-a", "-f", disk], check=True)
        subprocess.run(["parted", "-s", disk, "mklabel", "gpt"], check=True)
        subprocess.run(["parted", "-s", disk, "mkpart", "bios_boot", "1MiB", "2MiB"], check=True)
        subprocess.run(["parted", "-s", disk, "set", "1", "bios_grub", "on"], check=True)
        subprocess.run(["parted", "-s", disk, "mkpart", "EFI", "fat32", "2MiB", "1GiB"], check=True)
        subprocess.run(["parted", "-s", disk, "set", "2", "esp", "on"], check=True)

    create_root_partition(app, disk, separate_home, disk_size_gb)

    if not DEMO_MODE:
        log_message(app, "Waiting for partition devices...")
        subprocess.run(["partprobe", disk], check=False)
        subprocess.run(["udevadm", "settle", "--timeout=10"], check=False)
        time.sleep(2)
    else:
        time.sleep(0.5)

    part_prefix = get_partition_prefix(disk)
    return (
        f"{part_prefix}2",
        f"{part_prefix}3",
        f"{part_prefix}4" if separate_home else None,
    )


def create_root_partition(app, disk, separate_home, disk_size_gb):
    """Create root (and optionally home) partition."""
    if separate_home:
        root_end = "51GiB" if disk_size_gb < 128 else "61GiB"
        if DEMO_MODE:
            log_message(app, f"[DEMO] Simulating parted mkpart root 1GiB-{root_end}...")
            time.sleep(0.5)
            log_message(app, "[DEMO] Simulating parted mkpart home...")
            time.sleep(0.5)
        else:
            subprocess.run(
                ["parted", "-s", disk, "mkpart", "root", "ext4", "1GiB", root_end],
                check=True,
            )
            subprocess.run(
                ["parted", "-s", disk, "mkpart", "home", "ext4", root_end, "100%"],
                check=True,
            )
    else:
        if DEMO_MODE:
            log_message(app, "[DEMO] Simulating parted mkpart root 1GiB-100%...")
            time.sleep(0.5)
        else:
            subprocess.run(
                ["parted", "-s", disk, "mkpart", "root", "ext4", "1GiB", "100%"],
                check=True,
            )


def step_format_partitions(app, boot_part, root_part, home_part, separate_home):
    """Step 2: Format partitions."""
    set_progress(app, 0.15, "Formatting partitions...")
    log_message(app, "Formatting partitions...")

    if DEMO_MODE:
        format_partitions_demo(app, boot_part, root_part, home_part, separate_home)
    else:
        format_partitions_real(boot_part, root_part, home_part, separate_home)


def format_partitions_demo(app, boot_part, root_part, home_part, separate_home):
    """Demo mode partition formatting."""
    log_message(app, f"[DEMO] Simulating mkfs.fat {boot_part}...")
    time.sleep(0.5)
    log_message(app, f"[DEMO] Simulating mkfs.ext4 {root_part}...")
    time.sleep(0.5)
    if separate_home and home_part:
        log_message(app, f"[DEMO] Simulating mkfs.ext4 {home_part}...")
        time.sleep(0.5)


def format_partitions_real(boot_part, root_part, home_part, separate_home):
    """Real partition formatting."""
    partitions = [("EFI", boot_part), ("root", root_part)]
    if separate_home and home_part:
        partitions.append(("home", home_part))
    for part_name, part_dev in partitions:
        if not os.path.exists(part_dev):
            raise RuntimeError(f"Partition device {part_dev} ({part_name}) does not exist!")
    subprocess.run(["mkfs.fat", "-F32", boot_part], check=True)
    subprocess.run(["mkfs.ext4", "-F", root_part], check=True)
    if separate_home and home_part:
        subprocess.run(["mkfs.ext4", "-F", home_part], check=True)


def step_mount_filesystems(app, boot_part, root_part, home_part, separate_home):
    """Step 3: Mount filesystems."""
    set_progress(app, 0.20, "Mounting filesystems...")
    log_message(app, "Mounting filesystems...")

    if DEMO_MODE:
        log_message(app, f"[DEMO] Simulating mount {root_part} /mnt...")
        time.sleep(0.5)
        log_message(app, "[DEMO] Simulating mkdir /mnt/boot...")
        time.sleep(0.3)
        log_message(app, f"[DEMO] Simulating mount {boot_part} /mnt/boot...")
        time.sleep(0.5)
        if separate_home and home_part:
            log_message(app, "[DEMO] Simulating mkdir /mnt/home...")
            time.sleep(0.3)
            log_message(app, f"[DEMO] Simulating mount {home_part} /mnt/home...")
            time.sleep(0.5)
    else:
        subprocess.run(["mount", root_part, "/mnt"], check=True)
        subprocess.run(["mkdir", "-p", "/mnt/boot"], check=True)
        subprocess.run(["mount", boot_part, "/mnt/boot"], check=True)
        if separate_home and home_part:
            subprocess.run(["mkdir", "-p", "/mnt/home"], check=True)
            subprocess.run(["mount", home_part, "/mnt/home"], check=True)
