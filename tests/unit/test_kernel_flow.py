#!/usr/bin/env python3
"""Tests for boot configuration flow with linux-lts and archiso label lookup."""

from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]


def _read(path: str) -> str:
    return (REPO_ROOT / path).read_text(encoding="utf-8")


class TestBootEntriesUseLtsKernel:
    """Boot entries should point to linux-lts kernel artifacts."""

    @pytest.mark.parametrize(
        "path",
        [
            "syslinux/archiso_sys-linux.cfg",
            "syslinux/archiso_sys-linux-compat.cfg",
            "syslinux/archiso_pxe-linux.cfg",
            "efiboot/loader/entries/01-archiso-linux.conf",
            "efiboot/loader/entries/02-archiso-safe-graphics.conf",
            "efiboot/loader/entries/03-archiso-safe-compat.conf",
        ],
    )
    def test_uses_linux_lts_paths(self, path):
        content = _read(path)
        assert "vmlinuz-linux-lts" in content
        assert "initramfs-linux-lts.img" in content
        assert "vmlinuz-linux-mados" not in content
        assert "initramfs-linux-mados.img" not in content


class TestArchisoLookupCompatibility:
    """Boot entries should use label lookup for Ventoy compatibility."""

    @pytest.mark.parametrize(
        "path",
        [
            "syslinux/archiso_sys-linux.cfg",
            "syslinux/archiso_sys-linux-compat.cfg",
            "syslinux/archiso_pxe-linux.cfg",
            "efiboot/loader/entries/01-archiso-linux.conf",
            "efiboot/loader/entries/02-archiso-safe-graphics.conf",
            "efiboot/loader/entries/03-archiso-safe-compat.conf",
        ],
    )
    def test_uses_archisolabel(self, path):
        content = _read(path)
        assert "archisolabel=%ARCHISO_LABEL%" in content

    @pytest.mark.parametrize(
        "path",
        [
            "syslinux/archiso_sys-linux.cfg",
            "syslinux/archiso_sys-linux-compat.cfg",
            "syslinux/archiso_pxe-linux.cfg",
            "efiboot/loader/entries/01-archiso-linux.conf",
            "efiboot/loader/entries/02-archiso-safe-graphics.conf",
            "efiboot/loader/entries/03-archiso-safe-compat.conf",
        ],
    )
    def test_keeps_archisosearchuuid(self, path):
        content = _read(path)
        assert "archisosearchuuid=%ARCHISO_UUID%" in content

    @pytest.mark.parametrize(
        "path",
        [
            "syslinux/archiso_sys-linux.cfg",
            "syslinux/archiso_sys-linux-compat.cfg",
            "syslinux/archiso_pxe-linux.cfg",
            "efiboot/loader/entries/01-archiso-linux.conf",
            "efiboot/loader/entries/02-archiso-safe-graphics.conf",
            "efiboot/loader/entries/03-archiso-safe-compat.conf",
            "grub/grub.cfg",
            "grub/loopback.cfg",
        ],
    )
    def test_uses_quiet_boot_status_flags(self, path):
        content = _read(path)
        assert "quiet splash" in content
        assert "loglevel=3" in content
        assert "rd.systemd.show_status=false" in content
        assert "systemd.show_status=false" in content
        assert "vt.global_cursor_default=0" in content


class TestKernelCustomizationFlow:
    """The build flow should not force custom kernel install."""

    def test_customize_script_does_not_run_custom_kernel_modules(self):
        content = _read("airootfs/root/customize_airootfs.sh")
        assert 'run_module "00-kernel.sh" "install_mados_kernel"' not in content
        assert 'run_module "01-initramfs.sh" "generate_initramfs"' not in content


class TestGrubLoopbackCompatibility:
    """GRUB loopback config should support ISO loop boot (e.g. Ventoy)."""

    def test_loopback_cfg_exists_and_uses_img_loop(self):
        content = _read("grub/loopback.cfg")
        assert "img_dev=UUID=${archiso_img_dev_uuid}" in content
        assert 'img_loop="${iso_path}"' in content
        assert "vmlinuz-linux-lts" in content
        assert "initramfs-linux-lts.img" in content

    def test_grub_cfg_exists_with_lts_entries(self):
        content = _read("grub/grub.cfg")
        assert "vmlinuz-linux-lts" in content
        assert "initramfs-linux-lts.img" in content
        assert "cow_label=mados-persist" in content
        assert "archisolabel=%ARCHISO_LABEL%" in content


class TestProfileSearchFilename:
    """Ensure profile exports GRUB search filename for loopback support."""

    def test_profiledef_sets_search_filename_to_loopback(self):
        content = _read("profiledef.sh")
        assert 'search_filename="boot/grub/loopback.cfg"' in content


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
