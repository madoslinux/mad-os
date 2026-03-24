"""Configuration management for mados-updater."""

import os
from configparser import ConfigParser
from typing import Optional

DEFAULT_CONFIG = """[updater]
repo_url = https://github.com/madkoding/mados-updates
channel = stable
check_interval = 3600
auto_download = false
auto_install = false

[notifications]
enabled = true
use_dialog = true
"""

CONFIG_PATH = "/etc/mados-updater.conf"
STATE_PATH = "/var/lib/mados-updater/state.conf"


class UpdaterConfig:
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = config_path or CONFIG_PATH
        self.config = ConfigParser()
        self._load()

    def _load(self):
        if os.path.exists(self.config_path):
            self.config.read(self.config_path)
        else:
            self.config.read_string(DEFAULT_CONFIG)
            self._ensure_config_dir()

    def _ensure_config_dir(self):
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        with open(self.config_path, "w") as f:
            self.config.write(f)

    def get(self, section: str, key: str, fallback: str = None) -> str:
        return self.config.get(section, key, fallback=fallback)

    def get_bool(self, section: str, key: str, fallback: bool = False) -> bool:
        return self.config.getboolean(section, key, fallback=fallback)

    def get_int(self, section: str, key: str, fallback: int = 0) -> int:
        return self.config.getint(section, key, fallback=fallback)

    def set(self, section: str, key: str, value: str):
        if not self.config.has_section(section):
            self.config.add_section(section)
        self.config.set(section, key, value)

    def save(self):
        with open(self.config_path, "w") as f:
            self.config.write(f)


class UpdaterState:
    def __init__(self, state_path: Optional[str] = None):
        self.state_path = state_path or STATE_PATH
        self.config = ConfigParser()
        self._load()

    def _load(self):
        if os.path.exists(self.state_path):
            self.config.read(self.state_path)
        else:
            self.config.read_string("[state]")
            os.makedirs(os.path.dirname(self.state_path), exist_ok=True)

    def get_current_version(self) -> str:
        version_file = "/etc/mados-version"
        if os.path.exists(version_file):
            with open(version_file) as f:
                return f.read().strip()
        return self.config.get("state", "current_version", fallback="0.0.0")

    def set_current_version(self, version: str):
        self.config.set("state", "current_version", version)
        os.makedirs(os.path.dirname(self.state_path), exist_ok=True)
        with open(self.state_path, "w") as f:
            self.config.write(f)

    def get_last_check(self) -> int:
        return self.config.getint("state", "last_check", fallback=0)

    def set_last_check(self, timestamp: int):
        self.config.set("state", "last_check", str(timestamp))
        with open(self.state_path, "w") as f:
            self.config.write(f)
