"""GitHub API integration for mados-updater."""

import json
import os
import subprocess
import tempfile
import hashlib
from dataclasses import dataclass
from typing import Optional, List
import urllib.request
import urllib.error


RELEASES_JSON_URL = "releases.json"


@dataclass
class ReleaseInfo:
    version: str
    release_date: str
    packages: List[dict]
    checksum: str
    changelog: str
    min_supported_version: str
    download_url: str


class GitHubClient:
    def __init__(self, repo_url: str, channel: str = "stable"):
        self.repo_url = repo_url.rstrip("/")
        self.channel = channel
        self._parse_repo_url()

    def _parse_repo_url(self):
        parts = self.repo_url.replace("https://github.com/", "").split("/")
        self.owner = parts[0]
        self.repo = parts[1]

    def _get_api_url(self, endpoint: str) -> str:
        return f"https://api.github.com/repos/{self.owner}/{self.repo}/{endpoint}"

    def _get_release_url(self) -> str:
        return f"{self.repo_url}/releases/download/{self.channel}/{RELEASES_JSON_URL}"

    def fetch_releases_json(self) -> Optional[ReleaseInfo]:
        url = self._get_release_url()
        try:
            with urllib.request.urlopen(url, timeout=30) as resp:
                data = json.loads(resp.read().decode())
                return ReleaseInfo(
                    version=data.get("version", ""),
                    release_date=data.get("release_date", ""),
                    packages=data.get("packages", []),
                    checksum=data.get("checksum", ""),
                    changelog=data.get("changelog", ""),
                    min_supported_version=data.get("min_supported_version", "0.0.0"),
                    download_url=data.get(
                        "download_url",
                        f"{self.repo_url}/releases/download/{self.channel}/",
                    ),
                )
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            raise
        except Exception as e:
            print(f"Error fetching releases: {e}")
            return None

    def download_file(self, filename: str, dest_path: str) -> bool:
        url = f"{self._get_release_url().replace(RELEASES_JSON_URL, '')}{filename}"
        try:
            with urllib.request.urlopen(url, timeout=300) as resp:
                with open(dest_path, "wb") as f:
                    while True:
                        chunk = resp.read(8192)
                        if not chunk:
                            break
                        f.write(chunk)
            return True
        except Exception as e:
            print(f"Error downloading {filename}: {e}")
            if os.path.exists(dest_path):
                os.remove(dest_path)
            return False

    def verify_checksum(self, file_path: str, expected_checksum: str) -> bool:
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        actual = sha256_hash.hexdigest()
        return actual == expected_checksum

    def get_latest_release(self) -> Optional[ReleaseInfo]:
        api_url = self._get_api_url(f"releases/latest")
        try:
            with urllib.request.urlopen(api_url, timeout=30) as resp:
                data = json.loads(resp.read().decode())
                assets = data.get("assets", [])
                download_url = None
                for asset in assets:
                    if asset["name"] == RELEASES_JSON_URL:
                        download_url = asset["browser_download_url"]
                        break
                if not download_url:
                    return None
                temp_dir = tempfile.mkdtemp()
                releases_json_path = os.path.join(temp_dir, RELEASES_JSON_URL)
                if self.download_file(RELEASES_JSON_URL, releases_json_path):
                    with open(releases_json_path) as f:
                        data = json.load(f)
                    import shutil

                    shutil.rmtree(temp_dir)
                    return ReleaseInfo(
                        version=data.get("version", ""),
                        release_date=data.get("release_date", ""),
                        packages=data.get("packages", []),
                        checksum=data.get("checksum", ""),
                        changelog=data.get("changelog", ""),
                        min_supported_version=data.get(
                            "min_supported_version", "0.0.0"
                        ),
                        download_url=os.path.dirname(download_url) + "/",
                    )
        except Exception as e:
            print(f"Error fetching latest release: {e}")
        return None
