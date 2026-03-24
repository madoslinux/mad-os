"""Pacman integration for mados-updater."""

import subprocess
import os
import shutil
from typing import List, Optional


class PacmanClient:
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or "/var/lib/pacman"

    def install_packages(self, package_paths: List[str]) -> bool:
        if not package_paths:
            return True

        cmd = ["pacman", "-U", "--noconfirm", "--noprogressbar"]
        cmd.extend(package_paths)

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if result.returncode != 0:
                print(f"Pacman error: {result.stderr}")
                return False
            return True
        except Exception as e:
            print(f"Error installing packages: {e}")
            return False

    def get_installed_version(self, package_name: str) -> Optional[str]:
        try:
            result = subprocess.run(
                ["pacman", "-Q", package_name],
                capture_output=True,
                text=True,
                check=True,
            )
            output = result.stdout.strip()
            if output:
                parts = output.split()
                if len(parts) >= 2:
                    return parts[1]
            return None
        except subprocess.CalledProcessError:
            return None

    def sync_packages(self, refresh: bool = False) -> bool:
        cmd = ["pacman", "-Sy", "--noconfirm", "--noprogressbar"]
        if not refresh:
            cmd.remove("-y")

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            return result.returncode == 0
        except Exception as e:
            print(f"Error syncing packages: {e}")
            return False

    def get_pending_updates(self) -> List[str]:
        try:
            result = subprocess.run(
                ["pacman", "-Qu"],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode == 0:
                packages = []
                for line in result.stdout.strip().split("\n"):
                    if line:
                        parts = line.split()
                        if parts:
                            packages.append(parts[0])
                return packages
            return []
        except Exception as e:
            print(f"Error checking pending updates: {e}")
            return []

    def is_locked(self) -> bool:
        return os.path.exists("/var/lib/pacman/db.lck")

    def remove_packages(self, package_paths: List[str]) -> bool:
        for pkg_path in package_paths:
            if os.path.exists(pkg_path):
                os.remove(pkg_path)
        return True
