#!/usr/bin/env python3
"""Integration checks for madOS <-> mados-installer contract."""

import os
import unittest


REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
APPS_SCRIPT = os.path.join(REPO_DIR, "airootfs", "root", "customize_airootfs.d", "03-apps.sh")
PACKAGES_FILE = os.path.join(REPO_DIR, "packages.x86_64")
AUTOSTART_HELPER = os.path.join(
    REPO_DIR, "airootfs", "usr", "local", "bin", "mados-installer-autostart"
)
TOGGLE_DEMO = os.path.join(REPO_DIR, "airootfs", "usr", "local", "bin", "toggle-demo-mode.sh")
XDG_AUTOSTART = os.path.join(
    REPO_DIR,
    "airootfs",
    "etc",
    "xdg",
    "autostart",
    "mados-installer-autostart.desktop",
)
HYPR_CONF = os.path.join(REPO_DIR, "airootfs", "etc", "skel", ".config", "hypr", "hyprland.conf")
SWAY_CONF = os.path.join(
    REPO_DIR, "airootfs", "etc", "sway", "config.d", "50-installer-autostart.conf"
)
CUSTOMIZE_SCRIPT = os.path.join(REPO_DIR, "airootfs", "root", "customize_airootfs.sh")
THEME_HYPR_CONF = os.path.join(
    REPO_DIR,
    "airootfs",
    "usr",
    "share",
    "mados",
    "themes",
    "imperative-dots",
    ".config",
    "hypr",
    "hyprland.conf",
)
GUIDE_QML = os.path.join(
    REPO_DIR,
    "airootfs",
    "usr",
    "share",
    "mados",
    "themes",
    "imperative-dots",
    ".config",
    "hypr",
    "scripts",
    "quickshell",
    "guide",
    "GuidePopup.qml",
)
WALLPAPER_PICKER_HELPER = os.path.join(
    REPO_DIR, "airootfs", "usr", "local", "bin", "mados-wallpaper-picker"
)


def _read(path):
    with open(path) as f:
        return f.read()


class TestInstallerPinnedReference(unittest.TestCase):
    """Installer source should be pinned and verified for reproducible builds."""

    @classmethod
    def setUpClass(cls):
        cls.apps_script = _read(APPS_SCRIPT)

    def test_installer_ref_tag_and_commit_defined(self):
        self.assertIn('INSTALLER_REF_TAG="', self.apps_script)
        self.assertIn('INSTALLER_REF_COMMIT="', self.apps_script)

    def test_clone_uses_verified_ref_not_main(self):
        self.assertIn("clone_ref_verified", self.apps_script)
        self.assertNotIn(
            'clone_latest_main "https://github.com/${INSTALLER_GITHUB_REPO}/${installer_name}.git"',
            self.apps_script,
        )


class TestInstallerContractChecks(unittest.TestCase):
    """Build script should fail fast if installer contract drifts."""

    @classmethod
    def setUpClass(cls):
        cls.apps_script = _read(APPS_SCRIPT)

    def test_has_explicit_contract_assertions(self):
        self.assertIn("assert_installer_contract()", self.apps_script)
        self.assertIn("Installer contract missing required file", self.apps_script)
        self.assertIn("configure-grub.sh missing ensure_btrfs_rootflags", self.apps_script)
        self.assertIn("configure-grub.sh still forces rootflags=subvol=@", self.apps_script)
        self.assertIn("steps.py missing rsync metadata fallback", self.apps_script)


class TestInstallerRuntimePaths(unittest.TestCase):
    """Runtime scripts should use canonical installer path."""

    def test_autostart_uses_opt_path_for_debug_listing(self):
        content = _read(AUTOSTART_HELPER)
        self.assertIn("/opt/mados/mados_installer/", content)
        self.assertNotIn("/usr/local/lib/mados_installer", content)

    def test_toggle_demo_uses_opt_path(self):
        content = _read(TOGGLE_DEMO)
        self.assertIn('CONFIG="/opt/mados/mados_installer/config.py"', content)


class TestSecureBootPrereqs(unittest.TestCase):
    """Package list should include Secure Boot user-mode dependencies."""

    def test_required_packages_present(self):
        packages = _read(PACKAGES_FILE)
        self.assertIn("\nsbctl\n", packages)
        self.assertIn("\nshim\n", packages)
        self.assertIn("\nmokutil\n", packages)


class TestAutostartStrategy(unittest.TestCase):
    """Compositor autostart is primary; XDG entry should be disabled."""

    def test_compositor_autostart_entries_exist(self):
        self.assertIn("mados-installer-autostart", _read(HYPR_CONF))
        self.assertIn("mados-installer-autostart", _read(SWAY_CONF))

    def test_xdg_autostart_is_disabled(self):
        content = _read(XDG_AUTOSTART)
        self.assertIn("X-GNOME-Autostart-enabled=false", content)
        self.assertIn("Hidden=true", content)


class TestSkwdWallIntegration(unittest.TestCase):
    """Validate skwd-wall wiring across build and runtime configs."""

    def test_customize_script_calls_skwd_wall_install(self):
        content = _read(CUSTOMIZE_SCRIPT)
        self.assertIn('run_module "03-apps.sh" "setup_wallpaper_assets"', content)
        self.assertIn('run_module "03-apps.sh" "install_skwd_wall"', content)

    def test_hypr_bindings_use_wallpaper_picker_helper(self):
        self.assertIn("mados-wallpaper-picker toggle", _read(HYPR_CONF))
        self.assertIn("mados-wallpaper-picker toggle", _read(THEME_HYPR_CONF))

    def test_guide_uses_wallpaper_picker_helper(self):
        guide = _read(GUIDE_QML)
        self.assertIn("mados-wallpaper-picker toggle", guide)
        self.assertNotIn("qs_manager.sh toggle wallpaper", guide)

    def test_wallpaper_picker_helper_exists_with_fallback_path(self):
        content = _read(WALLPAPER_PICKER_HELPER)
        self.assertIn("#!/usr/bin/env bash", content)
        self.assertIn('SKWD_DAEMON="/opt/mados/skwd-wall/daemon.qml"', content)
        self.assertIn('quickshell ipc -p "$SKWD_DAEMON"', content)


if __name__ == "__main__":
    unittest.main()
