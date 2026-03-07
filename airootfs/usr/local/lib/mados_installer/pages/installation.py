"""
madOS Installer - Installation progress page and install logic
"""

import glob as globmod
import os
import re
import subprocess
import time
import threading

from gi.repository import Gtk, GLib

from ..config import (
    DEMO_MODE,
    PACKAGES,
    RSYNC_EXCLUDES,
    POST_COPY_CLEANUP,
    ARCHISO_PACKAGES,
    NORD_FROST,
    LOCALE_KB_MAP,
    TIMEZONES,
    LOCALE_MAP,
)
from ..utils import log_message, set_progress, show_error, save_log_to_file, LOG_FILE

MNT_USR_LOCAL_BIN = "/mnt/usr/local/bin/"
SCRIPTS_DIR = "/usr/local/lib/mados_installer/scripts"



from .base import create_page_header


def create_installation_page(app):
    """Installation progress page with spinner, progress bar and log"""
    page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    page.get_style_context().add_class("page-container")
    page.set_valign(Gtk.Align.CENTER)

    content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    content.set_margin_start(30)
    content.set_margin_end(30)
    content.set_margin_top(10)
    content.set_margin_bottom(14)

    # Spinner
    app.install_spinner = Gtk.Spinner()
    app.install_spinner.get_style_context().add_class("install-spinner")
    app.install_spinner.set_halign(Gtk.Align.CENTER)
    app.install_spinner.set_margin_top(8)
    content.pack_start(app.install_spinner, False, False, 0)

    # Title
    title = Gtk.Label()
    title.set_markup(f'<span size="15000" weight="bold">{app.t("installing")}</span>')
    title.set_halign(Gtk.Align.CENTER)
    content.pack_start(title, False, False, 0)

    # Status
    app.status_label = Gtk.Label()
    app.status_label.set_markup(
        f'<span size="10000" foreground="{NORD_FROST["nord8"]}">{app.t("preparing")}</span>'
    )
    app.status_label.set_halign(Gtk.Align.CENTER)
    content.pack_start(app.status_label, False, False, 0)

    # Progress bar
    app.progress_bar = Gtk.ProgressBar()
    app.progress_bar.set_show_text(True)
    app.progress_bar.set_margin_top(4)
    app.progress_bar.set_margin_start(16)
    app.progress_bar.set_margin_end(16)
    content.pack_start(app.progress_bar, False, False, 0)

    # Log toggle link
    app.log_toggle = Gtk.EventBox()
    app.log_toggle.set_halign(Gtk.Align.CENTER)
    app.log_toggle.set_margin_top(8)
    toggle_label = Gtk.Label()
    toggle_label.set_markup(
        f'<span size="9000" foreground="{NORD_FROST["nord8"]}">{app.t("show_log")}</span>'
    )
    toggle_label.get_style_context().add_class("log-toggle")
    app.log_toggle.add(toggle_label)
    app.log_toggle.connect("button-press-event", lambda w, e: _toggle_log(app))
    content.pack_start(app.log_toggle, False, False, 0)

    # Log viewer (hidden by default)
    log_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    log_card.get_style_context().add_class("content-card")
    log_card.set_margin_top(4)
    log_card.set_no_show_all(True)
    app.log_card = log_card

    scrolled = Gtk.ScrolledWindow()
    scrolled.set_min_content_height(120)
    scrolled.set_max_content_height(180)
    app.log_scrolled = scrolled

    app.log_buffer = Gtk.TextBuffer()
    log_view = Gtk.TextView(buffer=app.log_buffer)
    log_view.set_editable(False)
    log_view.set_monospace(True)
    log_view.set_left_margin(12)
    log_view.set_right_margin(12)
    log_view.set_top_margin(8)
    log_view.set_bottom_margin(8)
    scrolled.add(log_view)

    log_card.pack_start(scrolled, True, True, 0)
    content.pack_start(log_card, True, True, 0)

    page.pack_start(content, True, True, 0)
    app.notebook.append_page(page, Gtk.Label(label="Installing"))


def _toggle_log(app):
    """Toggle visibility of the log console"""
    if app.log_card.get_visible():
        app.log_card.hide()
        label = app.log_toggle.get_child()
        label.set_markup(
            f'<span size="9000" foreground="{NORD_FROST["nord8"]}">{app.t("show_log")}</span>'
        )
    else:
        # show() bypasses no_show_all; then show children that were never shown
        app.log_card.show()
        app.log_card.foreach(lambda w: w.show_all())
        label = app.log_toggle.get_child()
        label.set_markup(
            f'<span size="9000" foreground="{NORD_FROST["nord8"]}">{app.t("hide_log")}</span>'
        )


def on_start_installation(app):
    """Start the installation process"""
    app.notebook.next_page()
    app.install_spinner.start()

    thread = threading.Thread(target=_run_installation, args=(app,))
    thread.daemon = True
    thread.start()


SKEL_DIR = "/mnt/etc/skel/"


def _get_partition_prefix(disk):
    """Get partition prefix (nvme/mmcblk use 'p' separator)"""
    return f"{disk}p" if "nvme" in disk or "mmcblk" in disk else disk


def _step_partition_disk(app, disk, separate_home, disk_size_gb):
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

    _create_root_partition(app, disk, separate_home, disk_size_gb)

    if not DEMO_MODE:
        log_message(app, "Waiting for partition devices...")
        subprocess.run(["partprobe", disk], check=False)
        subprocess.run(["udevadm", "settle", "--timeout=10"], check=False)
        time.sleep(2)
    else:
        time.sleep(0.5)

    part_prefix = _get_partition_prefix(disk)
    return (
        f"{part_prefix}2",
        f"{part_prefix}3",
        f"{part_prefix}4" if separate_home else None,
    )


def _create_root_partition(app, disk, separate_home, disk_size_gb):
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


def _step_format_partitions(app, boot_part, root_part, home_part, separate_home):
    """Step 2: Format partitions."""
    set_progress(app, 0.15, "Formatting partitions...")
    log_message(app, "Formatting partitions...")

    if DEMO_MODE:
        _format_partitions_demo(app, boot_part, root_part, home_part, separate_home)
    else:
        _format_partitions_real(boot_part, root_part, home_part, separate_home)


def _format_partitions_demo(app, boot_part, root_part, home_part, separate_home):
    """Demo mode partition formatting."""
    log_message(app, f"[DEMO] Simulating mkfs.fat {boot_part}...")
    time.sleep(0.5)
    log_message(app, f"[DEMO] Simulating mkfs.ext4 {root_part}...")
    time.sleep(0.5)
    if separate_home and home_part:
        log_message(app, f"[DEMO] Simulating mkfs.ext4 {home_part}...")
        time.sleep(0.5)


def _format_partitions_real(boot_part, root_part, home_part, separate_home):
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


def _step_mount_filesystems(app, boot_part, root_part, home_part, separate_home):
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


def _copy_item(src, dst):
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


def _ensure_kernel_in_target(app):
    """Ensure /mnt/boot/vmlinuz-linux exists before entering the chroot.

    The archiso live system stores the kernel in the ISO boot structure,
    so ``/boot/vmlinuz-linux`` is typically absent from the live rootfs.
    After rsync, the target ``/mnt/boot/`` (EFI partition) may be missing
    the kernel image.  This helper copies it from the live system's
    ``/usr/lib/modules/*/vmlinuz`` (the canonical location installed by
    the ``linux`` package) so that both ``grub-mkconfig`` and
    ``mkinitcpio`` (with ``-P``) find it without needing a network download.
    """
    target_kernel = "/mnt/boot/vmlinuz-linux"

    # Already present and readable?
    if (
        os.path.isfile(target_kernel)
        and os.access(target_kernel, os.R_OK)
        and os.path.getsize(target_kernel) > 0
    ):
        return

    log_message(app, "  Kernel not found in target /boot, copying from live system...")

    # Try canonical location: /usr/lib/modules/<version>/vmlinuz
    for vmlinuz in sorted(globmod.glob("/usr/lib/modules/*/vmlinuz"), reverse=True):
        if os.path.isfile(vmlinuz) and os.access(vmlinuz, os.R_OK):
            subprocess.run(["cp", vmlinuz, target_kernel], check=True)
            log_message(app, f"  Copied kernel from {vmlinuz}")
            return

    # Fallback: try /boot/vmlinuz-linux from the live system
    if os.path.isfile("/boot/vmlinuz-linux") and os.access("/boot/vmlinuz-linux", os.R_OK):
        subprocess.run(["cp", "/boot/vmlinuz-linux", target_kernel], check=True)
        log_message(app, "  Copied kernel from /boot/vmlinuz-linux")
        return

    # Also try inside the target's own modules (rsync may have copied them)
    for vmlinuz in sorted(globmod.glob("/mnt/usr/lib/modules/*/vmlinuz"), reverse=True):
        if os.path.isfile(vmlinuz) and os.access(vmlinuz, os.R_OK):
            subprocess.run(["cp", vmlinuz, target_kernel], check=True)
            log_message(app, f"  Copied kernel from {vmlinuz}")
            return

    log_message(
        app,
        "  WARNING: Could not find kernel in live system, chroot will attempt recovery",
    )


def _step_copy_live_files(app):
    """Step 6: Copy files from live ISO to installed system."""
    set_progress(app, 0.51, "Copying boot splash assets...")
    log_message(app, "Copying Plymouth boot splash assets...")
    subprocess.run(["mkdir", "-p", "/mnt/usr/share/plymouth/themes/mados"], check=True)
    _copy_item(
        "/usr/share/plymouth/themes/mados/logo.png",
        "/mnt/usr/share/plymouth/themes/mados/",
    )
    _copy_item(
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
        _copy_item(f"/etc/skel/{item}", f"{SKEL_DIR}{item}")

    subprocess.run(["mkdir", "-p", "/mnt/etc/gtk-3.0"], check=False)
    _copy_item("/etc/gtk-3.0/settings.ini", "/mnt/etc/gtk-3.0/")

    _copy_item("/usr/share/themes/Nordic", "/mnt/usr/share/themes/")
    _copy_item("/etc/skel/.oh-my-zsh", SKEL_DIR)

    for binary in ["opencode", "ollama"]:
        _copy_item(f"/usr/local/bin/{binary}", MNT_USR_LOCAL_BIN)

    _step_copy_scripts(app)
    _step_copy_desktop_files(app)


def _step_copy_scripts(app):
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
        _copy_item(f"/usr/local/bin/{script}", MNT_USR_LOCAL_BIN)

    for launcher in [
        "mados-photo-viewer",
        "mados-pdf-viewer",
        "mados-equalizer",
        "mados-debug",
    ]:
        _copy_item(f"/usr/local/bin/{launcher}", MNT_USR_LOCAL_BIN)

    subprocess.run(["mkdir", "-p", "/mnt/usr/local/lib"], check=False)
    for lib in ["mados_photo_viewer", "mados_pdf_viewer", "mados_equalizer"]:
        _copy_item(f"/usr/local/lib/{lib}", "/mnt/usr/local/lib/")

    subprocess.run(["mkdir", "-p", "/mnt/usr/local/lib/mados_installer/scripts"], check=False)
    for script in ["configure-system.sh", "setup-plymouth.sh", "rebuild-initramfs.sh", "apply-configuration.sh"]:
        _copy_item(f"/usr/local/lib/mados_installer/scripts/{script}", f"/mnt/usr/local/lib/mados_installer/scripts/{script}")

    for script in scripts + [
        "mados-photo-viewer",
        "mados-pdf-viewer",
        "mados-equalizer",
        "mados-debug",
    ]:
        subprocess.run(["chmod", "+x", f"{MNT_USR_LOCAL_BIN}{script}"], check=False)

    for s in ["configure-system.sh", "setup-plymouth.sh", "rebuild-initramfs.sh", "apply-configuration.sh"]:
        subprocess.run(["chmod", "+x", f"/mnt/usr/local/lib/mados_installer/scripts/{s}"], check=False)


def _step_copy_desktop_files(app):
    """Copy session and desktop files."""
    set_progress(app, 0.54, "Copying session files...")
    log_message(app, "Copying session files...")
    subprocess.run(["mkdir", "-p", "/mnt/usr/share/wayland-sessions"], check=False)
    _copy_item("/usr/share/wayland-sessions/sway.desktop", "/mnt/usr/share/wayland-sessions/")
    _copy_item(
        "/usr/share/wayland-sessions/hyprland.desktop",
        "/mnt/usr/share/wayland-sessions/",
    )

    subprocess.run(["mkdir", "-p", "/mnt/usr/share/backgrounds"], check=False)
    # Copy ALL wallpapers for per-workspace random wallpaper support
    for wp_file in globmod.glob("/usr/share/backgrounds/*"):
        _copy_item(wp_file, "/mnt/usr/share/backgrounds/")

    subprocess.run(["mkdir", "-p", "/mnt/usr/share/applications"], check=False)
    for desktop in [
        "mados-photo-viewer.desktop",
        "mados-pdf-viewer.desktop",
        "mados-equalizer.desktop",
    ]:
        _copy_item(f"/usr/share/applications/{desktop}", "/mnt/usr/share/applications/")

    _copy_item("/usr/share/fonts/dseg", "/mnt/usr/share/fonts/")


def _run_installation(app):
    """Perform installation (runs in background thread).

    Partition, format, install packages via rsync, configure bootloader and
    essential services, verify graphical environment — all in a single pass.
    """
    try:
        data = app.install_data
        disk = data["disk"]
        separate_home = data["separate_home"]
        disk_size_gb = data["disk_size_gb"]

        # Step 1: Partition
        boot_part, root_part, home_part = _step_partition_disk(
            app, disk, separate_home, disk_size_gb
        )

        # Step 2: Format
        _step_format_partitions(app, boot_part, root_part, home_part, separate_home)

        # Step 3: Mount
        _step_mount_filesystems(app, boot_part, root_part, home_part, separate_home)

        # Step 4: Copy live system to target (uses rsync instead of
        # downloading packages, since they already live in the ISO)
        if DEMO_MODE:
            log_message(app, "[DEMO] Simulating system copy from live ISO...")
            set_progress(app, 0.21, "Copying system files...")
            time.sleep(0.5)
            log_message(app, "[DEMO] rsync / → /mnt/ ...")
            for pct in (25, 50, 75, 100):
                set_progress(app, 0.21 + 0.22 * pct / 100, f"Copying ({pct}%)...")
                time.sleep(0.3)
            log_message(app, "[DEMO] Cleaning archiso artifacts...")
            time.sleep(0.3)
            log_message(app, "[DEMO] System files copied")
            set_progress(app, 0.48, "System files copied")
            time.sleep(0.3)
        else:
            _rsync_rootfs_with_progress(app)

        # Step 4b: Ensure kernel image exists in target /boot
        # (archiso keeps the kernel in the ISO boot structure, not the rootfs)
        if not DEMO_MODE:
            _ensure_kernel_in_target(app)

        # Step 5: Generate fstab
        set_progress(app, 0.49, "Generating filesystem table...")
        log_message(app, "Generating fstab...")
        if DEMO_MODE:
            log_message(app, "[DEMO] Simulating genfstab -U /mnt...")
            time.sleep(0.5)
            log_message(app, "[DEMO] Would write fstab to /mnt/etc/fstab")
            time.sleep(0.5)
        else:
            result = subprocess.run(
                ["genfstab", "-U", "/mnt"], capture_output=True, text=True, check=True
            )
            with open("/mnt/etc/fstab", "w") as f:
                f.write(result.stdout)

        # Step 6: Configure system (Phase 1 only)
        set_progress(app, 0.50, "Preparing system configuration...")
        log_message(app, "Preparing Phase 1 configuration...")

        config_script = _build_config_script(data)

        if DEMO_MODE:
            log_message(app, "[DEMO] Would write configuration script to /mnt/root/configure.sh")
            time.sleep(0.5)
            log_message(app, "[DEMO] Configuration would include:")
            log_message(app, "[DEMO]   - Timezone setup")
            log_message(app, "[DEMO]   - Locale generation")
            log_message(app, "[DEMO]   - Hostname configuration")
            log_message(app, "[DEMO]   - User creation")
            log_message(app, "[DEMO]   - GRUB bootloader")
            log_message(app, "[DEMO]   - Graphical environment verification")
            time.sleep(1)
        else:
            fd = os.open("/mnt/root/configure.sh", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o700)
            with os.fdopen(fd, "w") as f:
                f.write(config_script)

            _step_copy_live_files(app)

        # Step 7: Run chroot configuration
        set_progress(app, 0.55, "Applying configurations...")
        log_message(app, "Running chroot configuration...")
        if DEMO_MODE:
            demo_steps = [
                (0.58, "Installing GRUB bootloader"),
                (0.64, "Enabling essential services..."),
                (0.70, "Rebuilding initramfs..."),
                (0.76, "Verifying graphical environment..."),
            ]
            log_message(app, "[DEMO] Simulating arch-chroot configuration...")
            for progress, desc in demo_steps:
                set_progress(app, progress, desc)
                log_message(app, f"[DEMO]   - {desc}")
                time.sleep(0.5)
        else:
            _run_chroot_with_progress(app)

        set_progress(app, 0.90, "Cleaning up...")
        log_message(app, "Cleaning up...")
        if DEMO_MODE:
            log_message(app, "[DEMO] Would remove configuration script")
            time.sleep(0.3)
            log_message(app, "[DEMO] Would unmount filesystems")
            time.sleep(0.5)
        else:
            subprocess.run(["rm", "/mnt/root/configure.sh"], check=True)
            # Sync and unmount all filesystems cleanly
            log_message(app, "Syncing and unmounting filesystems...")
            subprocess.run(["sync"], check=False)
            subprocess.run(["umount", "-R", "/mnt"], check=False)

        set_progress(app, 1.0, "Installation complete!")
        if DEMO_MODE:
            log_message(app, "\n[OK] Demo installation completed successfully!")
            log_message(app, "\n[DEMO] No actual changes were made to your system.")
            log_message(app, "[DEMO] Set DEMO_MODE = False for real installation.")
        else:
            log_message(app, "\n[OK] Installation completed successfully!")
            log_message(app, "madOS is fully configured and ready to use.")

        GLib.idle_add(_finish_installation, app)

    except Exception as e:
        log_message(app, f"\n[ERROR] {str(e)}")
        # Cleanup: try to unmount filesystems on failure
        if not DEMO_MODE:
            log_message(app, "Cleaning up after error...")
            subprocess.run(["umount", "-R", "/mnt"], capture_output=True)
        GLib.idle_add(app.install_spinner.stop)
        GLib.idle_add(_handle_installation_error, app, str(e))


def _handle_installation_error(app, error_msg):
    """Save log to file, show error dialog, then quit the installer."""
    log_path = save_log_to_file(app)
    if log_path:
        message = (
            f"{error_msg}\n\n"
            f"The installation log has been saved to:\n{log_path}\n\n"
            "The installer will now close."
        )
    else:
        message = f"{error_msg}\n\nThe installer will now close."
    show_error(app, "Installation Failed", message)
    Gtk.main_quit()
    return False


def _finish_installation(app):
    """Stop spinner and move to completion page"""
    app.install_spinner.stop()
    app.notebook.next_page()
    return False


def _post_rsync_cleanup(app):
    """Remove bulky files from the target after rsync to reclaim disk space.

    Expands glob patterns from ``POST_COPY_CLEANUP`` (relative to ``/mnt``)
    and removes matching paths.  Also sweeps for scattered ``__pycache__``
    directories.  Errors are silently ignored so a missing path never aborts
    the installation.
    """
    for pattern in POST_COPY_CLEANUP:
        full = os.path.join("/mnt", pattern)
        for path in globmod.glob(full):
            subprocess.run(["rm", "-rf", path], check=False)
    # Remove scattered __pycache__ directories
    subprocess.run(
        ["find", "/mnt/usr", "-type", "d", "-name", "__pycache__", "-exec", "rm", "-rf", "{}", "+"],
        check=False,
        capture_output=True,
    )
    log_message(app, "  Disk footprint reduced")


def _rsync_rootfs_with_progress(app):
    """Copy the live root filesystem to /mnt using rsync.

    All packages from the ISO are already installed in the live system, so
    copying with rsync is much faster than downloading and re-installing via
    pacstrap.  Virtual filesystems, caches, and archiso-specific files are
    excluded (see ``RSYNC_EXCLUDES`` in config.py).

    After the copy, archiso-specific packages are removed.

    Progress range: 0.21 → 0.48.
    """
    # --- rsync phase (0.21 → 0.43) ---
    set_progress(app, 0.21, "Copying live system to disk...")
    log_message(app, "Copying live system to target disk (rsync)...")
    log_message(app, "  (Packages already installed in the ISO – no download needed)")

    cmd = ["rsync", "-aAXHWS", "--info=progress2", "--no-inc-recursive", "--numeric-ids"]
    for exc in RSYNC_EXCLUDES:
        cmd.extend(["--exclude", exc])
    cmd.extend(["/", "/mnt/"])

    progress_start = 0.21
    progress_end = 0.43
    pct_re = re.compile(r"(\d{1,3})%")

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    while True:
        line = proc.stdout.readline()
        if not line:
            break
        line = line.rstrip()
        if not line:
            continue
        match = pct_re.search(line)
        if match:
            pct = int(match.group(1))
            progress = progress_start + (progress_end - progress_start) * (pct / 100)
            set_progress(app, progress, f"Copying system files ({pct}%)...")
        # Log non-progress lines (errors / warnings) but not individual filenames
        elif line.startswith("rsync:") or line.startswith("sent "):
            log_message(app, f"  {line}")

    proc.wait()
    if proc.returncode not in (0, 24):
        raise subprocess.CalledProcessError(proc.returncode, "rsync")
    if proc.returncode == 24:
        log_message(
            app,
            "  WARNING: rsync reported vanished source files (normal on live system)",
        )

    log_message(app, "  System files copied successfully")

    # --- Post-copy cleanup (0.43 → 0.45) ---
    set_progress(app, 0.43, "Reducing disk footprint...")
    log_message(app, "Removing unnecessary files to save disk space...")
    _post_rsync_cleanup(app)

    # --- Archiso cleanup (0.45 → 0.48) ---
    set_progress(app, 0.45, "Cleaning archiso artifacts...")
    log_message(app, "Removing archiso-specific packages...")
    subprocess.run(
        ["arch-chroot", "/mnt", "pacman", "-Rdd", "--noconfirm"] + list(ARCHISO_PACKAGES),
        capture_output=True,
    )
    # Ensure machine-id is regenerated on first boot
    machine_id = "/mnt/etc/machine-id"
    try:
        os.remove(machine_id)
    except FileNotFoundError:
        pass
    with open(machine_id, "w"):
        pass  # empty file → systemd generates a new id
    log_message(app, "  Archiso cleanup complete")

    set_progress(app, 0.48, "System ready")
    log_message(app, "Base system ready")


def _prepare_pacman(app):
    """Ensure pacman keyring is ready and databases are synced before pacstrap.

    On the live ISO, pacman-init.service initializes the keyring on a tmpfs at
    boot.  On slow hardware (Intel Atom, limited entropy) this can take 10-20
    minutes.  If pacstrap starts before it finishes, it blocks silently while
    waiting for the keyring — the user sees no progress at all.

    This function:
    1. Waits for pacman-init.service to finish (with progress feedback).
    2. Syncs the package databases so pacstrap can skip that step.
    """
    # --- Wait for pacman-init.service ---
    set_progress(app, 0.21, "Checking package manager keyring...")
    log_message(app, "Checking pacman keyring status...")

    try:
        result = subprocess.run(
            ["systemctl", "is-active", "pacman-init.service"],
            capture_output=True,
            text=True,
        )
        status = result.stdout.strip()
    except Exception:
        status = "unknown"

    if status == "activating":
        log_message(app, "  Pacman keyring is still being initialized, waiting...")
        log_message(app, "  (This can take several minutes on slow hardware)")
        poll_count = 0
        while True:
            time.sleep(5)
            poll_count += 1
            try:
                result = subprocess.run(
                    ["systemctl", "is-active", "pacman-init.service"],
                    capture_output=True,
                    text=True,
                )
                status = result.stdout.strip()
            except Exception:
                status = "unknown"
                break
            if status != "activating":
                break
            # Show periodic feedback so the user knows it's not stuck
            if poll_count % 6 == 0:  # every ~30 seconds
                elapsed = poll_count * 5
                log_message(app, f"  Still initializing keyring... ({elapsed}s elapsed)")

    # systemctl is-active returns: active, activating, inactive, failed, or
    # deactivating.  We already waited for "activating" above; "active" means
    # the keyring is fine.  Any other state means the keyring may be missing.
    if status in ("failed", "inactive", "unknown"):
        log_message(app, f"  Keyring service status: {status}, initializing manually...")
        # Ensure the gnupg directory exists and is writable before pacman-key.
        # The installer runs as root, so the directory will be root-owned.
        gnupg_dir = "/etc/pacman.d/gnupg"
        os.makedirs(gnupg_dir, mode=0o700, exist_ok=True)
        subprocess.run(["pacman-key", "--init"], check=True)
        subprocess.run(["pacman-key", "--populate"], check=True)

    log_message(app, "  Pacman keyring is ready")

    # --- Sync package databases ---
    set_progress(app, 0.23, "Synchronizing package databases...")
    log_message(app, "Synchronizing package databases...")
    proc = subprocess.Popen(
        ["pacman", "-Sy", "--noconfirm"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    while True:
        line = proc.stdout.readline()
        if not line:
            break
        line = line.rstrip()
        if line:
            log_message(app, f"  {line}")
    proc.wait()
    if proc.returncode != 0:
        log_message(app, "  Warning: database sync returned non-zero, pacstrap will retry")
    else:
        log_message(app, "  Package databases synchronized")


def _download_packages_with_progress(app, packages):
    """Pre-download packages in small groups so the progress bar stays alive.

    Downloads packages to the host pacman cache using ``pacman -Sw``.
    pacstrap will then find them already cached and skip re-downloading,
    which keeps the subsequent install phase fast and responsive.

    The progress bar advances from 0.25 to 0.36 during this phase.
    """
    total = len(packages)
    progress_start = 0.25
    progress_end = 0.36
    group_size = 10

    downloaded = 0
    for i in range(0, total, group_size):
        group = packages[i : i + group_size]
        end = min(i + group_size, total)
        progress = progress_start + (progress_end - progress_start) * (i / total)
        set_progress(app, progress, f"Downloading packages ({downloaded}/{total})...")

        group_preview = ", ".join(group[:3]) + ("..." if len(group) > 3 else "")
        log_message(app, f"  Downloading group: {group_preview}")

        proc = subprocess.Popen(
            ["pacman", "-Sw", "--noconfirm"] + group,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        while True:
            line = proc.stdout.readline()
            if not line:
                break
            line = line.rstrip()
            if not line:
                continue
            # Skip noisy progress-bar lines (e.g. "  100%  [####...]" or "---")
            if re.match(r"^\s*\d+%\s*\[|^\s*[-#]+\s*$", line):
                continue
            log_message(app, f"    {line}")

        proc.wait()
        if proc.returncode != 0:
            log_message(
                app,
                f"  Warning: download failed for group {i // group_size + 1} "
                f"(exit code {proc.returncode}), pacstrap will retry",
            )

        downloaded = end
        progress = progress_start + (progress_end - progress_start) * (downloaded / total)
        set_progress(app, progress, f"Downloading packages ({downloaded}/{total})...")

    set_progress(app, progress_end, "All packages downloaded")
    log_message(app, f"  All {total} packages downloaded to cache")


def _run_pacstrap_with_progress(app, packages, max_retries=3):
    """Run pacstrap while parsing output to update progress bar and log.

    Retries up to *max_retries* times on failure, refreshing the package
    databases between attempts so that transient mirror / keyring / network
    errors do not immediately abort the installation.
    """
    last_error = None

    for attempt in range(1, max_retries + 1):
        returncode, installed_count = _run_single_pacstrap(app, packages)

        if returncode == 0:
            set_progress(app, 0.48, "Base system installed")
            log_message(app, f"Base system installed ({installed_count} packages)")
            return

        last_error = subprocess.CalledProcessError(returncode, "pacstrap")
        if attempt < max_retries:
            log_message(
                app,
                f"  pacstrap failed (exit code {returncode}), "
                f"retrying ({attempt}/{max_retries})...",
            )
            # Progress 0.36 = pacstrap phase start (see _run_single_pacstrap)
            set_progress(
                app, 0.36, f"Retrying installation (attempt {attempt + 1}/{max_retries})..."
            )
            # Refresh databases before retrying
            refresh = subprocess.run(
                ["pacman", "-Sy", "--noconfirm"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if refresh.returncode != 0:
                log_message(
                    app,
                    "  Warning: database refresh failed, retrying pacstrap anyway...",
                )

    raise last_error


def _run_single_pacstrap(app, packages):
    """Execute one pacstrap invocation and return (returncode, installed_count)."""
    total_packages = len(packages)
    installed_count = 0

    # Progress range: 0.36 to 0.48 for pacstrap (packages already cached)
    progress_start = 0.36
    progress_end = 0.48

    proc = subprocess.Popen(
        ["pacstrap", "/mnt"] + packages,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    # Patterns to detect package installation progress from pacman output
    # Match "(N/M) installing pkg-name" format used by pacman
    numbered_pkg_pattern = re.compile(r"\((\d+)/(\d+)\)\s+installing\s+(\S+)", re.IGNORECASE)
    pkg_pattern = re.compile(r"installing\s+(\S+)", re.IGNORECASE)
    downloading_pattern = re.compile(r"downloading\s+(\S+)", re.IGNORECASE)
    resolving_pattern = re.compile(r"resolving dependencies|looking for conflicting", re.IGNORECASE)
    total_pattern = re.compile(r"Packages\s+\((\d+)\)", re.IGNORECASE)
    # Detect section markers like ":: Processing package changes..."
    section_pattern = re.compile(r"^::")
    # Detect hook lines like "(1/5) Arming ConditionNeedsUpdate..."
    hook_pattern = re.compile(r"^\((\d+)/(\d+)\)\s+(?!installing)", re.IGNORECASE)
    # Detect early-phase output: keyring checks, integrity verification, syncing
    keyring_pattern = re.compile(
        r"checking keyring|checking keys|checking integrity|"
        r"checking package integrity|checking available disk|"
        r"synchronizing package|loading package|"
        r"checking for file conflicts|upgrading|retrieving",
        re.IGNORECASE,
    )
    # Skip noisy progress-bar lines (e.g. "  100%  [####...]")
    progress_bar_pattern = re.compile(r"^\s*\d+%\s*\[|^\s*[-#]+\s*$|^$")

    # Use readline() instead of iterator to avoid Python's internal
    # read-ahead buffering which delays output on piped subprocesses
    while True:
        line = proc.stdout.readline()
        if not line:
            break
        line = line.rstrip()
        if not line:
            continue

        # Try to detect total package count from pacman
        total_match = total_pattern.search(line)
        if total_match:
            total_packages = int(total_match.group(1))
            log_message(app, f"Total packages to install: {total_packages}")
            continue

        # Detect "(N/M) installing pkg" format (most reliable)
        numbered_match = numbered_pkg_pattern.search(line)
        if numbered_match:
            installed_count = int(numbered_match.group(1))
            total_from_line = int(numbered_match.group(2))
            current_pkg = numbered_match.group(3).rstrip(".")
            if total_from_line > 0:
                total_packages = total_from_line
            progress = progress_start + (progress_end - progress_start) * (
                installed_count / max(total_packages, 1)
            )
            progress = min(progress, progress_end)
            set_progress(
                app,
                progress,
                f"Installing packages ({installed_count}/{total_packages})...",
            )
            log_message(app, f"  Installing {current_pkg}...")
            continue

        # Fallback: detect "installing pkg" without numbering
        pkg_match = pkg_pattern.search(line)
        if pkg_match:
            current_pkg = pkg_match.group(1).rstrip(".")
            installed_count += 1
            progress = progress_start + (progress_end - progress_start) * (
                installed_count / max(total_packages, 1)
            )
            progress = min(progress, progress_end)
            set_progress(
                app,
                progress,
                f"Installing packages ({installed_count}/{total_packages})...",
            )
            log_message(app, f"  Installing {current_pkg}...")
            continue

        # Show download progress
        dl_match = downloading_pattern.search(line)
        if dl_match:
            log_message(app, f"  Downloading {dl_match.group(1)}...")
            continue

        # Show resolving phase
        if resolving_pattern.search(line):
            log_message(app, f"  {line.strip()}")
            continue

        # Show section markers (e.g. ":: Processing package changes...")
        if section_pattern.search(line):
            log_message(app, line.strip())
            continue

        # Show post-transaction hooks
        if hook_pattern.search(line):
            log_message(app, f"  {line.strip()}")
            continue

        # Show early-phase output (keyring, integrity, sync, etc.)
        if keyring_pattern.search(line):
            set_progress(app, progress_start, f"{line.strip()}...")
            log_message(app, f"  {line.strip()}")
            continue

        # Skip noisy progress-bar lines
        if progress_bar_pattern.search(line):
            continue

        # Fallback: log any other non-empty output so nothing appears silent
        log_message(app, f"  {line.strip()}")

    proc.wait()
    return proc.returncode, installed_count


def _run_chroot_with_progress(app):
    """Run arch-chroot configure.sh while streaming output and updating progress"""
    # Progress range: 0.55 to 0.90 for chroot configuration
    progress_start = 0.55
    progress_end = 0.90

    # Validate that configure.sh was written before executing
    script_path = "/mnt/root/configure.sh"
    if not os.path.isfile(script_path):
        raise FileNotFoundError(
            f"Configuration script not found at {script_path} — disk may be full or write failed"
        )
    if os.path.getsize(script_path) == 0:
        raise ValueError(f"Configuration script at {script_path} is empty — write may have failed")

    proc = subprocess.Popen(
        ["arch-chroot", "/mnt", "/root/configure.sh"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    # Pattern to detect progress markers: [PROGRESS N/M] description
    progress_pattern = re.compile(r"\[PROGRESS\s+(\d+)/(\d+)\]\s+(.+)")

    while True:
        line = proc.stdout.readline()
        if not line:
            break
        line = line.rstrip()
        if not line:
            continue

        # Check for progress markers
        progress_match = progress_pattern.search(line)
        if progress_match:
            step = int(progress_match.group(1))
            total = int(progress_match.group(2))
            description = progress_match.group(3)
            progress = progress_start + (progress_end - progress_start) * (step / max(total, 1))
            progress = min(progress, progress_end)
            set_progress(app, progress, description)
            log_message(app, f"  {description}")
            continue

        # Log all other output
        log_message(app, f"  {line}")

    proc.wait()
    if proc.returncode != 0:
        raise subprocess.CalledProcessError(proc.returncode, "arch-chroot")

    set_progress(app, progress_end, "System configured")
    log_message(app, "System configuration complete")




def _build_config_script(data):
    """Build the chroot configuration shell script.

    Handles: timezone, locale, hostname, user account, GRUB bootloader,
    Plymouth, initramfs, essential services, system optimizations, desktop
    environment basics, and graphical environment verification.
    """
    disk = data["disk"]

    # Validate timezone against whitelist to prevent path traversal
    timezone = data["timezone"]
    if timezone not in TIMEZONES:
        raise ValueError(f"Invalid timezone: {timezone}")

    # Validate locale against whitelist
    locale = data["locale"]
    valid_locales = list(LOCALE_MAP.values())
    if locale not in valid_locales:
        raise ValueError(f"Invalid locale: {locale}")

    # Validate disk path (must be a simple block device path like /dev/sda or /dev/nvme0n1)
    if not re.match(r"^/dev/[a-zA-Z0-9]+$", disk):
        raise ValueError(f"Invalid disk path: {disk}")

    # Validate username (defense-in-depth, also checked in user.py)
    username = data["username"]
    if not re.match(r"^[a-z_][a-z0-9_-]*$", username):
        raise ValueError(f"Invalid username: {username}")

    ventoy_size = data.get("ventoy_persist_size", 4096)

    return f'''#!/bin/bash
set -e
exec {SCRIPTS_DIR}/configure-system.sh "{username}" "{timezone}" "{locale}" "{data["hostname"]}" "{disk}" "{ventoy_size}"
'''
