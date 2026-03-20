#!/usr/bin/env python3
"""Downloader module for madOS OTA updates.

Handles downloading updates from GitHub Releases.
"""

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


GITHUB_API_URL = "https://api.github.com"
GITHUB_REPO = "madoslinux/mad-os"
BACKUP_DIR = Path("/var/backup/mados")
TEMP_DIR = Path("/tmp/mados-update")


@dataclass
class ReleaseInfo:
    """Information about a GitHub release."""

    tag: str
    version: str
    version_json: dict
    download_urls: dict[str, str]
    checksums: dict[str, str]


@dataclass
class UpdateInfo:
    """Information about available updates."""

    system_update: bool
    app_updates: dict[str, tuple[str, str]]
    latest_version: str
    release_date: str


class Downloader:
    """Handles downloading updates from GitHub Releases."""

    def __init__(self, repo: str = GITHUB_REPO):
        self.repo = repo
        self.temp_dir = TEMP_DIR
        self.temp_dir.mkdir(parents=True, exist_ok=True)

    def get_latest_release(self, channel: str = "stable") -> ReleaseInfo | None:
        """Get the latest release from GitHub.

        Args:
            channel: Update channel (stable, beta)

        Returns:
            ReleaseInfo if found, None otherwise
        """
        if channel == "stable":
            tags_url = f"{GITHUB_API_URL}/repos/{self.repo}/releases"
        else:
            tags_url = f"{GITHUB_API_URL}/repos/{self.repo}/tags"

        try:
            with urllib.request.urlopen(tags_url) as response:
                data = json.loads(response.read().decode())

            if channel == "stable":
                releases = [r for r in data if not r.get("draft", False)]
                if not releases:
                    return None
                release = releases[0]
            else:
                release = data[0] if data else None

            if not release:
                return None

            tag = release.get("tag_name", "v0.0.0")
            version = tag.lstrip("v")

            version_json_url = None
            checksums = {}
            download_urls = {}

            for asset in release.get("assets", []):
                name = asset["name"]
                url = asset["browser_download_url"]

                if name == "version.json":
                    version_json_url = url
                elif name.endswith((".tar.gz", ".zip")):
                    download_urls[name] = url

            if version_json_url:
                with urllib.request.urlopen(version_json_url) as response:
                    version_json = json.loads(response.read().decode())
            else:
                version_json = {}

            return ReleaseInfo(
                tag=tag,
                version=version,
                version_json=version_json,
                download_urls=download_urls,
                checksums=checksums,
            )

        except Exception as e:
            print(f"Error fetching release: {e}", file=sys.stderr)
            return None

    def download_file(self, url: str, dest: Path, expected_hash: str | None = None) -> bool:
        """Download a file from URL.

        Args:
            url: Download URL
            dest: Destination path
            expected_hash: Expected SHA256 hash (optional)

        Returns:
            True if successful, False otherwise
        """
        try:
            print(f"Downloading {dest.name}...")
            urllib.request.urlretrieve(url, dest)

            if expected_hash:
                actual_hash = self._calculate_sha256(dest)
                if actual_hash != expected_hash:
                    print(
                        f"Hash mismatch! Expected: {expected_hash}, Got: {actual_hash}",
                        file=sys.stderr,
                    )
                    dest.unlink()
                    return False

            return True

        except Exception as e:
            print(f"Download failed: {e}", file=sys.stderr)
            return False

    def download_update(self, release: ReleaseInfo, dest_dir: Path | None = None) -> Path | None:
        """Download all update files from a release.

        Args:
            release: Release information
            dest_dir: Destination directory (default: temp dir)

        Returns:
            Path to directory with downloaded files, None on failure
        """
        if dest_dir is None:
            dest_dir = self.temp_dir

        download_dir = dest_dir / "update"
        download_dir.mkdir(parents=True, exist_ok=True)

        for name, url in release.download_urls.items():
            dest = download_dir / name
            expected_hash = release.checksums.get(name)

            if not self.download_file(url, dest, expected_hash):
                return None

        version_json_path = download_dir / "version.json"
        with open(version_json_path, "w") as f:
            json.dump(release.version_json, f, indent=2)

        return download_dir

    def cleanup(self) -> None:
        """Clean up temporary files."""
        import shutil

        if self.temp_dir.exists():
            shutil.rmtree(self.temp_dir, ignore_errors=True)

    @staticmethod
    def _calculate_sha256(file_path: Path) -> str:
        """Calculate SHA256 hash of a file."""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    @staticmethod
    def check_for_updates(current_version_json: dict, channel: str = "stable") -> UpdateInfo | None:
        """Check if updates are available.

        Args:
            current_version_json: Current version information
            channel: Update channel (stable, beta)

        Returns:
            UpdateInfo if updates available, None otherwise
        """
        downloader = Downloader()
        release = downloader.get_latest_release(channel)

        if not release:
            return None

        current_version = current_version_json.get("version", "0.0.0")

        if release.version <= current_version:
            return None

        system_update = release.version_json.get("system", {}).get(
            "version"
        ) != current_version_json.get("system", {}).get("version")

        app_updates = {}
        current_apps = current_version_json.get("apps", {})
        release_apps = release.version_json.get("apps", {})

        for app_name, app_version in release_apps.items():
            current_app_version = current_apps.get(app_name, "0.0.0")
            if app_version != current_app_version:
                app_updates[app_name] = (current_app_version, app_version)

        if not system_update and not app_updates:
            return None

        return UpdateInfo(
            system_update=system_update,
            app_updates=app_updates,
            latest_version=release.version,
            release_date=release.version_json.get("release_date", ""),
        )


def main():
    """CLI for testing downloader."""
    import argparse

    parser = argparse.ArgumentParser(description="madOS Update Downloader")
    parser.add_argument("--check", action="store_true", help="Check for updates")
    parser.add_argument(
        "--channel", default="stable", choices=["stable", "beta"], help="Update channel"
    )

    args = parser.parse_args()

    if args.check:
        current = {"version": "0.0.0", "system": {"version": "0.0.0"}, "apps": {}}
        try:
            with open("/etc/mados/version.json") as f:
                current = json.load(f)
        except FileNotFoundError:
            pass

        update_info = Downloader.check_for_updates(current, args.channel)
        if update_info:
            print(f"Updates available: {update_info.latest_version}")
            if update_info.system_update:
                print("  - System update available")
            if update_info.app_updates:
                print("  - App updates:")
                for app, (old, new) in update_info.app_updates.items():
                    print(f"    - {app}: {old} -> {new}")
        else:
            print("No updates available")


if __name__ == "__main__":
    main()
