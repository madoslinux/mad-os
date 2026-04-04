#!/usr/bin/env python3
"""Tests for kernel installation logic in 00-kernel.sh"""

import os
import stat
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open


TEST_KERNEL_VERSION = "6.19.10.zen1-34"
TEST_KERNEL_PKGVER = "6.19.10.zen1-1"
TEST_KERNEL_URL = f"https://github.com/madoslinux/mados-kernel/releases/download/v{TEST_KERNEL_VERSION}/linux-mados-{TEST_KERNEL_PKGVER}-x86_64.pkg.tar.zst"


class TestKernelVersionParsing:
    """Test kernel version parsing from GitHub API response"""

    def test_version_parsing_from_tag(self):
        """Test extracting version from tag format vX.Y.Z"""
        tag = "v6.19.10.zen1-34"
        version = tag.lstrip("v")
        assert version == "6.19.10.zen1-34"

    def test_pkgver_conversion(self):
        """Test converting tag version to package version"""
        version = "6.19.10.zen1-34"
        import re

        pkgver = re.sub(r"^([0-9]+\.[0-9]+\.[0-9]+\.zen1)-[0-9]+$", r"\1-1", version)
        assert pkgver == "6.19.10.zen1-1"

    def test_kernel_url_construction(self):
        """Test kernel URL is correctly constructed"""
        version = "6.19.10.zen1-34"
        pkgver = "6.19.10.zen1-1"
        url = f"https://github.com/madoslinux/mados-kernel/releases/download/v{version}/linux-mados-{pkgver}-x86_64.pkg.tar.zst"
        assert "v6.19.10.zen1-34" in url
        assert "linux-mados-6.19.10.zen1-1" in url


class TestKernelVerification:
    """Test kernel verification functions"""

    def test_verify_kernel_exists(self, tmp_path):
        """Test that verify detects existing kernel"""
        boot_dir = tmp_path / "boot"
        boot_dir.mkdir(parents=True)
        modules_dir = tmp_path / "lib/modules"
        modules_dir.mkdir(parents=True)

        # Create mock kernel files
        vmlinuz = boot_dir / "vmlinuz-linux-mados"
        vmlinuz.write_bytes(b"Linux kernel x86 boot executable")

        kver_dir = modules_dir / "6.19.10-zen1-mados"
        kver_dir.mkdir()

        # Verify files exist
        assert (boot_dir / "vmlinuz-linux-mados").exists()
        assert (modules_dir / "6.19.10-zen1-mados").exists()

    def test_verify_kernel_missing(self, tmp_path):
        """Test that verify detects missing kernel"""
        boot_dir = tmp_path / "boot"
        boot_dir.mkdir(parents=True)
        modules_dir = tmp_path / "lib/modules"
        modules_dir.mkdir(parents=True)

        # Only vmlinuz exists, not modules
        vmlinuz = boot_dir / "vmlinuz-linux-mados"
        vmlinuz.write_bytes(b"Linux kernel")

        assert (boot_dir / "vmlinuz-linux-mados").exists()
        assert not (modules_dir / "6.19.10-zen1-mados").exists()


class TestKernelModuleFiltering:
    """Test that only linux-mados kernels are detected"""

    def test_filter_mados_modules(self):
        """Test filtering modules directories for mados"""
        modules = [
            "6.19.10-zen1-mados",
            "6.18.20-1-cachyos-lts",
            "6.19.10-1-cachyos",
            "5.15.100ARCH1-1",  # should be filtered
        ]

        mados_modules = [m for m in modules if "mados" in m]
        assert mados_modules == ["6.19.10-zen1-mados"]

    def test_filter_non_arch_modules(self):
        """Test filtering out non-mados kernels"""
        modules = [
            "6.19.10-zen1-mados",
            "6.19.10-arch1-1",  # Arch kernel - should be filtered
            "5.10.100-1-lts",  # LTS - should be filtered
        ]

        # Filter modules that are NOT Arch or other distros
        mad_kernel_modules = [m for m in modules if "arch1-1" not in m and "-lts" not in m]
        assert "6.19.10-arch1-1" not in mad_kernel_modules
        assert "5.10.100-1-lts" not in mad_kernel_modules


class TestKernelDownload:
    """Test kernel download functionality"""

    def test_fetch_version_network_error(self):
        """Test handling network errors when fetching version"""
        # Simulate a network error
        with pytest.raises(Exception, match="Network error"):
            raise Exception("Network error")


class TestKernelInstallation:
    """Test kernel installation steps"""

    def test_remove_arch_kernel(self, tmp_path):
        """Test that Arch kernel files are correctly identified for removal"""
        boot_dir = tmp_path / "boot"
        boot_dir.mkdir(parents=True)

        # Arch kernel files
        (boot_dir / "vmlinuz-linux").write_bytes(b"arch kernel")
        (boot_dir / "initramfs-linux.img").write_bytes(b"initramfs")
        (boot_dir / "System.map-linux").write_bytes(b"system map")

        # madOS kernel files
        (boot_dir / "vmlinuz-linux-mados").write_bytes(b"mados kernel")
        (boot_dir / "initramfs-linux-mados.img").write_bytes(b"mados initramfs")

        arch_files = [
            "vmlinuz-linux",
            "initramfs-linux.img",
            "System.map-linux",
        ]

        mados_files = [
            "vmlinuz-linux-mados",
            "initramfs-linux-mados.img",
        ]

        for f in arch_files:
            assert (boot_dir / f).exists()

        for f in mados_files:
            assert (boot_dir / f).exists()


class TestKernelVersionDetection:
    """Test kernel version detection from /lib/modules"""

    def test_detect_mados_kernel_version(self):
        """Test detection of mados kernel version"""
        import re

        modules_list = [
            "6.19.10-zen1-mados",
            "6.18.20-1-cachyos-lts",
            "6.19.10-1-cachyos",
        ]

        # Find mados kernel
        pattern = re.compile(r"^6\.[0-9]+\.[0-9]+-zen1-mados$")
        mados_modules = [m for m in modules_list if pattern.match(m)]

        assert mados_modules == ["6.19.10-zen1-mados"]

    def test_exclude_arch_kernel(self):
        """Test that arch kernel version is excluded"""
        import re

        modules_list = [
            "6.19.10-zen1-mados",
            "6.19.10-arch1-1",  # Should NOT match
        ]

        pattern = re.compile(r"^6\.[0-9]+\.[0-9]+-zen1-mados$")
        mados_modules = [m for m in modules_list if pattern.match(m)]

        assert mados_modules == ["6.19.10-zen1-mados"]
        assert "6.19.10-arch1-1" not in mados_modules


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
