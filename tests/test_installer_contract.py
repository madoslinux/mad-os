#!/usr/bin/env python3
"""
Tests for madOS installer contract validation.

Validates that the mados-installer external repository has the expected
contract requirements met at the pinned commit (v1.0.4 / 259d14cb722f86ef17aa6a8e5f265ea88020ee38).

These tests verify that:
1. The installer repo is at the expected commit
2. Required files exist
3. Patches applied by 03-apps.sh are in place (hardened GRUB cmdline, rsync fallback, no iwd)
"""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_DIR = Path(__file__).parent.parent.resolve()
INSTALLER_SCRIPTS_DIR = REPO_DIR / "airootfs/usr/local/lib/mados_installer/scripts"

INSTALLER_TAG = "v1.0.4"
INSTALLER_COMMIT = "259d14cb722f86ef17aa6a8e5f265ea88020ee38"
INSTALLER_REPO_URL = "https://github.com/madoslinux/mados-installer.git"

REQUIRED_FILES = [
    "__main__.py",
    "installer/steps.py",
    "scripts/configure-grub.sh",
    "scripts/setup-bootloader.sh",
    "scripts/apply-configuration.sh",
    "scripts/enable-services.sh",
]


class TestInstallerRepoCommit(unittest.TestCase):
    """Verify installer repo resolves to expected commit."""

    def test_installer_tag_resolves_to_commit(self):
        """The v1.0.4 tag should resolve to the expected commit hash."""
        tag_ref = f"refs/tags/{INSTALLER_TAG}" + "^{}"
        result = subprocess.run(
            ["git", "ls-remote", INSTALLER_REPO_URL, tag_ref],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"git ls-remote failed: {result.stderr}")
        actual_commit = result.stdout.strip().split()[0]
        self.assertEqual(
            actual_commit,
            INSTALLER_COMMIT,
            f"Installer tag {INSTALLER_TAG} resolves to {actual_commit}, "
            f"expected {INSTALLER_COMMIT}. Update INSTALLER_REF_COMMIT in 03-apps.sh or "
            "update INSTALLER_COMMIT in this test.",
        )


class TestInstallerRepoSource(unittest.TestCase):
    """Verify source of truth: original installer repo at pinned commit."""

    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.mkdtemp(prefix="mados_test_installer_")
        cls.clone_dir = Path(cls.temp_dir) / "mados_installer"

        result = subprocess.run(
            ["git", "clone", "--depth=1", "--no-tags", INSTALLER_REPO_URL, str(cls.clone_dir)],
            capture_output=True,
            text=True,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
        if result.returncode != 0:
            raise RuntimeError(f"Failed to clone installer repo: {result.stderr}")

        result = subprocess.run(
            ["git", "-C", str(cls.clone_dir), "fetch", "--depth=1", "origin", INSTALLER_COMMIT],
            capture_output=True,
            text=True,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
        if result.returncode != 0:
            raise RuntimeError(f"Failed to fetch commit {INSTALLER_COMMIT}: {result.stderr}")

        result = subprocess.run(
            ["git", "-C", str(cls.clone_dir), "checkout", "--detach", "FETCH_HEAD"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Failed to checkout commit: {result.stderr}")

        cls.work_dir = cls.clone_dir

    @classmethod
    def tearDownClass(cls):
        import shutil

        shutil.rmtree(cls.temp_dir, ignore_errors=True)

    def test_required_files_exist(self):
        """All required installer files should exist."""
        for file_rel in REQUIRED_FILES:
            path = self.work_dir / file_rel
            with self.subTest(file=file_rel):
                self.assertTrue(
                    path.is_file(),
                    f"Required file missing: {file_rel} (cloned from {INSTALLER_REPO_URL}@{INSTALLER_COMMIT})",
                )

    def test_configure_grub_has_ensure_btrfs_rootflags(self):
        """configure-grub.sh should have ensure_btrfs_rootflags function."""
        path = self.work_dir / "scripts/configure-grub.sh"
        content = path.read_text()
        self.assertIn(
            "ensure_btrfs_rootflags()",
            content,
            "configure-grub.sh missing ensure_btrfs_rootflags() function",
        )

    def test_configure_grub_source_has_legacy_subvol_bug(self):
        """configure-grub.sh source at pinned commit has the legacy rootflags=subvol=@ bug.

        This bug causes incorrect GRUB cmdline for non-btrfs installations.
        03-apps.sh patches this by replacing the if/else with ensure_btrfs_rootflags().
        """
        path = self.work_dir / "scripts/configure-grub.sh"
        content = path.read_text()
        self.assertIn(
            'rootflags=subvol=@"',
            content,
            "configure-grub.sh source at pinned commit should have legacy subvol=@ bug "
            "(03-apps.sh patches this - this test verifies the bug exists in source)",
        )

    def test_steps_has_rsync_fallback(self):
        """steps.py should have rsync metadata fallback for VFAT /boot."""
        path = self.work_dir / "installer/steps.py"
        content = path.read_text()
        self.assertIn(
            "retrying without ACL/xattr",
            content,
            "steps.py missing rsync metadata fallback for VFAT filesystem",
        )

    def test_apply_configuration_no_iwd_backend(self):
        """apply-configuration.sh should not force iwd backend."""
        path = self.work_dir / "scripts/apply-configuration.sh"
        content = path.read_text()
        self.assertNotIn(
            "wifi.backend=iwd",
            content,
            "apply-configuration.sh still forces iwd backend",
        )

    def test_enable_services_no_iwd(self):
        """enable-services.sh should not enable iwd service."""
        path = self.work_dir / "scripts/enable-services.sh"
        content = path.read_text()
        self.assertNotIn(
            "enable_service iwd",
            content,
            "enable-services.sh still enables iwd service",
        )


class Test03AppsShContract(unittest.TestCase):
    """Verify 03-apps.sh applies patches correctly to installer code."""

    def test_installer_contract_assertions_in_03_apps(self):
        """03-apps.sh should have contract assertions for all required patches."""
        script_path = REPO_DIR / "airootfs/root/customize_airootfs.d/03-apps.sh"
        content = script_path.read_text()

        assertions = [
            ("ensure_btrfs_rootflags", "GRUB cmdline hardening"),
            ("retrying without ACL/xattr", "rsync VFAT fallback"),
            ("wifi.backend=iwd", "iwd backend removal"),
            ("enable_service iwd", "iwd service removal"),
        ]

        for pattern, description in assertions:
            with self.subTest(pattern=pattern):
                self.assertIn(
                    pattern,
                    content,
                    f"03-apps.sh missing contract check for {description}",
                )


if __name__ == "__main__":
    unittest.main(verbosity=2)
