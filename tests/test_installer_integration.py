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
SHELLBAR_START = os.path.join(REPO_DIR, "airootfs", "usr", "local", "bin", "mados-shellbar-start")
SHELL_THEME_VALIDATOR = os.path.join(
    REPO_DIR,
    "airootfs",
    "root",
    "customize_airootfs.d",
    "05-shell-theme.sh",
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
        self.assertIn(
            "configure-grub.sh still calls ensure_btrfs_rootflags (duplicates rootflags)",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh still defines ensure_btrfs_rootflags (duplicates rootflags)",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh missing bare subvol token sanitizer",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh still injects bare subvol= kernel args",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh still injects splash in GRUB_CMDLINE_LINUX",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh still injects quiet in GRUB_CMDLINE_LINUX",
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
            "configure-grub.sh missing grub.cfg sanitizer",
            self.apps_script,
        )
        self.assertIn(
            "grub.cfg still contains invalid rootflag= token",
            self.apps_script,
        )
        self.assertIn(
            "grub.cfg still contains invalid bare subvol= token",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh missing grub.cfg rootflag assertion",
            self.apps_script,
        )
        self.assertIn(
            "configure-grub.sh missing grub.cfg bare subvol assertion",
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


class TestShellbarSessionDetection(unittest.TestCase):
    """Shellbar launcher should prefer correct compositor context."""

    def test_hyprland_detection_has_priority_over_sway(self):
        content = _read(SHELLBAR_START)
        self.assertIn('LOG_FILE="${XDG_CACHE_HOME}/mados-shellbar.log"', content)
        self.assertIn("if is_hyprland_session; then", content)
        self.assertIn('echo "hyprland"', content)

    def test_swaysock_requires_real_socket(self):
        content = _read(SHELLBAR_START)
        self.assertIn("has_valid_sway_socket()", content)
        self.assertIn('[[ -S "${SWAYSOCK}" ]]', content)
        self.assertIn("Ignoring stale SWAYSOCK", content)

    def test_theme_launch_retries_before_waybar_fallback(self):
        content = _read(SHELLBAR_START)
        self.assertIn("launch_theme_with_retry()", content)
        self.assertIn("Theme launch attempt", content)
        self.assertIn("Theme launch failed after retries, falling back to waybar", content)

    def test_hyprland_uses_direct_quickshell_last_resort(self):
        content = _read(SHELLBAR_START)
        self.assertIn("launch_quickshell_direct()", content)
        self.assertIn('local state_dir="${runtime_dir}/mados-quickshell"', content)
        self.assertIn('export QS_IPC_FILE="${state_dir}/qs_widget_state"', content)
        self.assertIn('export QS_ACTIVE_WIDGET_FILE="${state_dir}/qs_active_widget"', content)
        self.assertIn(
            'if [[ "${session_type}" == "hyprland" ]] && launch_quickshell_direct; then', content
        )


class TestThemeLayoutContract(unittest.TestCase):
    """Theme install/runtime references must match external imperative-dots layout."""

    def test_customize_runs_imperative_dots_install(self):
        content = _read(CUSTOMIZE_SCRIPT)
        self.assertIn('run_module "03-apps.sh" "install_imperative_dots"', content)

    def test_apps_script_installs_external_theme_and_start_hook(self):
        content = _read(APPS_SCRIPT)
        self.assertIn('IMPERATIVE_DOTS_REPO="madkoding/theme-imperative-dots"', content)
        self.assertIn(
            'IMPERATIVE_DOTS_INSTALL_DIR="/usr/share/mados/themes/imperative-dots"', content
        )
        self.assertIn(
            'if [[ -x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/start.sh" && -x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/healthcheck.sh" ]]; then',
            content,
        )
        self.assertIn('echo "  → Found incomplete imperative-dots install, reinstalling"', content)
        self.assertIn('chmod +x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/start.sh"', content)
        self.assertIn(
            'chmod +x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/healthcheck.sh"', content
        )
        self.assertIn(
            'find "${IMPERATIVE_DOTS_INSTALL_DIR}/config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} +',
            content,
        )
        self.assertNotIn("/usr/share/mados/themes/imperative-dots/.config", content)

    def test_shell_theme_validation_uses_start_script_path(self):
        content = _read(SHELL_THEME_VALIDATOR)
        self.assertIn('"${THEME_INSTALL_DIR}/scripts/start/start.sh"', content)
        self.assertIn('"${THEME_INSTALL_DIR}/scripts/quickshell/Main.qml"', content)
        self.assertIn('"${THEME_INSTALL_DIR}/scripts/quickshell/TopBar.qml"', content)
        self.assertIn('"${THEME_INSTALL_DIR}/config/hypr/scripts/init.sh"', content)

    def test_shellbar_uses_scripts_quickshell_layout(self):
        content = _read(SHELLBAR_START)
        self.assertIn('"${theme_dir}/scripts/quickshell/Main.qml"', content)
        self.assertIn('"${theme_dir}/scripts/quickshell/TopBar.qml"', content)
        self.assertNotIn("/usr/share/mados/themes/imperative-dots/.config", content)

    def test_customize_script_calls_skwd_wall_install(self):
        content = _read(CUSTOMIZE_SCRIPT)
        self.assertIn('run_module "03-apps.sh" "setup_wallpaper_assets"', content)
        self.assertIn('run_module "03-apps.sh" "install_skwd_wall"', content)


if __name__ == "__main__":
    unittest.main()
