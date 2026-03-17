#!/usr/bin/env python3
"""madOS OTA Update System

This module provides Over-The-Air update functionality for madOS,
including system packages and madOS applications.
"""

__version__ = "1.0.0"
__author__ = "madOS Team"

from .downloader import Downloader
from .installer import Installer
from .backup import BackupManager
from .version import VersionManager

__all__ = ["Downloader", "Installer", "BackupManager", "VersionManager"]