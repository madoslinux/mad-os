#!/usr/bin/env python3
"""
Tests for madOS installer contract validation.

Validates that the mados-installer external repository contract remains compatible with
the dynamic latest-tag fetch strategy in 03-apps.sh.

These tests verify that:
1. The installer repository has at least one version tag
2. Required files exist in the latest tagged source
3. Patches expected by 03-apps.sh remain applicable/checked (GRUB hardening, rsync fallback, no iwd)
"""

import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_DIR = Path(__file__).parent.parent.resolve()
INSTALLER_REPO_URL = "https://github.com/madoslinux/mados-installer.git"

REQUIRED_FILES = [
    "__main__.py",
    "installer/steps.py",
    "scripts/configure-grub.sh",
    "scripts/setup-bootloader.sh",
    "scripts/apply-configuration.sh",
    "scripts/enable-services.sh",
]


def resolve_latest_tag() -> str:
    result = subprocess.run(
        ["git", "ls-remote", "--refs", "--tags", INSTALLER_REPO_URL, "v*"],
        capture_output=True,
        text=True,
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
    )
    if result.returncode != 0:
        raise RuntimeError(f"git ls-remote failed: {result.stderr}")

    tags = []
    for line in result.stdout.splitlines():
        parts = line.strip().split()
        if len(parts) != 2:
            continue
        ref = parts[1]
        if ref.startswith("refs/tags/"):
            tags.append(ref.removeprefix("refs/tags/"))

    if not tags:
        raise RuntimeError("No installer tags found matching pattern v*")

    def key(tag: str):
        nums = [int(x) for x in re.findall(r"\d+", tag)]
        return nums if nums else [0]

    return sorted(tags, key=key)[-1]


class TestInstallerRepoTags(unittest.TestCase):
    """Verify installer repo exposes tags and latest tag resolves."""

    def test_latest_installer_tag_resolves_to_commit(self):
        latest_tag = resolve_latest_tag()
        result = subprocess.run(
            [
                "git",
                "ls-remote",
                INSTALLER_REPO_URL,
                f"refs/tags/{latest_tag}",
                f"refs/tags/{latest_tag}^{{}}",
            ],
            capture_output=True,
            text=True,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
        self.assertEqual(result.returncode, 0, f"git ls-remote failed: {result.stderr}")
        self.assertTrue(
            result.stdout.strip(), f"Latest tag {latest_tag} did not resolve to any commit"
        )


class TestInstallerRepoSource(unittest.TestCase):
    """Verify source of truth: installer repo at latest resolved tag."""

    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.mkdtemp(prefix="mados_test_installer_")
        cls.clone_dir = Path(cls.temp_dir) / "mados_installer"
        cls.latest_tag = resolve_latest_tag()

        result = subprocess.run(
            [
                "git",
                "clone",
                "--depth=1",
                "--branch",
                cls.latest_tag,
                "--single-branch",
                INSTALLER_REPO_URL,
                str(cls.clone_dir),
            ],
            capture_output=True,
            text=True,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"Failed to clone installer repo at {cls.latest_tag}: {result.stderr}"
            )

        cls.work_dir = cls.clone_dir

    @classmethod
    def tearDownClass(cls):
        import shutil

        shutil.rmtree(cls.temp_dir, ignore_errors=True)

    def test_required_files_exist(self):
        for file_rel in REQUIRED_FILES:
            path = self.work_dir / file_rel
            with self.subTest(file=file_rel):
                self.assertTrue(
                    path.is_file(),
                    f"Required file missing: {file_rel} (cloned from {INSTALLER_REPO_URL}@{self.latest_tag})",
                )

    def test_configure_grub_has_ensure_btrfs_rootflags(self):
        content = (self.work_dir / "scripts/configure-grub.sh").read_text()
        self.assertIn("ensure_btrfs_rootflags()", content)

    def test_steps_has_rsync_fallback(self):
        content = (self.work_dir / "installer/steps.py").read_text()
        self.assertIn("retrying without ACL/xattr", content)

    def test_apply_configuration_no_iwd_backend(self):
        content = (self.work_dir / "scripts/apply-configuration.sh").read_text()
        self.assertNotIn("wifi.backend=iwd", content)

    def test_enable_services_no_iwd(self):
        content = (self.work_dir / "scripts/enable-services.sh").read_text()
        self.assertNotIn("enable_service iwd", content)


class Test03AppsShContract(unittest.TestCase):
    """Verify 03-apps.sh applies/asserts contract checks."""

    def test_installer_contract_assertions_in_03_apps(self):
        script_path = REPO_DIR / "airootfs/root/customize_airootfs.d/03-apps.sh"
        content = script_path.read_text()

        assertions = [
            ("INSTALLER_TAG_PATTERN=", "latest-tag installer strategy"),
            ("resolve_latest_tag", "latest tag resolution helper"),
            ("clone_latest_tag", "latest tag clone helper"),
            ("ensure_btrfs_rootflags", "GRUB cmdline hardening"),
            ("Drop malformed bare subvol= tokens", "remove bare subvol kernel args"),
            ("still injects bare subvol= kernel args", "reject bare subvol injection"),
            ("missing ensure_btrfs_rootflags call", "require ensure_btrfs_rootflags invocation"),
            (
                "missing GRUB_CMDLINE_LINUX sanitizer call",
                "sanitize GRUB_CMDLINE_LINUX bare subvol args",
            ),
            (
                "missing GRUB_CMDLINE_LINUX_DEFAULT sanitizer call",
                "sanitize GRUB_CMDLINE_LINUX_DEFAULT bare subvol args",
            ),
            ("retrying without ACL/xattr", "rsync VFAT fallback"),
            ("wifi.backend=iwd", "iwd backend removal"),
            ("enable_service iwd", "iwd service removal"),
            ("autologin-live.conf", "SDDM live autologin cleanup"),
            ("Current=pixel-night-city", "SDDM theme pin on installed system"),
            ("Current=sddm-astron_theme", "astron SDDM theme replacement"),
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
