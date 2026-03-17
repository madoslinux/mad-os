#!/usr/bin/env python3
"""Unit tests for madOS OTA Update System."""

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).parent.parent / "airootfs/usr/local/lib"))

from mados_update.version import VersionManager
from mados_update.backup import BackupManager
from mados_update.downloader import Downloader, ReleaseInfo, UpdateInfo


class TestVersionManager(unittest.TestCase):
    """Tests for VersionManager."""

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.version_file = Path(self.temp_dir.name) / "version.json"
        self.manager = VersionManager(self.version_file)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_get_version_default(self):
        """Test getting default version."""
        version = self.manager.get_version()
        self.assertEqual(version["version"], "0.0.0")
        self.assertIn("apps", version)

    def test_set_version(self):
        """Test setting version."""
        test_data = {
            "version": "1.0.0",
            "release_date": "2025-01-01",
            "system": {"version": "1.0.0", "arch": "x86_64"},
            "apps": {},
        }
        self.assertTrue(self.manager.set_version(test_data))

        loaded = self.manager.get_version()
        self.assertEqual(loaded["version"], "1.0.0")

    def test_update_last_check(self):
        """Test updating last check timestamp."""
        result = self.manager.update_last_check()
        self.assertTrue(result)

        version = self.manager.get_version()
        self.assertIsNotNone(version["last_check"])

    def test_set_auto_update(self):
        """Test setting auto-update preference."""
        self.manager.set_auto_update(True)
        version = self.manager.get_version()
        self.assertTrue(version["auto_update"])

        self.manager.set_auto_update(False)
        version = self.manager.get_version()
        self.assertFalse(version["auto_update"])

    def test_get_app_version(self):
        """Test getting specific app version."""
        test_data = {
            "version": "1.0.0",
            "apps": {"mados-installer": "2.0.0"},
        }
        self.manager.set_version(test_data)

        ver = self.manager.get_app_version("mados-installer")
        self.assertEqual(ver, "2.0.0")

        ver = self.manager.get_app_version("unknown-app")
        self.assertEqual(ver, "unknown")

    def test_compare_version(self):
        """Test version comparison."""
        test_data = {"version": "1.5.0"}
        self.manager.set_version(test_data)

        self.assertEqual(self.manager.compare_version("1.0.0"), -1)
        self.assertEqual(self.manager.compare_version("2.0.0"), 1)
        self.assertEqual(self.manager.compare_version("1.5.0"), 0)


class TestBackupManager(unittest.TestCase):
    """Tests for BackupManager."""

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.backup_root = Path(self.temp_dir.name) / "backups"
        self.manager = BackupManager(self.backup_root)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_list_backups_empty(self):
        """Test listing backups when none exist."""
        backups = self.manager.list_backups()
        self.assertEqual(len(backups), 0)

    def test_create_backup(self):
        """Test creating a backup."""
        with patch.object(self.manager, "_backup_apps"):
            backup = self.manager.create_backup("test-backup")
            self.assertIsNotNone(backup)
            self.assertEqual(backup.name, "test-backup")

    def test_cleanup_old_backups(self):
        """Test cleanup of old backups."""
        for i in range(5):
            (self.backup_root / f"backup_{i}").mkdir(parents=True)

        with patch.object(self.manager, "_backup_apps"):
            self.manager.create_backup("new-backup")

        remaining = list(self.backup_root.iterdir())
        self.assertLessEqual(len(remaining), 3)


class TestDownloader(unittest.TestCase):
    """Tests for Downloader."""

    def setUp(self):
        self.downloader = Downloader()

    def test_release_info_dataclass(self):
        """Test ReleaseInfo dataclass."""
        release = ReleaseInfo(
            tag="v1.0.0",
            version="1.0.0",
            version_json={"version": "1.0.0"},
            download_urls={"system.tar.gz": "https://example.com/system.tar.gz"},
            checksums={"system.tar.gz": "abc123"},
        )
        self.assertEqual(release.version, "1.0.0")
        self.assertIn("system.tar.gz", release.download_urls)

    def test_update_info_dataclass(self):
        """Test UpdateInfo dataclass."""
        update_info = UpdateInfo(
            system_update=True,
            app_updates={"mados-installer": ("1.0.0", "2.0.0")},
            latest_version="2.0.0",
            release_date="2025-03-17",
        )
        self.assertTrue(update_info.system_update)
        self.assertEqual(update_info.latest_version, "2.0.0")

    def test_calculate_sha256(self):
        """Test SHA256 calculation."""
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b"test content")
            f.flush()
            temp_path = Path(f.name)

        try:
            hash_value = Downloader._calculate_sha256(temp_path)
            self.assertEqual(len(hash_value), 64)
            self.assertEqual(
                hash_value, "6ae8a75555209fd6c44157c0aed8016e763ff435a19cf186f76863140143ff72"
            )
        finally:
            temp_path.unlink()


class TestDownloaderIntegration(unittest.TestCase):
    """Integration tests for Downloader (requires network)."""

    @unittest.skipIf(not sys.stdout.isatty(), "Skip network tests in non-interactive mode")
    def test_check_for_updates_no_updates(self):
        """Test checking for updates with current version."""
        current = {"version": "999.999.999", "system": {"version": "999.999.999"}, "apps": {}}

        update_info = Downloader.check_for_updates(current, "stable")
        self.assertIsNone(update_info)


if __name__ == "__main__":
    unittest.main()
