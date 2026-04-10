#!/usr/bin/env python3
"""Tests for Safe Compat boot menu entries."""

import os
import unittest


REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SYS_CFG_PATH = os.path.join(REPO_DIR, "syslinux", "archiso_sys.cfg")
SYS_COMPAT_CFG_PATH = os.path.join(REPO_DIR, "syslinux", "archiso_sys-linux-compat.cfg")
UEFI_COMPAT_ENTRY_PATH = os.path.join(
    REPO_DIR, "efiboot", "loader", "entries", "03-archiso-safe-compat.conf"
)


class TestSafeCompatBootEntries(unittest.TestCase):
    """Validate BIOS and UEFI safe compatibility entries."""

    def test_syslinux_includes_compat_menu(self):
        with open(SYS_CFG_PATH) as f:
            content = f.read()
        self.assertIn("INCLUDE archiso_sys-linux-compat.cfg", content)

    def test_syslinux_compat_entry_has_expected_kernel_params(self):
        with open(SYS_COMPAT_CFG_PATH) as f:
            content = f.read()
        self.assertIn("MENU LABEL madOS Live (Safe Compat)", content)
        self.assertIn("nomodeset", content)
        self.assertIn("i915.enable_psr=0", content)
        self.assertIn("pcie_aspm=off", content)
        self.assertIn("nvme_core.default_ps_max_latency_us=0", content)

    def test_uefi_compat_entry_exists_and_has_expected_params(self):
        self.assertTrue(os.path.isfile(UEFI_COMPAT_ENTRY_PATH))
        with open(UEFI_COMPAT_ENTRY_PATH) as f:
            content = f.read()
        self.assertIn("madOS Live (Safe Compat)", content)
        self.assertIn("sort-key 03", content)
        self.assertIn("nomodeset", content)
        self.assertIn("i915.enable_psr=0", content)
        self.assertIn("pcie_aspm=off", content)
        self.assertIn("nvme_core.default_ps_max_latency_us=0", content)


if __name__ == "__main__":
    unittest.main()
