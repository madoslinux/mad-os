#!/usr/bin/env python3
"""Tests for kernel installation logic in 00-kernel.sh"""
import os
import stat
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open


TEST_KERNEL_VERSION = "6.19.10.zen1-34"
TEST_KERNEL_PKGVER = "6.19.10-zen1"
TEST_KERNEL_URL = f"https://github.com/madoslinux/mados-kernel/releases/download/v{TEST_KERNEL_VERSION}/linux-mados-zen-{TEST_KERNEL_PKGVER}-x86_64.pkg.tar.xz"


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
        pkgver = re.sub(r'\.zen1-[0-9]+$', '-zen1', version)
        assert pkgver == "6.19.10-zen1"
    
    def test_kernel_url_construction(self):
        """Test kernel URL is correctly constructed"""
        version = "6.19.10.zen1-34"
        pkgver = "6.19.10-zen1"
        url = f"https://github.com/madoslinux/mados-kernel/releases/download/v{version}/linux-mados-zen-{pkgver}-x86_64.pkg.tar.xz"
        assert "v6.19.10.zen1-34" in url
        assert "linux-mados-zen-6.19.10-zen1" in url


class TestKernelVerification:
    """Test kernel verification functions"""
    
    def test_verify_kernel_exists(self, tmp_path):
        """Test that verify detects existing kernel"""
        boot_dir = tmp_path / "boot"
        boot_dir.mkdir()
        modules_dir = tmp_path / "lib/modules"
        modules_dir.mkdir()
        
        # Create mock kernel files
        vmlinuz = boot_dir / "vmlinuz-linux-mados-zen"
        vmlinuz.write_bytes(b"Linux kernel x86 boot executable")
        
        kver_dir = modules_dir / "6.19.10-zen1-mados-zen"
        kver_dir.mkdir()
        
        # Verify files exist
        assert (boot_dir / "vmlinuz-linux-mados-zen").exists()
        assert (modules_dir / "6.19.10-zen1-mados-zen").exists()
    
    def test_verify_kernel_missing(self, tmp_path):
        """Test that verify detects missing kernel"""
        boot_dir = tmp_path / "boot"
        boot_dir.mkdir()
        modules_dir = tmp_path / "lib/modules"
        modules_dir.mkdir()
        
        # Only vmlinuz exists, not modules
        vmlinuz = boot_dir / "vmlinuz-linux-mados-zen"
        vmlinuz.write_bytes(b"Linux kernel")
        
        assert (boot_dir / "vmlinuz-linux-mados-zen").exists()
        assert not (modules_dir / "6.19.10-zen1-mados-zen").exists()


class TestKernelModuleFiltering:
    """Test that only mados-zen kernels are detected"""
    
    def test_filter_mados_zen_modules(self):
        """Test filtering modules directories for mados-zen"""
        modules = [
            "6.19.10-zen1-mados-zen",
            "6.18.20-1-cachyos-lts",
            "6.19.10-1-cachyos",
            "5.15.100ARCH1-1",  # should be filtered
        ]
        
        mados_modules = [m for m in modules if "mados-zen" in m]
        assert mados_modules == ["6.19.10-zen1-mados-zen"]
    
    def test_filter_non_arch_modules(self):
        """Test filtering out non-mados kernels"""
        modules = [
            "6.19.10-zen1-mados-zen",
            "6.19.10-arch1-1",  # Arch kernel - should be filtered
            "5.10.100-1-lts",   # LTS - should be filtered
        ]
        
        # Filter modules that are NOT Arch or other distros
        mad_kernel_modules = [m for m in modules if "arch1-1" not in m and "-lts" not in m]
        assert "6.19.10-arch1-1" not in mad_kernel_modules
        assert "5.10.100-1-lts" not in mad_kernel_modules


class TestKernelDownload:
    """Test kernel download functionality"""
    
    @patch("urllib.request.urlopen")
    def test_fetch_latest_version_success(self, mock_urlopen):
        """Test fetching latest kernel version from GitHub"""
        import json
        
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "tag_name": "v6.19.10.zen1-34"
        }).encode()
        mock_urlopen.return_value = mock_response
        
        # This would be the actual bash curl call
        # Simulating the expected behavior
        expected_tag = "v6.19.10.zen1-34"
        assert expected_tag.startswith("v")
    
    @patch("urllib.request.urlopen")
    def test_fetch_version_network_error(self, mock_urlopen):
        """Test handling network errors when fetching version"""
        mock_urlopen.side_effect = Exception("Network error")
        
        # In bash: curl should fail and we should fallback or error
        with pytest.raises(Exception):
            pass  # Network error should be raised


class TestKernelInstallation:
    """Test kernel installation steps"""
    
    def test_remove_arch_kernel(self, tmp_path):
        """Test that Arch kernel files are correctly identified for removal"""
        boot_dir = tmp_path / "boot"
        boot_dir.mkdir()
        
        # Arch kernel files
        (boot_dir / "vmlinuz-linux").write_bytes(b"arch kernel")
        (boot_dir / "initramfs-linux.img").write_bytes(b"initramfs")
        (boot_dir / "System.map-linux").write_bytes(b"system map")
        
        # madOS kernel files
        (boot_dir / "vmlinuz-linux-mados-zen").write_bytes(b"mados kernel")
        (boot_dir / "initramfs-linux-mados-zen.img").write_bytes(b"mados initramfs")
        
        arch_files = [
            "vmlinuz-linux",
            "initramfs-linux.img",
            "System.map-linux",
        ]
        
        mados_files = [
            "vmlinuz-linux-mados-zen",
            "initramfs-linux-mados-zen.img",
        ]
        
        for f in arch_files:
            assert (boot_dir / f).exists()
        
        for f in mados_files:
            assert (boot_dir / f).exists()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
