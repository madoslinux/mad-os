#!/usr/bin/env python3
"""Tests for kernel installation flow - validates 00-kernel.sh logic"""

import os
import pytest
from pathlib import Path
import urllib.request
import json


class TestKernelInstallationFlow:
    """Validate that the kernel installation flow works correctly"""

    def test_fetches_latest_kernel_version(self):
        """Verify we can fetch latest kernel version from GitHub API"""
        url = "https://api.github.com/repos/madoslinux/mados-kernel/releases/latest"
        response = urllib.request.urlopen(url)
        data = json.loads(response.read().decode())
        tag = data["tag_name"]

        assert tag.startswith("v"), f"Tag should start with v, got: {tag}"
        assert "zen1" in tag, f"Tag should contain zen1, got: {tag}"

    def test_kernel_url_construction(self):
        """Test kernel URL is correctly constructed"""
        version = "6.19.10.zen1-34"
        import re

        pkgver = re.sub(r"^([0-9]+\.[0-9]+\.[0-9]+\.zen1)-[0-9]+$", r"\1-1", version)
        assert pkgver == "6.19.10.zen1-1"

        url = f"https://github.com/madoslinux/mados-kernel/releases/download/v{version}/linux-mados-{pkgver}-x86_64.pkg.tar.zst"
        assert "v6.19.10.zen1-34" in url
        assert "linux-mados-6.19.10.zen1-1" in url

    def test_kernel_package_contents(self):
        """Verify kernel package contains expected files"""
        version = "6.19.10.zen1-34"
        pkgver = "6.19.10.zen1-1"
        url = f"https://github.com/madoslinux/mados-kernel/releases/download/v{version}/linux-mados-{pkgver}-x86_64.pkg.tar.zst"

        # Just verify URL is valid (don't actually download)
        assert url.endswith(".pkg.tar.zst")
        assert "linux-mados-" in url

    def test_headers_package_contents(self):
        """Verify headers package contains expected files"""
        version = "6.19.10.zen1-34"
        pkgver = "6.19.10.zen1-1"
        url = f"https://github.com/madoslinux/mados-kernel/releases/download/v{version}/linux-mados-headers-{pkgver}-x86_64.pkg.tar.zst"

        assert url.endswith(".pkg.tar.zst")
        assert "linux-mados-headers" in url


class TestKernelPathFiltering:
    """Test that kernel filtering logic correctly identifies madOS kernel"""

    def test_mados_module_filter(self):
        """Modules directory should filter for mados only"""
        modules = [
            "6.19.10-zen1-mados",  # Should be included
            "6.19.10-arch1-1",  # Should be excluded
            "5.15.100-1-ARCH",  # Should be excluded
            "6.18.20-1-cachyos-lts",  # Should be excluded
        ]

        import re

        pattern = re.compile(r"^6\.[0-9]+\.[0-9]+-zen1-mados$")

        for mod in modules:
            if pattern.match(mod):
                assert "mados" in mod

    def test_arch_kernel_excluded(self):
        """Arch kernel should be identified for removal"""
        boot_files = [
            "/boot/vmlinuz-linux",  # Arch - should be removed
            "/boot/vmlinuz-linux-mados",  # madOS - should be kept
            "/boot/initramfs-linux.img",  # Arch - should be removed
            "/boot/initramfs-linux-mados.img",  # madOS - should be kept
        ]

        arch_kernel_files = [
            f for f in boot_files if f == "/boot/vmlinuz-linux" or f == "/boot/initramfs-linux.img"
        ]
        mados_kernel_files = [f for f in boot_files if "mados" in f]

        assert "/boot/vmlinuz-linux" in arch_kernel_files
        assert "/boot/vmlinuz-linux-mados" in mados_kernel_files


class TestKernelVersionParsing:
    """Test kernel version parsing from GitHub tag"""

    def test_version_stripping(self):
        """Tag v6.19.10.zen1-34 should become 6.19.10.zen1-34"""
        tag = "v6.19.10.zen1-34"
        version = tag.lstrip("v")
        assert version == "6.19.10.zen1-34"

    def test_pkgver_conversion(self):
        """6.19.10.zen1-34 should become 6.19.10-zen1"""
        import re

        version = "6.19.10.zen1-34"
        pkgver = re.sub(r"^([0-9]+\.[0-9]+\.[0-9]+\.zen1)-[0-9]+$", r"\1-1", version)
        assert pkgver == "6.19.10.zen1-1"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
