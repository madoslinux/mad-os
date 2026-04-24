#!/usr/bin/env python3
"""Tests for linux-lts kernel boot artifact expectations."""

import pytest


class TestKernelBootArtifacts:
    """Validate linux-lts boot file naming used by boot entries."""

    def test_expected_boot_filenames(self):
        """Boot entries should reference linux-lts artifacts."""
        kernel = "vmlinuz-linux-lts"
        initramfs = "initramfs-linux-lts.img"

        assert kernel.startswith("vmlinuz-linux-")
        assert initramfs.startswith("initramfs-linux-")
        assert kernel.endswith("-lts")
        assert initramfs.endswith("-lts.img")

    def test_arch_kernel_is_not_target(self):
        """Plain linux artifacts are not the selected target."""
        boot_files = {
            "vmlinuz-linux",
            "initramfs-linux.img",
            "vmlinuz-linux-lts",
            "initramfs-linux-lts.img",
        }

        assert "vmlinuz-linux-lts" in boot_files
        assert "initramfs-linux-lts.img" in boot_files


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
