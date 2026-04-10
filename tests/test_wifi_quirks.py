#!/usr/bin/env python3
"""Tests for hardware-conditional hardware quirks framework."""

import os
import subprocess
import tempfile
import unittest


REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AIROOTFS = os.path.join(REPO_DIR, "airootfs")
SCRIPT_PATH = os.path.join(AIROOTFS, "usr", "local", "bin", "mados-hw-quirks.sh")
SERVICE_PATH = os.path.join(AIROOTFS, "etc", "systemd", "system", "mados-hw-quirks.service")
QUIRKS_DIR = os.path.join(AIROOTFS, "usr", "local", "lib", "mados-hw-quirks.d")
QUIRKS_LIB_PATH = os.path.join(AIROOTFS, "usr", "local", "lib", "mados-hw-quirks-lib.sh")
RTL_QUIRK_PATH = os.path.join(QUIRKS_DIR, "10-rtl8723de-rtw88.sh")
INTEL_WIFI_QUIRK_PATH = os.path.join(QUIRKS_DIR, "20-intel-wifi-power-save-off.sh")
RTL8821CE_QUIRK_PATH = os.path.join(QUIRKS_DIR, "21-realtek-rtl8821ce.sh")
I915_QUIRK_PATH = os.path.join(QUIRKS_DIR, "30-intel-i915-legacy-stability.sh")
AMDGPU_QUIRK_PATH = os.path.join(QUIRKS_DIR, "31-amdgpu-stability.sh")
NVME_QUIRK_PATH = os.path.join(QUIRKS_DIR, "40-nvme-conservative-power.sh")
AUDIO_HDA_QUIRK_PATH = os.path.join(QUIRKS_DIR, "50-audio-hda-fallback.sh")
AUDIO_SOF_QUIRK_PATH = os.path.join(QUIRKS_DIR, "51-audio-sof-to-hda-fallback.sh")
USB_WIFI_QUIRK_PATH = os.path.join(QUIRKS_DIR, "60-usb-wifi-autosuspend-off.sh")
ACPI_BACKLIGHT_QUIRK_PATH = os.path.join(QUIRKS_DIR, "70-acpi-backlight-dmi.sh")
SUSPEND_S2IDLE_QUIRK_PATH = os.path.join(QUIRKS_DIR, "80-suspend-prefer-s2idle-dmi.sh")
SUSPEND_NET_QUIRK_PATH = os.path.join(QUIRKS_DIR, "81-suspend-resume-network-reset.sh")
SLEEP_HOOK_PATH = os.path.join(
    AIROOTFS, "usr", "lib", "systemd", "system-sleep", "mados-resume-network-reset"
)
PROFILEDEF_PATH = os.path.join(REPO_DIR, "profiledef.sh")
NETWORK_MODULE_PATH = os.path.join(AIROOTFS, "root", "customize_airootfs.d", "06-network.sh")
AUTOINSTALL_PATH = os.path.join(AIROOTFS, "usr", "local", "bin", "mados-autoinstall")


class TestHwQuirksRunner(unittest.TestCase):
    """Validate mados-hw-quirks runner structure and behavior markers."""

    def setUp(self):
        if not os.path.isfile(SCRIPT_PATH):
            self.skipTest("mados-hw-quirks.sh not found")
        with open(SCRIPT_PATH) as f:
            self.content = f.read()

    def test_script_exists(self):
        self.assertTrue(os.path.isfile(SCRIPT_PATH))

    def test_valid_bash_syntax(self):
        result = subprocess.run(["bash", "-n", SCRIPT_PATH], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, f"Bash syntax error: {result.stderr}")

    def test_uses_strict_mode(self):
        self.assertIn("set -euo pipefail", self.content)

    def test_has_disable_switch(self):
        self.assertIn("mados.disable_quirks=1", self.content)

    def test_supports_group_disable_switch(self):
        self.assertIn("mados.disable_quirks=", self.content)

    def test_uses_quirks_directory(self):
        self.assertIn("/usr/local/lib/mados-hw-quirks.d", self.content)


class TestHwQuirksService(unittest.TestCase):
    """Validate systemd integration for hardware quirks service."""

    def test_service_exists(self):
        self.assertTrue(os.path.isfile(SERVICE_PATH))

    def test_service_content(self):
        with open(SERVICE_PATH) as f:
            content = f.read()

        self.assertIn("Type=oneshot", content)
        self.assertIn("ExecStart=/usr/local/bin/mados-hw-quirks.sh", content)
        self.assertIn("Before=NetworkManager.service", content)
        self.assertIn("WantedBy=multi-user.target", content)


class TestHwQuirksWiring(unittest.TestCase):
    """Validate build-time wiring for permissions and service enabling."""

    def test_profiledef_contains_permissions(self):
        with open(PROFILEDEF_PATH) as f:
            content = f.read()

        self.assertIn("mados-hw-quirks.sh", content)
        self.assertIn("mados-hw-quirks.service", content)
        self.assertIn("mados-hw-quirks-lib.sh", content)
        self.assertIn("mados-hw-quirks.d/10-rtl8723de-rtw88.sh", content)
        self.assertIn("mados-hw-quirks.d/20-intel-wifi-power-save-off.sh", content)
        self.assertIn("mados-hw-quirks.d/21-realtek-rtl8821ce.sh", content)
        self.assertIn("mados-hw-quirks.d/30-intel-i915-legacy-stability.sh", content)
        self.assertIn("mados-hw-quirks.d/31-amdgpu-stability.sh", content)
        self.assertIn("mados-hw-quirks.d/40-nvme-conservative-power.sh", content)
        self.assertIn("mados-hw-quirks.d/50-audio-hda-fallback.sh", content)
        self.assertIn("mados-hw-quirks.d/51-audio-sof-to-hda-fallback.sh", content)
        self.assertIn("mados-hw-quirks.d/60-usb-wifi-autosuspend-off.sh", content)
        self.assertIn("mados-hw-quirks.d/70-acpi-backlight-dmi.sh", content)
        self.assertIn("mados-hw-quirks.d/80-suspend-prefer-s2idle-dmi.sh", content)
        self.assertIn("mados-hw-quirks.d/81-suspend-resume-network-reset.sh", content)
        self.assertIn("/usr/lib/systemd/system-sleep/mados-resume-network-reset", content)

    def test_network_module_enables_service(self):
        with open(NETWORK_MODULE_PATH) as f:
            content = f.read()

        self.assertIn("mados-hw-quirks.service", content)

    def test_autoinstall_enables_service(self):
        with open(AUTOINSTALL_PATH) as f:
            content = f.read()

        self.assertIn("mados-hw-quirks.service", content)


class TestHwQuirkRules(unittest.TestCase):
    """Validate individual quirk rule scripts are present and sane."""

    def test_rtl_rule_exists_and_references_rtw88(self):
        self.assertTrue(os.path.isfile(RTL_QUIRK_PATH))
        with open(RTL_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("10ec:d723", content)
        self.assertIn("rtw88_8723de", content)

    def test_intel_wifi_rule_exists_and_references_iwlwifi(self):
        self.assertTrue(os.path.isfile(INTEL_WIFI_QUIRK_PATH))
        with open(INTEL_WIFI_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("iwlwifi", content)
        self.assertIn("Network controller \\[0280\\]", content)

    def test_quirks_library_exists(self):
        self.assertTrue(os.path.isfile(QUIRKS_LIB_PATH))
        with open(QUIRKS_LIB_PATH) as f:
            content = f.read()
        self.assertIn("hwq_is_group_disabled", content)

    def test_rtl8821ce_rule_exists(self):
        self.assertTrue(os.path.isfile(RTL8821CE_QUIRK_PATH))
        with open(RTL8821CE_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("10ec:c821", content)
        self.assertIn("rtl8821ce", content)

    def test_i915_rule_exists(self):
        self.assertTrue(os.path.isfile(I915_QUIRK_PATH))
        with open(I915_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("i915", content)
        self.assertIn("enable_psr=0", content)

    def test_amdgpu_rule_exists(self):
        self.assertTrue(os.path.isfile(AMDGPU_QUIRK_PATH))
        with open(AMDGPU_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("amdgpu", content)
        self.assertIn("aspm=0", content)

    def test_nvme_rule_exists(self):
        self.assertTrue(os.path.isfile(NVME_QUIRK_PATH))
        with open(NVME_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("nvme_core", content)
        self.assertIn("default_ps_max_latency_us=0", content)

    def test_audio_hda_rule_exists(self):
        self.assertTrue(os.path.isfile(AUDIO_HDA_QUIRK_PATH))
        with open(AUDIO_HDA_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("snd_hda_intel", content)
        self.assertIn("model=generic", content)

    def test_audio_sof_rule_exists(self):
        self.assertTrue(os.path.isfile(AUDIO_SOF_QUIRK_PATH))
        with open(AUDIO_SOF_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("snd_intel_dspcfg", content)
        self.assertIn("dsp_driver=1", content)

    def test_usb_wifi_rule_exists(self):
        self.assertTrue(os.path.isfile(USB_WIFI_QUIRK_PATH))
        with open(USB_WIFI_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("lsusb", content)
        self.assertIn("usbcore/parameters/autosuspend", content)

    def test_acpi_backlight_rule_exists(self):
        self.assertTrue(os.path.isfile(ACPI_BACKLIGHT_QUIRK_PATH))
        with open(ACPI_BACKLIGHT_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("/sys/class/dmi/id/sys_vendor", content)
        self.assertIn("modprobe video", content)

    def test_suspend_s2idle_rule_exists(self):
        self.assertTrue(os.path.isfile(SUSPEND_S2IDLE_QUIRK_PATH))
        with open(SUSPEND_S2IDLE_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("/sys/power/mem_sleep", content)
        self.assertIn("s2idle", content)

    def test_suspend_network_rule_exists(self):
        self.assertTrue(os.path.isfile(SUSPEND_NET_QUIRK_PATH))
        with open(SUSPEND_NET_QUIRK_PATH) as f:
            content = f.read()
        self.assertIn("/run/mados/suspend-reset-needed", content)
        self.assertIn("Network controller \\[0280\\]", content)

    def test_system_sleep_resume_hook_exists(self):
        self.assertTrue(os.path.isfile(SLEEP_HOOK_PATH))
        with open(SLEEP_HOOK_PATH) as f:
            content = f.read()
        self.assertIn("systemctl try-restart NetworkManager.service", content)
        self.assertIn("rfkill unblock all", content)


class TestHwQuirksLibraryBehavior(unittest.TestCase):
    """Validate helper-library behavior with controlled cmdline input."""

    def test_group_disable_match(self):
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write("quiet splash mados.disable_quirks=wifi,gpu\n")
            cmdline_path = f.name

        script = 'source "$1"; if hwq_is_group_disabled wifi; then echo yes; else echo no; fi'
        env = os.environ.copy()
        env["MADOS_QUIRKS_CMDLINE_PATH"] = cmdline_path
        result = subprocess.run(
            ["bash", "-c", script, "bash", QUIRKS_LIB_PATH],
            env=env,
            capture_output=True,
            text=True,
        )

        try:
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stdout.strip(), "yes")
        finally:
            if os.path.exists(cmdline_path):
                os.unlink(cmdline_path)

    def test_disable_token_parsing_from_custom_cmdline_path(self):
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write("quiet splash mados.disable_quirks=wifi,gpu\n")
            cmdline_path = f.name

        script = 'source "$1"; hwq_get_disable_token'
        env = os.environ.copy()
        env["MADOS_QUIRKS_CMDLINE_PATH"] = cmdline_path

        result = subprocess.run(
            ["bash", "-c", script, "bash", QUIRKS_LIB_PATH],
            env=env,
            capture_output=True,
            text=True,
        )

        try:
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stdout.strip(), "wifi,gpu")
        finally:
            if os.path.exists(cmdline_path):
                os.unlink(cmdline_path)


if __name__ == "__main__":
    unittest.main()
