#!/usr/bin/env python3
"""Installer module for madOS OTA updates.

Handles installation of downloaded updates.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional

from .backup import BackupManager
from .downloader import ReleaseInfo


VERSION_FILE = Path("/etc/mados/version.json")


class Installer:
    """Handles installation of OTA updates."""

    def __init__(self):
        self.backup_manager = BackupManager()

    def install_update(
        self, update_dir: Path, auto_backup: bool = True
    ) -> bool:
        """Install an update from a downloaded directory.

        Args:
            update_dir: Directory containing update files
            auto_backup: Whether to create backup before install

        Returns:
            True if successful, False otherwise
        """
        try:
            version_json_path = update_dir / "version.json"
            if not version_json_path.exists():
                print("version.json not found in update", file=sys.stderr)
                return False

            with open(version_json_path) as f:
                new_version_data = json.load(f)

            if auto_backup:
                print("Creating backup...")
                backup = self.backup_manager.create_backup()
                if not backup:
                    print("Warning: Backup failed, continuing anyway...")

            apps_tarball = update_dir / "apps.tar.gz"
            if apps_tarball.exists():
                print("Installing apps...")
                self._install_apps(apps_tarball)

            system_tarball = update_dir / "system.tar.gz"
            if system_tarball.exists():
                print("Installing system files...")
                self._install_system(system_tarball)

            self._update_version(new_version_data)

            print("Update installed successfully!")
            return True

        except Exception as e:
            print(f"Installation failed: {e}", file=sys.stderr)
            return False

    def _install_apps(self, tarball: Path) -> None:
        """Install applications from tarball."""
        apps_dir = Path("/usr/local/lib")

        result = subprocess.run(
            ["tar", "-xzf", str(tarball), "-C", str(apps_dir)],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(f"Failed to extract apps: {result.stderr}")

        print("Apps installed successfully")

    def _install_system(self, tarball: Path) -> None:
        """Install system files from tarball."""
        result = subprocess.run(
            ["tar", "-xzf", str(tarball), "-C", "/"],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(f"Failed to extract system: {result.stderr}")

        print("System files installed successfully")

    def _update_version(self, new_version_data: dict) -> None:
        """Update the version file with new version info."""
        version_data = {}
        if VERSION_FILE.exists():
            with open(VERSION_FILE) as f:
                version_data = json.load(f)

        version_data.update(new_version_data)

        with open(VERSION_FILE, "w") as f:
            json.dump(version_data, f, indent=2)

    def run_pacman_update(self) -> bool:
        """Run pacman system update.

        Returns:
            True if successful, False otherwise
        """
        try:
            print("Running pacman update...")

            result = subprocess.run(
                ["pacman", "-Syu", "--noconfirm"],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                print("System packages updated successfully")
                return True
            elif result.returncode == 1:
                print("Warning: pacman update had issues", file=sys.stderr)
                print(result.stdout, file=sys.stdout)
                return False
            else:
                print(f"pacman update failed: {result.stderr}", file=sys.stderr)
                return False

        except Exception as e:
            print(f"pacman update failed: {e}", file=sys.stderr)
            return False

    def restart_services(self) -> None:
        """Restart systemd services that need updating."""
        services_to_restart = [
            "mados-ota.service",
            "mados-installer-autostart.service",
        ]

        for service in services_to_restart:
            try:
                subprocess.run(
                    ["systemctl", "restart", service],
                    capture_output=True,
                )
            except Exception:
                pass

    def rollback(self, backup_name: Optional[str] = None) -> bool:
        """Rollback to a previous version.

        Args:
            backup_name: Specific backup to restore (latest if None)

        Returns:
            True if successful, False otherwise
        """
        if backup_name is None:
            backup = self.backup_manager.get_latest_backup()
            if backup:
                backup_name = backup.name
            else:
                print("No backups available", file=sys.stderr)
                return False

        return self.backup_manager.restore_backup(backup_name)


def main():
    """CLI for testing installer functionality."""
    import argparse

    parser = argparse.ArgumentParser(description="madOS Update Installer")
    parser.add_argument("--install", type=str, help="Install from directory")
    parser.add_argument("--rollback", type=str, help="Rollback to backup")
    parser.add_argument(
        "--pacman", action="store_true", help="Run pacman system update"
    )

    args = parser.parse_args()

    installer = Installer()

    if args.install:
        success = installer.install_update(Path(args.install))
        sys.exit(0 if success else 1)

    elif args.rollback:
        success = installer.rollback(args.rollback)
        sys.exit(0 if success else 1)

    elif args.pacman:
        success = installer.run_pacman_update()
        sys.exit(0 if success else 1)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()