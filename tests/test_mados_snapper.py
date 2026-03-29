#!/usr/bin/env python3
"""
Tests for madOS snapper integration and Btrfs snapshot support.

Validates:
- mados-snapper script exists and has correct structure
- snapper package is included in packages.x86_64
- snapper configuration files exist
- systemd units for automatic snapshots
"""

import os
import subprocess
import sys
import unittest

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AIROOTFS = os.path.join(REPO_DIR, "airootfs")
BIN_DIR = os.path.join(AIROOTFS, "usr", "local", "bin")


class TestMadosSnapperScript(unittest.TestCase):
    """Verify mados-snapper script exists and has correct structure."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "mados-snapper")
        if not os.path.isfile(self.script_path):
            self.skipTest("mados-snapper script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-snapper must exist."""
        self.assertTrue(os.path.isfile(self.script_path))

    def test_valid_bash_syntax(self):
        """mados-snapper must have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", self.script_path],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Bash syntax error: {result.stderr}",
        )

    def test_has_shebang(self):
        """Script must start with a bash shebang."""
        first_line = self.content.splitlines()[0]
        self.assertTrue(first_line.startswith("#!"), "Must start with #!")
        self.assertIn("bash", first_line, "Must use bash")

    def test_supports_list_command(self):
        """Script must support 'list' command."""
        self.assertIn("list_snapshots", self.content, "Must have list_snapshots function")

    def test_supports_create_command(self):
        """Script must support 'create' command."""
        self.assertIn("create_snapshot", self.content, "Must have create_snapshot function")

    def test_supports_rollback_command(self):
        """Script must support 'rollback' command."""
        self.assertIn("rollback", self.content, "Must have rollback function")

    def test_supports_status_command(self):
        """Script must support 'status' command."""
        self.assertIn("status", self.content, "Must have status function")


class TestMadosAutoinstallScript(unittest.TestCase):
    """Verify mados-autoinstall script exists and has correct structure."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "mados-autoinstall")
        if not os.path.isfile(self.script_path):
            self.skipTest("mados-autoinstall script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-autoinstall must exist."""
        self.assertTrue(os.path.isfile(self.script_path))

    def test_valid_bash_syntax(self):
        """mados-autoinstall must have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", self.script_path],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Bash syntax error: {result.stderr}",
        )

    def test_has_shebang(self):
        """Script must start with a bash shebang."""
        first_line = self.content.splitlines()[0]
        self.assertTrue(first_line.startswith("#!"), "Must start with #!")
        self.assertIn("bash", first_line, "Must use bash")

    def test_calls_mados_chwd(self):
        """Script must call mados-chwd for GPU configuration."""
        self.assertIn("mados-chwd", self.content, "Must call mados-chwd")

    def test_configures_btrfs_snapshots(self):
        """Script must configure Btrfs snapshots."""
        self.assertIn("snapper", self.content, "Must configure snapper")

    def test_enables_services(self):
        """Script must enable system services."""
        self.assertIn("systemctl", self.content, "Must enable services")


class TestSnapperPackage(unittest.TestCase):
    """Verify snapper package is included in ISO."""

    def setUp(self):
        pkg_file = os.path.join(REPO_DIR, "packages.x86_64")
        if not os.path.isfile(pkg_file):
            self.skipTest("packages.x86_64 not found")
        with open(pkg_file) as f:
            self.packages = [
                line.strip() for line in f if line.strip() and not line.startswith("#")
            ]

    def test_snapper_included(self):
        """snapper must be in packages.x86_64."""
        self.assertIn("snapper", self.packages, "packages.x86_64 must include snapper")

    def test_btrfs_progs_included(self):
        """btrfs-progs must be in packages.x86_64."""
        self.assertIn("btrfs-progs", self.packages, "packages.x86_64 must include btrfs-progs")


class TestSnapperConfig(unittest.TestCase):
    """Verify snapper configuration files exist."""

    def test_snapper_config_exists(self):
        """Snapper root config must exist."""
        config_path = os.path.join(AIROOTFS, "etc", "snapper", "configs", "root")
        self.assertTrue(
            os.path.isfile(config_path),
            "etc/snapper/configs/root must exist",
        )

    def test_snapper_config_has_timeline(self):
        """Snapper config must have timeline settings."""
        config_path = os.path.join(AIROOTFS, "etc", "snapper", "configs", "root")
        if not os.path.isfile(config_path):
            self.skipTest("Snapper config not found")
        with open(config_path) as f:
            content = f.read()
        self.assertIn("TIMELINE", content, "Config must have timeline settings")


class TestSnapperSystemdUnits(unittest.TestCase):
    """Verify snapper systemd units exist."""

    def setUp(self):
        self.systemd_dir = os.path.join(AIROOTFS, "etc", "systemd", "system")

    def test_snapper_service_exists(self):
        """mados-snapper.service must exist."""
        service_path = os.path.join(self.systemd_dir, "mados-snapper.service")
        self.assertTrue(
            os.path.isfile(service_path),
            "mados-snapper.service must exist",
        )

    def test_snapper_timer_exists(self):
        """mados-snapper.timer must exist."""
        timer_path = os.path.join(self.systemd_dir, "mados-snapper.timer")
        self.assertTrue(
            os.path.isfile(timer_path),
            "mados-snapper.timer must exist",
        )

    def test_snapper_service_is_oneshot(self):
        """mados-snapper.service must be Type=oneshot."""
        service_path = os.path.join(self.systemd_dir, "mados-snapper.service")
        if not os.path.isfile(service_path):
            self.skipTest("mados-snapper.service not found")
        with open(service_path) as f:
            content = f.read()
        self.assertIn("Type=oneshot", content, "Service must be Type=oneshot")

    def test_snapper_timer_is_daily(self):
        """mados-snapper.timer must trigger daily."""
        timer_path = os.path.join(self.systemd_dir, "mados-snapper.timer")
        if not os.path.isfile(timer_path):
            self.skipTest("mados-snapper.timer not found")
        with open(timer_path) as f:
            content = f.read()
        self.assertIn("OnCalendar=daily", content, "Timer must trigger daily")


class TestProfiledefIncludesSnapperFiles(unittest.TestCase):
    """Verify profiledef.sh includes permissions for snapper files."""

    def setUp(self):
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        if not os.path.isfile(profiledef):
            self.skipTest("profiledef.sh not found")
        with open(profiledef) as f:
            self.content = f.read()

    def test_includes_mados_snapper(self):
        """profiledef.sh must include mados-snapper."""
        self.assertIn(
            "mados-snapper",
            self.content,
            "profiledef.sh must include mados-snapper",
        )

    def test_includes_mados_autoinstall(self):
        """profiledef.sh must include mados-autoinstall."""
        self.assertIn(
            "mados-autoinstall",
            self.content,
            "profiledef.sh must include mados-autoinstall",
        )

    def test_includes_snapper_service(self):
        """profiledef.sh must include mados-snapper.service."""
        self.assertIn(
            "mados-snapper.service",
            self.content,
            "profiledef.sh must include mados-snapper.service",
        )

    def test_includes_snapper_timer(self):
        """profiledef.sh must include mados-snapper.timer."""
        self.assertIn(
            "mados-snapper.timer",
            self.content,
            "profiledef.sh must include mados-snapper.timer",
        )


if __name__ == "__main__":
    unittest.main()
