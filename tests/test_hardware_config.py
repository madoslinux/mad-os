#!/usr/bin/env python3
"""
Tests for madOS Adaptive Hardware Configuration script.

Validates that the mados-hardware-config script:
- Has correct structure and permissions
- Detects hardware correctly (RAM, CPU, storage)
- Configures ZRAM appropriately based on RAM
- Sets optimal swappiness values
- Applies correct I/O scheduler for storage type
"""

import os
import re
import unittest

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AIROOTFS = os.path.join(REPO_DIR, "airootfs")
BIN_DIR = os.path.join(AIROOTFS, "usr", "local", "bin")
SYSTEMD_DIR = os.path.join(AIROOTFS, "etc", "systemd", "system")


class TestHardwareConfigScript(unittest.TestCase):
    """Test the mados-hardware-config script structure."""

    def setUp(self):
        script_path = os.path.join(BIN_DIR, "mados-hardware-config")
        if not os.path.isfile(script_path):
            self.skipTest("mados-hardware-config not found")
        with open(script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-hardware-config script must exist."""
        self.assertTrue(os.path.isfile(os.path.join(BIN_DIR, "mados-hardware-config")))

    def test_script_has_shebang(self):
        """Script must start with #!/bin/bash shebang."""
        self.assertTrue(self.content.strip().startswith("#!/bin/bash"))

    def test_script_uses_strict_mode(self):
        """Script must use set -e for error handling."""
        self.assertIn("set -e", self.content)

    def test_script_has_logging(self):
        """Script must have logging function."""
        self.assertIn("log()", self.content)

    def test_detects_ram_size(self):
        """Script must detect RAM size."""
        self.assertIn("detect_ram_size", self.content)
        self.assertIn("MemTotal", self.content)

    def test_detects_cpu_cores(self):
        """Script must detect CPU cores."""
        self.assertIn("detect_cpu_cores", self.content)
        self.assertIn("nproc", self.content)

    def test_detects_storage_type(self):
        """Script must detect storage type (nvme, ssd, hdd)."""
        self.assertIn("detect_storage_type", self.content)
        self.assertIn("rotational", self.content)


class TestZRampConfiguration(unittest.TestCase):
    """Test ZRAM configuration logic."""

    def setUp(self):
        script_path = os.path.join(BIN_DIR, "mados-hardware-config")
        if not os.path.isfile(script_path):
            self.skipTest("mados-hardware-config not found")
        with open(script_path) as f:
            self.content = f.read()

    def test_configures_zram(self):
        """Script must have ZRAM configuration function."""
        self.assertIn("configure_zram", self.content)

    def test_zram_size_calculation(self):
        """Script must calculate ZRAM size based on RAM."""
        # Check for different RAM configurations
        self.assertIn("1024", self.content)  # MB conversion
        self.assertIn("zram_size_mb", self.content)

    def test_zram_compression_algorithm(self):
        """Script must use zstd compression for ZRAM."""
        self.assertIn("zstd", self.content)

    def test_zram_generator_config(self):
        """Script must create zram-generator.conf."""
        self.assertIn("/etc/systemd/zram-generator.conf", self.content)


class TestSwappinessConfiguration(unittest.TestCase):
    """Test swappiness configuration logic."""

    def setUp(self):
        script_path = os.path.join(BIN_DIR, "mados-hardware-config")
        if not os.path.isfile(script_path):
            self.skipTest("mados-hardware-config not found")
        with open(script_path) as f:
            self.content = f.read()

    def test_configures_swappiness(self):
        """Script must have swappiness configuration function."""
        self.assertIn("configure_swappiness", self.content)

    def test_swappiness_values(self):
        """Script must set different swappiness values based on RAM."""
        # Check for swappiness value ranges
        self.assertIn("swappiness", self.content)
        # Should have different values for different RAM amounts
        self.assertRegex(self.content, r"swappiness_value=\d+")

    def test_swappiness_persistent(self):
        """Script must make swappiness persistent via sysctl."""
        self.assertIn("/etc/sysctl.d/", self.content)
        self.assertIn("vm.swappiness", self.content)


class TestIOSchedulerConfiguration(unittest.TestCase):
    """Test I/O scheduler configuration logic."""

    def setUp(self):
        script_path = os.path.join(BIN_DIR, "mados-hardware-config")
        if not os.path.isfile(script_path):
            self.skipTest("mados-hardware-config not found")
        with open(script_path) as f:
            self.content = f.read()

    def test_configures_io_scheduler(self):
        """Script must have I/O scheduler configuration function."""
        self.assertIn("configure_io_scheduler", self.content)

    def test_scheduler_for_ssd(self):
        """Script must use 'none' scheduler for SSD/NVMe."""
        # For SSDs, should use 'none' or 'mq-deadline'
        self.assertIn("none", self.content)

    def test_scheduler_for_hdd(self):
        """Script must use 'bfq' scheduler for HDDs."""
        self.assertIn("bfq", self.content)

    def test_scheduler_persistent(self):
        """Script should make scheduler persistent via GRUB."""
        self.assertIn("elevator=", self.content)
        self.assertIn("/etc/default/grub", self.content)


class TestDirtyWritebackConfiguration(unittest.TestCase):
    """Test dirty page writeback configuration."""

    def setUp(self):
        script_path = os.path.join(BIN_DIR, "mados-hardware-config")
        if not os.path.isfile(script_path):
            self.skipTest("mados-hardware-config not found")
        with open(script_path) as f:
            self.content = f.read()

    def test_configures_dirty_writeback(self):
        """Script must configure dirty page writeback."""
        self.assertIn("configure_dirty_writeback", self.content)

    def test_dirty_ratio_settings(self):
        """Script must set dirty_ratio and dirty_background_ratio."""
        self.assertIn("dirty_ratio", self.content)
        self.assertIn("dirty_background_ratio", self.content)


class TestTHPConfiguration(unittest.TestCase):
    """Test Transparent Huge Pages configuration."""

    def setUp(self):
        script_path = os.path.join(BIN_DIR, "mados-hardware-config")
        if not os.path.isfile(script_path):
            self.skipTest("mados-hardware-config not found")
        with open(script_path) as f:
            self.content = f.read()

    def test_configures_thp(self):
        """Script must configure Transparent Huge Pages."""
        self.assertIn("configure_thp", self.content)

    def test_thp_settings(self):
        """Script must set THP to 'never' or 'madvise'."""
        self.assertIn("transparent_hugepage", self.content)
        # Should have 'never' for low RAM or 'madvise' for sufficient RAM
        self.assertIn("madvise", self.content)


class TestSystemdService(unittest.TestCase):
    """Test the systemd service file."""

    def setUp(self):
        service_path = os.path.join(SYSTEMD_DIR, "mados-hardware-config.service")
        if not os.path.isfile(service_path):
            self.skipTest("mados-hardware-config.service not found")
        with open(service_path) as f:
            self.content = f.read()

    def test_service_exists(self):
        """Systemd service file must exist."""
        self.assertTrue(os.path.isfile(os.path.join(SYSTEMD_DIR, "mados-hardware-config.service")))

    def test_service_has_unit_section(self):
        """Service must have [Unit] section."""
        self.assertIn("[Unit]", self.content)

    def test_service_has_service_section(self):
        """Service must have [Service] section."""
        self.assertIn("[Service]", self.content)

    def test_service_has_install_section(self):
        """Service must have [Install] section."""
        self.assertIn("[Install]", self.content)

    def test_service_runs_after_local_fs(self):
        """Service must run after local-fs.target."""
        self.assertIn("After=local-fs.target", self.content)

    def test_service_type_oneshot(self):
        """Service must be Type=oneshot."""
        self.assertIn("Type=oneshot", self.content)

    def test_service_remains_after_exit(self):
        """Service must have RemainAfterExit=yes."""
        self.assertIn("RemainAfterExit=yes", self.content)

    def test_service_enabled_by_default(self):
        """Service must be wanted by sysinit.target."""
        self.assertIn("WantedBy=sysinit.target", self.content)


class TestProfiledefPermissions(unittest.TestCase):
    """Test profiledef.sh has correct permissions."""

    def setUp(self):
        profiledef_path = os.path.join(REPO_DIR, "profiledef.sh")
        if not os.path.isfile(profiledef_path):
            self.skipTest("profiledef.sh not found")
        with open(profiledef_path) as f:
            self.content = f.read()

    def test_script_has_permissions(self):
        """profiledef.sh must set permissions for mados-hardware-config."""
        self.assertIn("mados-hardware-config", self.content)

    def test_script_is_executable(self):
        """mados-hardware-config must have 755 permissions."""
        pattern = re.compile(r'\["/usr/local/bin/mados-hardware-config"\]="0:0:755"')
        self.assertRegex(self.content, pattern)

    def test_service_has_permissions(self):
        """Service file must have permissions set in profiledef.sh."""
        self.assertIn("mados-hardware-config.service", self.content)


class TestIntegrationWithInstaller(unittest.TestCase):
    """Test integration with installer."""

    def setUp(self):
        cfg = os.path.join(AIROOTFS, "usr", "local", "lib", "mados_installer", "scripts")
        config_script = os.path.join(cfg, "configure-system.sh")
        if not os.path.isfile(config_script):
            self.skipTest("configure-system.sh not found")
        with open(config_script) as f:
            self.content = f.read()

    def test_enables_hardware_config_service(self):
        """Installer must enable mados-hardware-config.service."""
        self.assertIn("mados-hardware-config.service", self.content)
        self.assertIn("systemctl enable mados-hardware-config.service", self.content)


if __name__ == "__main__":
    unittest.main()
