#!/usr/bin/env python3
"""
mados-updater - OTA update client for madOS

Usage:
    mados-updater --check          Check for updates
    mados-updater --download      Download available updates
    mados-updater --install       Install downloaded updates
    mados-updater --rollback      Rollback to previous state
    mados-updater --status        Show current status
"""

import argparse
import os
import sys
import time
import tempfile
import shutil

DEMO_MODE = os.environ.get("DEMO_MODE", "false").lower() == "true"

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lib.config import UpdaterConfig, UpdaterState
from lib.github import GitHubClient
from lib.snapper import SnapperClient
from lib.pacman import PacmanClient


class MadOSUpdater:
    def __init__(self):
        self.config = UpdaterConfig()
        self.state = UpdaterState()
        self.snapper = SnapperClient()
        self.pacman = PacmanClient()
        self.github = GitHubClient(
            repo_url=self.config.get("updater", "repo_url"),
            channel=self.config.get("updater", "channel", "stable"),
        )
        self.temp_dir = None
        self.downloaded_packages = []

    def notify(self, message: str, dialog: bool = False):
        use_dialog = self.config.get_bool("notifications", "use_dialog", True)
        if dialog and use_dialog:
            self._notify_dialog(message)
        else:
            self._notify_system(message)

    def _notify_system(self, message: str):
        os.system(f'notify-send "madOS Updater" "{message}" 2>/dev/null')

    def _notify_dialog(self, message: str):
        os.system(
            f'zenity --info --title="madOS Updater" --text="{message}" 2>/dev/null'
        )

    def check(self) -> bool:
        if DEMO_MODE:
            print("[DEMO] Checking for updates...")
            print("[DEMO] Current version: 1.0.0")
            print("[DEMO] Latest version: 1.0.1")
            return True

        current_version = self.state.get_current_version()
        release = self.github.fetch_releases_json()

        if not release:
            print("No releases found or unable to fetch releases.")
            return False

        if release.version == current_version:
            print(f"System is up to date (version {current_version})")
            return False

        print(f"Update available: {current_version} -> {release.version}")
        print(f"Release date: {release.release_date}")
        print(f"Changelog: {release.changelog}")
        return True

    def download(self) -> bool:
        if DEMO_MODE:
            print("[DEMO] Downloading packages...")
            print("[DEMO] mados-core-1.0.1-1-x86_64.pkg.tar.zst")
            print("[DEMO] mados-desktop-1.0.1-1-x86_64.pkg.tar.zst")
            return True

        release = self.github.fetch_releases_json()
        if not release:
            print("No release information available.")
            return False

        self.temp_dir = tempfile.mkdtemp(prefix="mados-updater-")
        print(f"Download directory: {self.temp_dir}")

        for pkg in release.packages:
            pkg_name = f"{pkg['name']}-{pkg['version']}-x86_64.pkg.tar.zst"
            dest_path = os.path.join(self.temp_dir, pkg_name)
            print(f"Downloading {pkg_name}...")
            if not self.github.download_file(pkg_name, dest_path):
                print(f"Failed to download {pkg_name}")
                return False
            if release.checksum:
                if not self.github.verify_checksum(dest_path, release.checksum):
                    print(f"Checksum verification failed for {pkg_name}")
                    return False
            self.downloaded_packages.append(dest_path)

        print(f"Downloaded {len(self.downloaded_packages)} packages successfully.")
        return True

    def install(self) -> bool:
        if DEMO_MODE:
            print("[DEMO] Creating pre-update snapshot...")
            print("[DEMO] Installing packages...")
            print("[DEMO] Update completed successfully!")
            return True

        if not self.downloaded_packages and not self._load_downloaded_packages():
            print("No packages to install. Run --download first.")
            return False

        print("Creating pre-update snapshot...")
        snapshot_num = self.snapper.create_snapshot(
            description=f"pre-update-{int(time.time())}"
        )
        if not snapshot_num:
            print("Failed to create snapshot. Aborting update.")
            return False
        print(f"Created snapshot #{snapshot_num}")

        print("Installing packages...")
        if not self.pacman.install_packages(self.downloaded_packages):
            print("Package installation failed. Rolling back...")
            self.snapper.rollback(snapshot_num)
            return False

        print("Update installed successfully!")
        release = self.github.fetch_releases_json()
        if release:
            self.state.set_current_version(release.version)
        return True

    def _load_downloaded_packages(self) -> bool:
        if not self.temp_dir or not os.path.exists(self.temp_dir):
            return False
        self.downloaded_packages = [
            os.path.join(self.temp_dir, f)
            for f in os.listdir(self.temp_dir)
            if f.endswith(".pkg.tar.zst")
        ]
        return len(self.downloaded_packages) > 0

    def rollback(self, snapshot_number: int = None) -> bool:
        if DEMO_MODE:
            print("[DEMO] Rolling back to snapshot...")
            return True

        if snapshot_number is None:
            snapshot_number = self.snapper.get_latest_pre_snapshot()

        if not snapshot_number:
            print("No pre-update snapshot found.")
            return False

        print(f"Rolling back to snapshot #{snapshot_number}...")
        if self.snapper.rollback(snapshot_number):
            print("Rollback completed. Please reboot.")
            return True
        return False

    def status(self):
        current_version = self.state.get_current_version()
        print(f"Current version: {current_version}")
        print(f"Repo URL: {self.config.get('updater', 'repo_url')}")
        print(f"Channel: {self.config.get('updater', 'channel')}")

        snapshots = self.snapper.list_snapshots()
        print(f"\nSnapshots: {len(snapshots)}")
        for snap in snapshots[-5:]:
            print(f"  #{snap['number']} - {snap['description']}")

    def cleanup(self):
        if self.temp_dir and os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)


def main():
    parser = argparse.ArgumentParser(description="madOS OTA Updater")
    parser.add_argument(
        "--check", action="store_true", help="Check for available updates"
    )
    parser.add_argument(
        "--download", action="store_true", help="Download available updates"
    )
    parser.add_argument(
        "--install", action="store_true", help="Install downloaded updates"
    )
    parser.add_argument(
        "--rollback", action="store_true", help="Rollback to previous state"
    )
    parser.add_argument(
        "--status", action="store_true", help="Show current status"
    )
    parser.add_argument(
        "--snapshot",
        type=int,
        default=None,
        help="Specify snapshot number for rollback",
    )

    args = parser.parse_args()

    updater = MadOSUpdater()

    try:
        if args.check:
            success = updater.check()
            sys.exit(0 if success else 1)
        elif args.download:
            success = updater.download()
            sys.exit(0 if success else 1)
        elif args.install:
            success = updater.install()
            sys.exit(0 if success else 1)
        elif args.rollback:
            success = updater.rollback(args.snapshot)
            sys.exit(0 if success else 1)
        elif args.status:
            updater.status()
            sys.exit(0)
        else:
            parser.print_help()
            sys.exit(1)
    finally:
        updater.cleanup()


if __name__ == "__main__":
    main()
