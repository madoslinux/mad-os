#!/usr/bin/env python3
"""
Tests for madOS DE/WM selector tools.

Validates:
- mados-rate-mirrors script exists and has correct structure
- mados-select-desktop script exists and has correct structure
- New DE/WM packages are included
- GTK4 and dependencies are included
"""

import os
import subprocess
import sys
import unittest

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AIROOTFS = os.path.join(REPO_DIR, "airootfs")
BIN_DIR = os.path.join(AIROOTFS, "usr", "local", "bin")


class TestMadosRateMirrorsScript(unittest.TestCase):
    """Verify mados-rate-mirrors script exists and has correct structure."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "mados-rate-mirrors")
        if not os.path.isfile(self.script_path):
            self.skipTest("mados-rate-mirrors script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-rate-mirrors must exist."""
        self.assertTrue(os.path.isfile(self.script_path))

    def test_valid_bash_syntax(self):
        """mados-rate-mirrors must have valid bash syntax."""
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

    def test_uses_curl(self):
        """Script must use curl for testing mirror speeds."""
        self.assertIn("curl", self.content, "Must use curl for speed testing")

    def test_modifies_mirrorlist(self):
        """Script must modify /etc/pacman.d/mirrorlist."""
        self.assertIn("/etc/pacman.d/mirrorlist", self.content, "Must modify mirrorlist")


class TestMadosSelectDesktopScript(unittest.TestCase):
    """Verify mados-select-desktop script exists and has correct structure."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "mados-select-desktop")
        if not os.path.isfile(self.script_path):
            self.skipTest("mados-select-desktop script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-select-desktop must exist."""
        self.assertTrue(os.path.isfile(self.script_path))

    def test_valid_bash_syntax(self):
        """mados-select-desktop must have valid bash syntax."""
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
        self.assertIn("list_desktops", self.content, "Must have list_desktops function")

    def test_supports_set_command(self):
        """Script must support 'set' command."""
        self.assertIn("set_desktop", self.content, "Must have set_desktop function")

    def test_lists_available_desktops(self):
        """Script must list available desktops."""
        self.assertIn("hyprland", self.content, "Must list hyprland")
        self.assertIn("sway", self.content, "Must list sway")
        self.assertIn("kde", self.content, "Must list kde")
        self.assertIn("xfce", self.content, "Must list xfce")


class TestWelcomeAppDependencies(unittest.TestCase):
    def setUp(self):
        pkg_file = os.path.join(REPO_DIR, "packages.x86_64")
        if not os.path.isfile(pkg_file):
            self.skipTest("packages.x86_64 not found")
        with open(pkg_file) as f:
            self.packages = [
                line.strip() for line in f if line.strip() and not line.startswith("#")
            ]

    def test_gtk4_included(self):
        """gtk4 must be in packages.x86_64."""
        self.assertIn("gtk4", self.packages, "packages.x86_64 must include gtk4")

    def test_libadwaita_included(self):
        """libadwaita must be in packages.x86_64."""
        self.assertIn("libadwaita", self.packages, "packages.x86_64 must include libadwaita")


class TestProfiledefIncludesWelcomeFiles(unittest.TestCase):
    """Verify profiledef.sh includes permissions for tool files."""

    def setUp(self):
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        if not os.path.isfile(profiledef):
            self.skipTest("profiledef.sh not found")
        with open(profiledef) as f:
            self.content = f.read()

    def test_includes_mados_rate_mirrors(self):
        """profiledef.sh must include mados-rate-mirrors."""
        self.assertIn(
            "mados-rate-mirrors",
            self.content,
            "profiledef.sh must include mados-rate-mirrors",
        )

    def test_includes_mados_select_desktop(self):
        """profiledef.sh must include mados-select-desktop."""
        self.assertIn(
            "mados-select-desktop",
            self.content,
            "profiledef.sh must include mados-select-desktop",
        )


if __name__ == "__main__":
    unittest.main()
