"""Snapper integration for mados-updater."""

import subprocess
import re
from typing import Optional, List


class SnapperClient:
    SNAPSHOT_PREFIX = "pre-update"
    CONFIG = "root"

    def create_snapshot(
        self, description: str = None, snapshot_type: str = "single"
    ) -> Optional[int]:
        cmd = [
            "snapper",
            "create",
            "-t",
            snapshot_type,
            "-c",
            self.CONFIG,
            "-p",
        ]
        if description:
            cmd.extend(["-d", description])

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            output = result.stdout.strip()
            match = re.search(r"Created snapshot (\d+)", output)
            if match:
                return int(match.group(1))
            return None
        except subprocess.CalledProcessError as e:
            print(f"Error creating snapshot: {e.stderr}")
            return None
        except subprocess.CalledProcessError as e:
            print(f"Error creating snapshot: {e.stderr}")
            return None

    def list_snapshots(self) -> List[dict]:
        try:
            result = subprocess.run(
                ["snapper", "list", "-c", self.CONFIG],
                capture_output=True,
                text=True,
                check=True,
            )
            snapshots = []
            lines = result.stdout.strip().split("\n")
            for line in lines[2:]:
                parts = [p.strip() for p in line.split("|")]
                if len(parts) >= 6:
                    snapshots.append(
                        {
                            "number": parts[0],
                            "type": parts[1],
                            "pre_num": parts[2],
                            "date": parts[3],
                            "time": parts[4],
                            "description": parts[5] if len(parts) > 5 else "",
                        }
                    )
            return snapshots
        except subprocess.CalledProcessError as e:
            print(f"Error listing snapshots: {e.stderr}")
            return []

    def get_latest_pre_snapshot(self) -> Optional[int]:
        snapshots = self.list_snapshots()
        for snap in reversed(snapshots):
            if self.SNAPSHOT_PREFIX in snap.get("description", "").lower():
                return int(snap["number"])
        return None

    def rollback(self, snapshot_number: int) -> bool:
        try:
            subprocess.run(
                ["snapper", "rollback", str(snapshot_number)],
                capture_output=True,
                text=True,
                check=True,
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error rolling back: {e.stderr}")
            return False

    def delete_snapshot(self, snapshot_number: int) -> bool:
        try:
            subprocess.run(
                ["snapper", "delete", str(snapshot_number)],
                capture_output=True,
                text=True,
                check=True,
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error deleting snapshot: {e.stderr}")
            return False

    def cleanup(self, keep: int = 1) -> bool:
        try:
            subprocess.run(
                ["snapper", "cleanup", "number"],
                capture_output=True,
                text=True,
                check=True,
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error cleaning up snapshots: {e.stderr}")
            return False
