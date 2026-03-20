#!/usr/bin/env python3
"""Backup module for madOS OTA updates.

Handles backup creation and rollback functionality.
"""

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional


BACKUP_DIR = Path("/var/backup/mados")
VERSION_FILE = Path("/etc/mados/version.json")
MAX_BACKUPS = 3


class BackupManager:
    """Manages backups for rollback functionality."""

    def __init__(self, backup_root: Path = BACKUP_DIR):
        self.backup_root = backup_root
        self.backup_root.mkdir(parents=True, exist_ok=True)

    def create_backup(self, backup_name: str | None = None) -> Path | None:
        """Create a backup of current system state.

        Args:
            backup_name: Optional name for backup (default: timestamp)

        Returns:
            Path to backup directory, None on failure
        """
        if backup_name is None:
            backup_name = datetime.now().strftime("%Y%m%d_%H%M%S")

        backup_path = self.backup_root / backup_name
        backup_path.mkdir(parents=True, exist_ok=True)

        try:
            if VERSION_FILE.exists():
                shutil.copy2(VERSION_FILE, backup_path / "version.json")

            self._backup_apps(backup_path / "apps")

            self._cleanup_old_backups()

            self._save_backup_manifest(backup_path)

            return backup_path

        except Exception as e:
            print(f"Backup failed: {e}", file=sys.stderr)
            shutil.rmtree(backup_path, ignore_errors=True)
            return None

    def _backup_apps(self, dest: Path) -> None:
        """Backup madOS applications."""
        apps_dir = Path("/usr/local/lib")
        dest.mkdir(parents=True, exist_ok=True)

        mados_apps = [
            "mados_installer",
            "mados_audio_player",
            "mados_video_player",
            "mados_photo_viewer",
            "mados_pdf_viewer",
            "mados_launcher",
            "mados_equalizer",
        ]

        for app in mados_apps:
            app_path = apps_dir / app
            if app_path.exists():
                dest_app = dest / app
                print(f"Backing up {app}...")
                shutil.copytree(app_path, dest_app, symlinks=True, dirs_exist_ok=True)

    def _cleanup_old_backups(self) -> None:
        """Remove old backups, keeping only MAX_BACKUPS."""
        backups = sorted(
            [d for d in self.backup_root.iterdir() if d.is_dir()],
            key=lambda d: d.stat().st_mtime,
            reverse=True,
        )

        for old_backup in backups[MAX_BACKUPS:]:
            print(f"Removing old backup: {old_backup.name}")
            shutil.rmtree(old_backup, ignore_errors=True)

    def _save_backup_manifest(self, backup_path: Path) -> None:
        """Save backup manifest with metadata."""
        manifest = {
            "timestamp": datetime.now().isoformat(),
            "version": self._get_current_version(),
            "backup_type": "ota_update",
        }

        with open(backup_path / "manifest.json", "w") as f:
            json.dump(manifest, f, indent=2)

    def _get_current_version(self) -> str:
        """Get current system version."""
        try:
            with open(VERSION_FILE) as f:
                data = json.load(f)
                return data.get("version", "unknown")
        except FileNotFoundError:
            return "unknown"

    def list_backups(self) -> list[dict]:
        """List all available backups.

        Returns:
            List of backup information dicts
        """
        backups = []

        for backup_dir in sorted(
            [d for d in self.backup_root.iterdir() if d.is_dir()],
            key=lambda d: d.stat().st_mtime,
            reverse=True,
        ):
            manifest_path = backup_dir / "manifest.json"
            if manifest_path.exists():
                with open(manifest_path) as f:
                    manifest = json.load(f)
            else:
                manifest = {"timestamp": "unknown", "version": "unknown"}

            backups.append(
                {
                    "name": backup_dir.name,
                    "timestamp": manifest.get("timestamp", "unknown"),
                    "version": manifest.get("version", "unknown"),
                    "path": str(backup_dir),
                }
            )

        return backups

    def restore_backup(self, backup_name: str) -> bool:
        """Restore from a backup.

        Args:
            backup_name: Name of backup to restore

        Returns:
            True if successful, False otherwise
        """
        backup_path = self.backup_root / backup_name

        if not backup_path.exists():
            print(f"Backup not found: {backup_name}", file=sys.stderr)
            return False

        try:
            version_backup = backup_path / "version.json"
            if version_backup.exists():
                shutil.copy2(version_backup, VERSION_FILE)

            apps_backup = backup_path / "apps"
            if apps_backup.exists():
                apps_dir = Path("/usr/local/lib")
                for app_dir in apps_backup.iterdir():
                    if app_dir.is_dir():
                        dest = apps_dir / app_dir.name
                        print(f"Restoring {app_dir.name}...")
                        if dest.exists():
                            shutil.rmtree(dest)
                        shutil.copytree(app_dir, dest, symlinks=True)

            print(f"Successfully restored from backup: {backup_name}")
            return True

        except Exception as e:
            print(f"Restore failed: {e}", file=sys.stderr)
            return False

    def get_latest_backup(self) -> Path | None:
        """Get the most recent backup.

        Returns:
            Path to latest backup, None if no backups
        """
        backups = sorted(
            [d for d in self.backup_root.iterdir() if d.is_dir()],
            key=lambda d: d.stat().st_mtime,
            reverse=True,
        )

        return backups[0] if backups else None


def main():
    """CLI for testing backup functionality."""
    import argparse

    parser = argparse.ArgumentParser(description="madOS Backup Manager")
    parser.add_argument("--create", action="store_true", help="Create a backup")
    parser.add_argument("--list", action="store_true", help="List backups")
    parser.add_argument("--restore", type=str, help="Restore from backup")
    parser.add_argument("--name", type=str, help="Backup name (for --create)")

    args = parser.parse_args()

    manager = BackupManager()

    if args.create:
        backup = manager.create_backup(args.name)
        if backup:
            print(f"Backup created: {backup}")
        else:
            print("Backup failed", file=sys.stderr)
            sys.exit(1)

    elif args.list:
        backups = manager.list_backups()
        if not backups:
            print("No backups found")
        else:
            for backup in backups:
                print(f"{backup['name']} - {backup['version']} - {backup['timestamp']}")

    elif args.restore:
        if manager.restore_backup(args.restore):
            print("Restore successful")
        else:
            print("Restore failed", file=sys.stderr)
            sys.exit(1)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
