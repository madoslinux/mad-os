#!/usr/bin/env python3
"""pytest configuration and fixtures for mados tests"""
import os
import sys
import pytest
from pathlib import Path

# Add the project root to the path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


@pytest.fixture
def mados_kernel_version():
    """Standard madOS kernel version for testing"""
    return "6.19.10.zen1-34"


@pytest.fixture
def mados_kernel_pkgver():
    """Standard madOS kernel package version for testing"""
    return "6.19.10-zen1"


@pytest.fixture
def mados_kernel_url(mados_kernel_version, mados_kernel_pkgver):
    """Standard madOS kernel URL for testing"""
    return f"https://github.com/madoslinux/mados-kernel/releases/download/v{mados_kernel_version}/linux-mados-zen-{mados_kernel_pkgver}-x86_64.pkg.tar.xz"


@pytest.fixture
def mock_live_system(tmp_path):
    """Mock a live system structure for testing"""
    boot_dir = tmp_path / "boot"
    boot_dir.mkdir()
    
    modules_dir = tmp_path / "lib/modules"
    modules_dir.mkdir()
    
    # Create madOS kernel
    (boot_dir / "vmlinuz-linux-mados-zen").write_bytes(b"Linux kernel x86 boot executable vmlinuz")
    (boot_dir / "initramfs-linux-mados-zen.img").write_bytes(b"initramfs image")
    
    kver_dir = modules_dir / "6.19.10-zen1-mados-zen"
    kver_dir.mkdir()
    (kver_dir / "modules.dep").write_text("")
    
    # Create Arch kernel (should be filtered out)
    (boot_dir / "vmlinuz-linux").write_bytes(b"Arch Linux kernel")
    (boot_dir / "initramfs-linux.img").write_bytes(b"Arch initramfs")
    
    arch_modules = modules_dir / "6.19.10-arch1-1"
    arch_modules.mkdir()
    
    return {
        "root": tmp_path,
        "boot": boot_dir,
        "modules": modules_dir,
        "mados_kernel": "6.19.10-zen1-mados-zen",
        "arch_kernel": "6.19.10-arch1-1",
    }
