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
SKWD_DAEMON_HELPER = os.path.join(
    REPO_DIR, "airootfs", "usr", "local", "bin", "mados-skwd-wall-daemon"
)
SKWD_SOURCES_HELPER = os.path.join(
    REPO_DIR, "airootfs", "usr", "local", "bin", "mados-skwd-wall-sources"
)
SKWD_DOCTOR_HELPER = os.path.join(
    REPO_DIR, "airootfs", "usr", "local", "bin", "mados-skwd-wall-doctor"
)
SKWD_SERVICE = os.path.join(
    REPO_DIR,
    "airootfs",
    "etc",
    "skel",
    ".config",
    "systemd",
    "user",
    "skwd-wall.service",
)
QS_MANAGER = os.path.join(
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
    "qs_manager.sh",
)


def _read(path):
    with open(path) as f:
        return f.read()


class TestInstallerTagReference(unittest.TestCase):
    """Installer source should resolve dynamically from the latest tag."""

    @classmethod
    def setUpClass(cls):
        cls.apps_script = _read(APPS_SCRIPT)

    def test_installer_tag_pattern_defined(self):
        self.assertIn('INSTALLER_TAG_PATTERN="', self.apps_script)

    def test_clone_uses_latest_tag_not_main(self):
        self.assertIn("clone_latest_tag", self.apps_script)
        self.assertIn("resolve_latest_tag", self.apps_script)
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
        self.assertIn(
            "configure-grub.sh missing bare subvol token sanitizer",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh still injects bare subvol= kernel args",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh missing ensure_btrfs_rootflags call",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh missing GRUB_CMDLINE_LINUX sanitizer call",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh missing GRUB_CMDLINE_LINUX_DEFAULT sanitizer call",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh still injects legacy rootflag= token",
            self.apps_script,
        )
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

    def test_apps_script_keeps_opt_compat_symlink(self):
        content = _read(APPS_SCRIPT)
        self.assertIn('SKWD_WALL_COMPAT_DIR="/opt/mados/skwd-wall"', content)
        self.assertIn('ln -s "$SKWD_WALL_INSTALL_DIR" "$SKWD_WALL_COMPAT_DIR"', content)

    def test_apps_script_uses_madkoding_skwd_fork(self):
        content = _read(APPS_SCRIPT)
        self.assertIn('SKWD_WALL_REPO="madkoding/skwd-wall"', content)
        self.assertNotIn('SKWD_WALL_REPO="liixini/skwd-wall"', content)
        self.assertNotIn("WallhavenBrowser.qml", content)
        self.assertNotIn("SteamWorkshopBrowser.qml", content)

    def test_hypr_bindings_use_wallpaper_picker_helper(self):
        self.assertIn("mados-wallpaper-picker toggle", _read(HYPR_CONF))
        self.assertIn("mados-wallpaper-picker toggle", _read(THEME_HYPR_CONF))
        self.assertIn("mados-wallpaper-picker web", _read(HYPR_CONF))
        self.assertIn("mados-wallpaper-picker web", _read(THEME_HYPR_CONF))

    def test_hypr_autostart_starts_skwd_wall_daemon(self):
        self.assertIn("systemctl --user start skwd-wall.service", _read(HYPR_CONF))
        self.assertIn("systemctl --user start skwd-wall.service", _read(THEME_HYPR_CONF))

    def test_guide_uses_wallpaper_picker_helper(self):
        guide = _read(GUIDE_QML)
        self.assertIn("mados-wallpaper-picker toggle", guide)
        self.assertIn("mados-wallpaper-picker web", guide)
        self.assertNotIn("qs_manager.sh toggle wallpaper", guide)

    def test_wallpaper_picker_helper_exists_with_fallback_path(self):
        content = _read(WALLPAPER_PICKER_HELPER)
        self.assertIn("#!/usr/bin/env bash", content)
        self.assertIn('DAEMON_QML="/usr/local/share/skwd-wall/daemon.qml"', content)
        self.assertIn('quickshell ipc -p "$DAEMON_QML"', content)
        self.assertIn('systemctl --user start "$SERVICE_NAME"', content)

    def test_skwd_helpers_exist_and_use_canonical_layout(self):
        daemon_helper = _read(SKWD_DAEMON_HELPER)
        self.assertIn("/usr/local/share/skwd-wall/daemon.qml", daemon_helper)
        self.assertIn('SKWD_WALL_INSTALL="/usr/local/share/skwd-wall"', daemon_helper)
        self.assertIn("mados-skwd-wall-sources prepare", daemon_helper)

        sources_helper = _read(SKWD_SOURCES_HELPER)
        self.assertIn("wallpaperSources", sources_helper)
        self.assertIn("wallpaper-union", sources_helper)
        self.assertIn("source-sync-state.json", sources_helper)
        self.assertIn("SYNC_THROTTLE_SECONDS", sources_helper)
        self.assertIn("file_fingerprint", sources_helper)
        self.assertIn("seen_fingerprints", sources_helper)
        self.assertIn('"/usr/share/backgrounds"', sources_helper)
        self.assertIn('"/usr/share/mados/wallpapers"', sources_helper)

        doctor_helper = _read(SKWD_DOCTOR_HELPER)
        self.assertIn("/usr/local/share/skwd-wall/daemon.qml", doctor_helper)
        self.assertIn("journalctl --user -u skwd-wall.service", doctor_helper)

    def test_skwd_user_service_exists(self):
        content = _read(SKWD_SERVICE)
        self.assertIn("ExecStart=/usr/local/bin/mados-skwd-wall-daemon", content)
        self.assertIn("Restart=on-failure", content)

    def test_qs_manager_routes_wallpaper_to_skwd_wall(self):
        content = _read(QS_MANAGER)
        self.assertIn('if [[ "$TARGET" == "wallpaper" ]]; then', content)
        self.assertIn("mados-wallpaper-picker toggle", content)
        self.assertIn("mados-wallpaper-picker open", content)
        self.assertIn("mados-wallpaper-picker close", content)


if __name__ == "__main__":
    unittest.main()
