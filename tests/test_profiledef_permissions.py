#!/usr/bin/env python3
"""Tests that key executable/unit files are declared in profiledef.sh."""

import os
import unittest


REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PROFILEDEF_PATH = os.path.join(REPO_DIR, "profiledef.sh")

REQUIRED_ENTRIES = [
    '/usr/local/bin/mados-hw-quirks.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks-lib.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/10-rtl8723de-rtw88.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/20-intel-wifi-power-save-off.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/21-realtek-rtl8821ce.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/31-amdgpu-stability.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/33-nvidia-conditional-stack.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/40-nvme-conservative-power.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/50-audio-hda-fallback.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/51-audio-sof-to-hda-fallback.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/60-usb-wifi-autosuspend-off.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/70-acpi-backlight-dmi.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/80-suspend-prefer-s2idle-dmi.sh"]="0:0:755',
    '/usr/local/lib/mados-hw-quirks.d/81-suspend-resume-network-reset.sh"]="0:0:755',
    '/usr/lib/systemd/system-sleep/mados-resume-network-reset"]="0:0:755',
    '/etc/systemd/system/mados-hw-quirks.service"]="0:0:644',
]


class TestProfiledefPermissions(unittest.TestCase):
    """Validate file permission declarations for important scripts/units."""

    def test_profiledef_exists(self):
        self.assertTrue(os.path.isfile(PROFILEDEF_PATH))

    def test_required_entries_present(self):
        with open(PROFILEDEF_PATH) as f:
            content = f.read()

        for entry in REQUIRED_ENTRIES:
            with self.subTest(entry=entry):
                self.assertIn(entry, content)


if __name__ == "__main__":
    unittest.main()
