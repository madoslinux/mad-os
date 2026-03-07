"""
madOS Installer - Package Management Module

Handles package installation via pacman, pacstrap, and rsync.
"""

import glob as globmod
import os
import re
import subprocess
import time

from ..config import (
    DEMO_MODE,
    PACKAGES,
    RSYNC_EXCLUDES,
    POST_COPY_CLEANUP,
    ARCHISO_PACKAGES,
)
from ..utils import log_message, set_progress


def post_rsync_cleanup(app):
    """Remove bulky files from the target after rsync."""
    for pattern in POST_COPY_CLEANUP:
        full = os.path.join("/mnt", pattern)
        for path in globmod.glob(full):
            subprocess.run(["rm", "-rf", path], check=False)
    subprocess.run(
        ["find", "/mnt/usr", "-type", "d", "-name", "__pycache__", "-exec", "rm", "-rf", "{}", "+"],
        check=False,
        capture_output=True,
    )
    log_message(app, "  Disk footprint reduced")


def rsync_rootfs_with_progress(app):
    """Copy the live root filesystem to /mnt using rsync."""
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

    set_progress(app, 0.43, "Reducing disk footprint...")
    log_message(app, "Removing unnecessary files to save disk space...")
    post_rsync_cleanup(app)

    set_progress(app, 0.45, "Cleaning archiso artifacts...")
    log_message(app, "Removing archiso-specific packages...")
    subprocess.run(
        ["arch-chroot", "/mnt", "pacman", "-Rdd", "--noconfirm"] + list(ARCHISO_PACKAGES),
        capture_output=True,
    )
    machine_id = "/mnt/etc/machine-id"
    try:
        os.remove(machine_id)
    except FileNotFoundError:
        pass
    with open(machine_id, "w"):
        pass
    log_message(app, "  Archiso cleanup complete")

    set_progress(app, 0.48, "System ready")
    log_message(app, "Base system ready")


def prepare_pacman(app):
    """Ensure pacman keyring is ready and databases are synced."""
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
            if poll_count % 6 == 0:
                elapsed = poll_count * 5
                log_message(app, f"  Still initializing keyring... ({elapsed}s elapsed)")

    if status in ("failed", "inactive", "unknown"):
        log_message(app, f"  Keyring service status: {status}, initializing manually...")
        gnupg_dir = "/etc/pacman.d/gnupg"
        os.makedirs(gnupg_dir, mode=0o700, exist_ok=True)
        subprocess.run(["pacman-key", "--init"], check=True)
        subprocess.run(["pacman-key", "--populate"], check=True)

    log_message(app, "  Pacman keyring is ready")

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
        log_message(app, "  Warning: database sync failed, pacstrap will retry")
    else:
        log_message(app, "  Package databases synchronized")


def download_packages_with_progress(app, packages):
    """Pre-download packages in small groups."""
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


def run_pacstrap_with_progress(app, packages, max_retries=3):
    """Run pacstrap while parsing output to update progress bar and log."""
    last_error = None

    for attempt in range(1, max_retries + 1):
        returncode, installed_count = run_single_pacstrap(app, packages)

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
            set_progress(
                app, 0.36, f"Retrying installation (attempt {attempt + 1}/{max_retries})..."
            )
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


def run_single_pacstrap(app, packages):
    """Execute one pacstrap invocation and return (returncode, installed_count)."""
    total_packages = len(packages)
    installed_count = 0

    progress_start = 0.36
    progress_end = 0.48

    proc = subprocess.Popen(
        ["pacstrap", "/mnt"] + packages,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    numbered_pkg_pattern = re.compile(r"\((\d+)/(\d+)\)\s+installing\s+(\S+)", re.IGNORECASE)
    pkg_pattern = re.compile(r"installing\s+(\S+)", re.IGNORECASE)
    downloading_pattern = re.compile(r"downloading\s+(\S+)", re.IGNORECASE)
    resolving_pattern = re.compile(r"resolving dependencies|looking for conflicting", re.IGNORECASE)
    total_pattern = re.compile(r"Packages\s+\((\d+)\)", re.IGNORECASE)
    section_pattern = re.compile(r"^::")
    hook_pattern = re.compile(r"^\((\d+)/(\d+)\)\s+(?!installing)", re.IGNORECASE)
    keyring_pattern = re.compile(
        r"checking keyring|checking keys|checking integrity|"
        r"checking package integrity|checking available disk|"
        r"synchronizing package|loading package|"
        r"checking for file conflicts|upgrading|retrieving",
        re.IGNORECASE,
    )
    progress_bar_pattern = re.compile(r"^\s*\d+%\s*\[|^\s*[-#]+\s*$|^$")

    while True:
        line = proc.stdout.readline()
        if not line:
            break
        line = line.rstrip()
        if not line:
            continue

        total_match = total_pattern.search(line)
        if total_match:
            total_packages = int(total_match.group(1))
            log_message(app, f"Total packages to install: {total_packages}")
            continue

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

        dl_match = downloading_pattern.search(line)
        if dl_match:
            log_message(app, f"  Downloading {dl_match.group(1)}...")
            continue

        if resolving_pattern.search(line):
            log_message(app, f"  {line.strip()}")
            continue

        if section_pattern.search(line):
            log_message(app, line.strip())
            continue

        if hook_pattern.search(line):
            log_message(app, f"  {line.strip()}")
            continue

        if keyring_pattern.search(line):
            set_progress(app, progress_start, f"{line.strip()}...")
            log_message(app, f"  {line.strip()}")
            continue

        if progress_bar_pattern.search(line):
            continue

        log_message(app, f"  {line.strip()}")

    proc.wait()
    return proc.returncode, installed_count
