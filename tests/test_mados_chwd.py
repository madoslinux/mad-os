#!/usr/bin/env python3
"""
Tests for madOS hardware detection tool (mados-chwd).

Validates that mados-chwd correctly:
- Detects GPU hardware (NVIDIA, AMD, Intel, etc.)
- Identifies virtual machines
- Detects handheld devices (Steam Deck, ROG Ally, MSI Claw)
- Installs appropriate driver profiles
- Lists available and installed profiles
"""

import os
import subprocess
import sys
import unittest

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AIROOTFS = os.path.join(REPO_DIR, "airootfs")
BIN_DIR = os.path.join(AIROOTFS, "usr", "local", "bin")
CHWD_PATH = os.path.join(BIN_DIR, "mados-chwd")


class TestMadosChwdScript(unittest.TestCase):
    """Verify mados-chwd script exists and has correct structure."""

    def setUp(self):
        if not os.path.isfile(CHWD_PATH):
            self.skipTest("mados-chwd script not found")
        with open(CHWD_PATH) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-chwd must exist."""
        self.assertTrue(os.path.isfile(CHWD_PATH))

    def test_valid_python_syntax(self):
        """mados-chwd must have valid Python syntax."""
        result = subprocess.run(
            ["python3", "-m", "py_compile", CHWD_PATH],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Python syntax error: {result.stderr}",
        )

    def test_has_shebang(self):
        """Script must start with a Python shebang."""
        first_line = self.content.splitlines()[0]
        self.assertTrue(
            first_line.startswith("#!"),
            "Must start with #!",
        )
        self.assertIn("python", first_line, "Must use python")

    def test_has_argparse(self):
        """Script must use argparse for CLI argument parsing."""
        self.assertIn("argparse", self.content, "Must use argparse for CLI")

    def test_has_profiles(self):
        """Script must define hardware profiles."""
        self.assertIn("PROFILES", self.content, "Must define PROFILES dict")

    def test_profiles_include_nvidia(self):
        """Profiles must include NVIDIA options."""
        self.assertIn("nvidia-open", self.content, "Must include nvidia-open profile")
        self.assertIn("nvidia-dkms", self.content, "Must include nvidia-dkms profile")

    def test_profiles_include_amd(self):
        """Profiles must include AMD option."""
        self.assertIn("amdgpu", self.content, "Must include amdgpu profile")

    def test_profiles_include_intel(self):
        """Profiles must include Intel option."""
        self.assertIn("intel", self.content, "Must include intel profile")

    def test_profiles_include_virtualmachine(self):
        """Profiles must include virtual machine option."""
        self.assertIn("virtualmachine", self.content, "Must include virtualmachine profile")

    def test_profiles_include_handheld(self):
        """Profiles must include handheld device options."""
        self.assertIn("handheld.steam-deck", self.content, "Must include steam-deck profile")
        self.assertIn("handheld.rog-ally", self.content, "Must include rog-ally profile")
        self.assertIn("handheld.msi-claw", self.content, "Must include msi-claw profile")


class TestMadosChwdCLI(unittest.TestCase):
    """Verify mados-chwd CLI interface."""

    def setUp(self):
        if not os.path.isfile(CHWD_PATH):
            self.skipTest("mados-chwd script not found")

    def test_help_option(self):
        """mados-chwd --help must work."""
        result = subprocess.run(
            ["python3", CHWD_PATH, "--help"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"--help failed: {result.stderr}")

    def test_list_option(self):
        """mados-chwd --list must work."""
        result = subprocess.run(
            ["python3", CHWD_PATH, "--list"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"--list failed: {result.stderr}")
        self.assertIn("nvidia-open", result.stdout, "Must list nvidia-open profile")

    def test_version_option(self):
        """mados-chwd --version must work."""
        result = subprocess.run(
            ["python3", CHWD_PATH, "--version"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"--version failed: {result.stderr}")

    def test_autoconfigure_option_exists(self):
        """mados-chwd must support --autoconfigure/-a option."""
        result = subprocess.run(
            ["python3", CHWD_PATH, "--help"],
            capture_output=True,
            text=True,
        )
        self.assertIn("--autoconfigure", result.stdout, "Must support --autoconfigure")

    def test_install_option_exists(self):
        """mados-chwd must support --install/-i option."""
        result = subprocess.run(
            ["python3", CHWD_PATH, "--help"],
            capture_output=True,
            text=True,
        )
        self.assertIn("--install", result.stdout, "Must support --install")

    def test_remove_option_exists(self):
        """mados-chwd must support --remove/-r option."""
        result = subprocess.run(
            ["python3", CHWD_PATH, "--help"],
            capture_output=True,
            text=True,
        )
        self.assertIn("--remove", result.stdout, "Must support --remove")


class TestMadosChwdProfiles(unittest.TestCase):
    """Verify mados-chwd profile definitions."""

    def setUp(self):
        if not os.path.isfile(CHWD_PATH):
            self.skipTest("mados-chwd script not found")

    def test_nvidia_open_packages(self):
        """nvidia-open profile must include nvidia-open-dkms package."""
        with open(CHWD_PATH) as f:
            content = f.read()
        self.assertIn('"nvidia-open-dkms"', content, "nvidia-open must include nvidia-open-dkms")

    def test_nvidia_dkms_packages(self):
        """nvidia-dkms profile must include nvidia-dkms and utils."""
        with open(CHWD_PATH) as f:
            content = f.read()
        self.assertIn('"nvidia-dkms"', content, "nvidia-dkms must include nvidia-dkms")

    def test_amdgpu_packages(self):
        """amdgpu profile must include xf86-video-amdgpu."""
        with open(CHWD_PATH) as f:
            content = f.read()
        self.assertIn('"xf86-video-amdgpu"', content, "amdgpu must include xf86-video-amdgpu")

    def test_intel_packages(self):
        """intel profile must include xf86-video-intel."""
        with open(CHWD_PATH) as f:
            content = f.read()
        self.assertIn('"xf86-video-intel"', content, "intel must include xf86-video-intel")

    def test_virtualmachine_packages(self):
        """virtualmachine profile must include open-vm-tools and virtualbox-guest-utils."""
        with open(CHWD_PATH) as f:
            content = f.read()
        self.assertIn('"open-vm-tools"', content, "virtualmachine must include open-vm-tools")
        self.assertIn(
            '"virtualbox-guest-utils"',
            content,
            "virtualmachine must include virtualbox-guest-utils",
        )


class TestMadosKernelSelect(unittest.TestCase):
    """Verify mados-kernel-select script."""

    SCRIPT_PATH = os.path.join(BIN_DIR, "mados-kernel-select")

    def setUp(self):
        if not os.path.isfile(self.SCRIPT_PATH):
            self.skipTest("mados-kernel-select script not found")
        with open(self.SCRIPT_PATH) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-kernel-select must exist."""
        self.assertTrue(os.path.isfile(self.SCRIPT_PATH))

    def test_valid_bash_syntax(self):
        """mados-kernel-select must have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", self.SCRIPT_PATH],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Bash syntax error: {result.stderr}",
        )

    def test_has_shebang(self):
        """Script must start with bash shebang."""
        first_line = self.content.splitlines()[0]
        self.assertTrue(first_line.startswith("#!"), "Must start with #!")
        self.assertIn("bash", first_line, "Must use bash")

    def test_supports_bore_option(self):
        """Script must support 'bore' argument."""
        self.assertIn("bore", self.content, "Must support 'bore' scheduler")

    def test_supports_eevdf_option(self):
        """Script must support 'eevdf' argument."""
        self.assertIn("eevdf", self.content, "Must support 'eevdf' scheduler")

    def test_supports_status_option(self):
        """Script must support 'status' argument."""
        self.assertIn("status", self.content, "Must support 'status' argument")

    def test_has_help(self):
        """Script must have help function."""
        self.assertIn("help", self.content, "Must have help")


class TestMadosGpuDetect(unittest.TestCase):
    """Verify mados-gpu-detect script."""

    SCRIPT_PATH = os.path.join(BIN_DIR, "mados-gpu-detect")

    def setUp(self):
        if not os.path.isfile(self.SCRIPT_PATH):
            self.skipTest("mados-gpu-detect script not found")
        with open(self.SCRIPT_PATH) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-gpu-detect must exist."""
        self.assertTrue(os.path.isfile(self.SCRIPT_PATH))

    def test_valid_bash_syntax(self):
        """mados-gpu-detect must have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", self.SCRIPT_PATH],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Bash syntax error: {result.stderr}",
        )

    def test_has_shebang(self):
        """Script must start with bash shebang."""
        first_line = self.content.splitlines()[0]
        self.assertTrue(first_line.startswith("#!"), "Must start with #!")
        self.assertIn("bash", first_line, "Must use bash")

    def test_detects_nvidia(self):
        """Script must detect NVIDIA GPUs."""
        self.assertIn("nvidia", self.content, "Must detect nvidia GPUs")

    def test_detects_amdgpu(self):
        """Script must detect AMD GPUs."""
        self.assertIn("amdgpu", self.content, "Must detect amdgpu GPUs")

    def test_detects_intel(self):
        """Script must detect Intel GPUs."""
        self.assertIn("intel", self.content, "Must detect intel GPUs")

    def test_detects_virtual(self):
        """Script must detect virtual GPUs."""
        self.assertIn("virtual", self.content, "Must detect virtual GPUs")

    def test_uses_lspci(self):
        """Script must use lspci for GPU detection."""
        self.assertIn("lspci", self.content, "Must use lspci for detection")

    def test_supports_verbose(self):
        """Script must support --verbose/-v option."""
        self.assertIn("--verbose", self.content, "Must support --verbose")


class TestSchedulerConfig(unittest.TestCase):
    """Verify scheduler sysctl configuration."""

    def setUp(self):
        self.scheduler_conf = os.path.join(AIROOTFS, "etc", "sysctl.d", "99-scheduler.conf")
        if not os.path.isfile(self.scheduler_conf):
            self.skipTest("99-scheduler.conf not found")
        with open(self.scheduler_conf) as f:
            self.content = f.read()

    def test_scheduler_config_exists(self):
        """99-scheduler.conf must exist."""
        self.assertTrue(os.path.isfile(self.scheduler_conf))

    def test_has_bore_tuning(self):
        """Config must include BORE scheduler tuning."""
        self.assertIn("sched_latency", self.content, "Must include BORE latency tuning")
        self.assertIn("sched_min_granularity", self.content, "Must include granularity tuning")

    def test_has_vm_tuning(self):
        """Config must include VM tuning for responsiveness."""
        self.assertIn("vm.swappiness", self.content, "Must include swappiness tuning")
        self.assertIn("vm.dirty_ratio", self.content, "Must include dirty ratio tuning")


class TestProfiledefIncludesNewScripts(unittest.TestCase):
    """Verify profiledef.sh includes permissions for new scripts."""

    def setUp(self):
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        if not os.path.isfile(profiledef):
            self.skipTest("profiledef.sh not found")
        with open(profiledef) as f:
            self.content = f.read()

    def test_includes_mados_chwd(self):
        """profiledef.sh must set permissions for mados-chwd."""
        self.assertIn("mados-chwd", self.content, "profiledef.sh must include mados-chwd")

    def test_includes_mados_kernel_select(self):
        """profiledef.sh must set permissions for mados-kernel-select."""
        self.assertIn(
            "mados-kernel-select",
            self.content,
            "profiledef.sh must include mados-kernel-select",
        )

    def test_includes_mados_gpu_detect(self):
        """profiledef.sh must set permissions for mados-gpu-detect."""
        self.assertIn(
            "mados-gpu-detect",
            self.content,
            "profiledef.sh must include mados-gpu-detect",
        )


class TestPackagesIncludeNewTools(unittest.TestCase):
    """Verify packages.x86_64 includes new dependencies."""

    def setUp(self):
        pkg_file = os.path.join(REPO_DIR, "packages.x86_64")
        if not os.path.isfile(pkg_file):
            self.skipTest("packages.x86_64 not found")
        with open(pkg_file) as f:
            self.packages = [
                line.strip() for line in f if line.strip() and not line.startswith("#")
            ]

    def test_excludes_linux_zen(self):
        """packages.x86_64 should not include linux-zen when LTS is selected."""
        self.assertNotIn("linux-zen", self.packages, "packages.x86_64 should not include linux-zen")

    def test_includes_linux_lts(self):
        """packages.x86_64 must include linux-lts kernel."""
        self.assertIn("linux-lts", self.packages, "packages.x86_64 must include linux-lts")

    def test_includes_pciutils(self):
        """packages.x86_64 must include pciutils for lspci."""
        self.assertIn("pciutils", self.packages, "packages.x86_64 must include pciutils")


if __name__ == "__main__":
    unittest.main()
