"""
madOS Installer - File Copier Module

Handles copying files, scripts, and desktop configuration.
"""

import glob as globmod
import os
import subprocess
import time

from gi.repository import Gtk

from ..config import DEMO_MODE, NORD_FROST
from ..utils import log_message, set_progress

MNT_USR_LOCAL_BIN = "/mnt/usr/local/bin/"
SCRIPTS_DIR = "/usr/local/lib/mados_installer/scripts"
SKEL_DIR = "/mnt/etc/skel/"


def copy_item(src, dst):
    """Copy file or directory if it exists.

    Prints a warning when the source is missing or the copy command
    fails, so installation issues are visible in stdout/stderr rather
    than silently swallowed.
    """
    if not os.path.exists(src):
        print(f"  WARNING: {src} not found, skipping copy")
        return
    result = subprocess.run(["cp", "-a", src, dst], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  WARNING: failed to copy {src} → {dst}: {result.stderr.strip()}")


def ensure_kernel_in_target(app):
    """Ensure /mnt/boot/vmlinuz-linux exists before entering the chroot."""
    target_kernel = "/mnt/boot/vmlinuz-linux"

    if (
        os.path.isfile(target_kernel)
        and os.access(target_kernel, os.R_OK)
        and os.path.getsize(target_kernel) > 0
    ):
        return

    log_message(app, "  Kernel not found in target /boot, copying from live system...")

    for vmlinuz in sorted(globmod.glob("/usr/lib/modules/*/vmlinuz"), reverse=True):
        if os.path.isfile(vmlinuz) and os.access(vmlinuz, os.R_OK):
            subprocess.run(["cp", vmlinuz, target_kernel], check=True)
            log_message(app, f"  Copied kernel from {vmlinuz}")
            return

    if os.path.isfile("/boot/vmlinuz-linux") and os.access("/boot/vmlinuz-linux", os.R_OK):
        subprocess.run(["cp", "/boot/vmlinuz-linux", target_kernel], check=True)
        log_message(app, "  Copied kernel from /boot/vmlinuz-linux")
        return

    for vmlinuz in sorted(globmod.glob("/mnt/usr/lib/modules/*/vmlinuz"), reverse=True):
        if os.path.isfile(vmlinuz) and os.access(vmlinuz, os.R_OK):
            subprocess.run(["cp", vmlinuz, target_kernel], check=True)
            log_message(app, f"  Copied kernel from {vmlinuz}")
            return

    log_message(
        app,
        "  WARNING: Could not find kernel in live system, chroot will attempt recovery",
    )


def step_copy_live_files(app):
    """Copy files from live ISO to installed system."""
    set_progress(app, 0.51, "Copying boot splash assets...")
    log_message(app, "Copying Plymouth boot splash assets...")
    subprocess.run(["mkdir", "-p", "/mnt/usr/share/plymouth/themes/mados"], check=True)
    copy_item(
        "/usr/share/plymouth/themes/mados/logo.png",
        "/mnt/usr/share/plymouth/themes/mados/",
    )
    copy_item(
        "/usr/share/plymouth/themes/mados/dot.png",
        "/mnt/usr/share/plymouth/themes/mados/",
    )

    set_progress(app, 0.52, "Copying desktop configuration files...")
    log_message(app, "Copying desktop configuration files...")
    for item in [
        ".config",
        "Pictures",
        ".bash_profile",
        ".zshrc",
        ".bashrc",
        ".gtkrc-2.0",
    ]:
        copy_item(f"/etc/skel/{item}", f"{SKEL_DIR}{item}")

    subprocess.run(["mkdir", "-p", "/mnt/etc/gtk-3.0"], check=False)
    copy_item("/etc/gtk-3.0/settings.ini", "/mnt/etc/gtk-3.0/")

    copy_item("/usr/share/themes/Nordic", "/mnt/usr/share/themes/")
    copy_item("/etc/skel/.oh-my-zsh", SKEL_DIR)

    for binary in ["opencode", "ollama"]:
        copy_item(f"/usr/local/bin/{binary}", MNT_USR_LOCAL_BIN)

    step_copy_scripts(app)
    step_copy_desktop_files(app)


def step_copy_scripts(app):
    """Copy system scripts and launchers."""
    set_progress(app, 0.53, "Copying system scripts...")
    log_message(app, "Copying system scripts...")
    subprocess.run(["mkdir", "-p", "/mnt/usr/local/bin"], check=False)

    scripts = [
        "detect-legacy-hardware",
        "cage-greeter",
        "sway-session",
        "hyprland-session",
        "start-hyprland",
        "select-compositor",
        "mados-audio-quality.sh",
    ]
    for script in scripts:
        copy_item(f"/usr/local/bin/{script}", MNT_USR_LOCAL_BIN)

    for launcher in [
        "mados-photo-viewer",
        "mados-pdf-viewer",
        "mados-equalizer",
        "mados-debug",
    ]:
        copy_item(f"/usr/local/bin/{launcher}", MNT_USR_LOCAL_BIN)

    subprocess.run(["mkdir", "-p", "/mnt/usr/local/lib"], check=False)
    for lib in ["mados_photo_viewer", "mados_pdf_viewer", "mados_equalizer"]:
        copy_item(f"/usr/local/lib/{lib}", "/mnt/usr/local/lib/")

    subprocess.run(["mkdir", "-p", "/mnt/usr/local/lib/mados_installer/scripts"], check=False)
    for script in ["configure-system.sh", "setup-plymouth.sh", "rebuild-initramfs.sh", "apply-configuration.sh"]:
        copy_item(f"/usr/local/lib/mados_installer/scripts/{script}", f"/mnt/usr/local/lib/mados_installer/scripts/{script}")

    for script in scripts + [
        "mados-photo-viewer",
        "mados-pdf-viewer",
        "mados-equalizer",
        "mados-debug",
    ]:
        subprocess.run(["chmod", "+x", f"{MNT_USR_LOCAL_BIN}{script}"], check=False)

    for s in ["configure-system.sh", "setup-plymouth.sh", "rebuild-initramfs.sh", "apply-configuration.sh"]:
        subprocess.run(["chmod", "+x", f"/mnt/usr/local/lib/mados_installer/scripts/{s}"], check=False)


def step_copy_desktop_files(app):
    """Copy session files."""
    set_progress(app, 0.54, "Copying session files...")
    log_message(app, "Copying session files...")
    subprocess.run(["mkdir", "-p", "/mnt/usr/share/wayland-sessions"], check=False)
    copy_item("/usr/share/wayland-sessions/sway.desktop", "/mnt/usr/share/wayland-sessions/")
    copy_item(
        "/usr/share/wayland-sessions/hyprland.desktop",
        "/mnt/usr/share/wayland-sessions/",
    )
    
    subprocess.run(["mkdir", "-p", "/mnt/etc/greetd"], check=False)
    copy_item("/etc/greetd/regreet.css", "/mnt/etc/greetd/")

    subprocess.run(["mkdir", "-p", "/mnt/usr/share/backgrounds"], check=False)
    for wp_file in globmod.glob("/usr/share/backgrounds/*"):
        copy_item(wp_file, "/mnt/usr/share/backgrounds/")

    subprocess.run(["mkdir", "-p", "/mnt/usr/share/applications"], check=False)
    for desktop in [
        "mados-photo-viewer.desktop",
        "mados-pdf-viewer.desktop",
        "mados-equalizer.desktop",
    ]:
        copy_item(f"/usr/share/applications/{desktop}", "/mnt/usr/share/applications/")

    copy_item("/usr/share/fonts/dseg", "/mnt/usr/share/fonts/")
