#!/usr/bin/env python3
"""pytest configuration and fixtures for madOS tests."""

import sys
from pathlib import Path

import pytest

# Add the project root to the path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


@pytest.fixture
def kernel_package_name():
    """Standard kernel package name for current ISO builds."""
    return "linux-lts"


@pytest.fixture
def mock_live_system(tmp_path):
    """Mock a live system structure for testing."""
    boot_dir = tmp_path / "boot"
    boot_dir.mkdir()

    modules_dir = tmp_path / "lib/modules"
    modules_dir.mkdir(parents=True)

    (boot_dir / "vmlinuz-linux-lts").write_bytes(b"Linux kernel x86 boot executable vmlinuz")
    (boot_dir / "initramfs-linux-lts.img").write_bytes(b"initramfs image")

    lts_modules = modules_dir / "6.6.84-1-lts"
    lts_modules.mkdir()
    (lts_modules / "modules.dep").write_text("", encoding="utf-8")

    return {
        "root": tmp_path,
        "boot": boot_dir,
        "modules": modules_dir,
        "kernel": "6.6.84-1-lts",
    }
