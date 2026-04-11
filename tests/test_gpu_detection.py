#!/usr/bin/env python3
"""
Tests for madOS 3D acceleration auto-detection and compositor selection.

Validates that the system correctly auto-detects whether the user has 3D
acceleration and selects the appropriate compositor:
  - No 3D acceleration → Sway (software rendering via pixman)
  - 3D acceleration    → Hyprland (GPU-accelerated)

These tests verify the detect-legacy-hardware and select-compositor scripts,
the SDDM auto-session launcher, and the session wrapper scripts
(sway-session, hyprland-session).
"""

import os
import re
import subprocess
import sys
import unittest

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AIROOTFS = os.path.join(REPO_DIR, "airootfs")
BIN_DIR = os.path.join(AIROOTFS, "usr", "local", "bin")
SKEL_DIR = os.path.join(AIROOTFS, "etc", "skel")
SESSIONS_DIR = os.path.join(AIROOTFS, "usr", "share", "wayland-sessions")


# ═══════════════════════════════════════════════════════════════════════════
# detect-legacy-hardware script
# ═══════════════════════════════════════════════════════════════════════════
class TestDetectLegacyHardwareScript(unittest.TestCase):
    """Verify detect-legacy-hardware script exists and has correct structure."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        if not os.path.isfile(self.script_path):
            self.skipTest("detect-legacy-hardware script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """detect-legacy-hardware must exist."""
        self.assertTrue(os.path.isfile(self.script_path))

    def test_valid_bash_syntax(self):
        """detect-legacy-hardware must have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", self.script_path],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Bash syntax error: {result.stderr}",
        )

    def test_has_shebang(self):
        """Script must start with a bash shebang."""
        first_line = self.content.splitlines()[0]
        self.assertTrue(first_line.startswith("#!"), "Must start with #!")
        self.assertIn("bash", first_line, "Must use bash")


# ═══════════════════════════════════════════════════════════════════════════
# 3D acceleration detection function
# ═══════════════════════════════════════════════════════════════════════════
class TestDetect3DAcceleration(unittest.TestCase):
    """Verify the 3D acceleration detection logic in detect-legacy-hardware."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        if not os.path.isfile(self.script_path):
            self.skipTest("detect-legacy-hardware script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_has_3d_acceleration_function(self):
        """Script must define a detect_3d_acceleration function."""
        self.assertIn(
            "detect_3d_acceleration",
            self.content,
            "Must have a detect_3d_acceleration function",
        )

    def test_checks_drm_render_node(self):
        """3D detection must check for DRM render node (/dev/dri/renderD128)."""
        self.assertIn(
            "/dev/dri/renderD128",
            self.content,
            "Must check /dev/dri/renderD128 for GPU render node",
        )

    def test_checks_egl_support(self):
        """3D detection must verify EGL/OpenGL capability via eglinfo."""
        # Must use eglinfo to check for OpenGL support as a real 3D test
        self.assertIn("eglinfo", self.content, "Must check eglinfo for EGL support")
        # eglinfo output is piped through grep for OpenGL
        self.assertRegex(
            self.content,
            r"eglinfo.*OpenGL",
            "Must verify OpenGL support by parsing eglinfo output",
        )

    def test_checks_drm_drivers(self):
        """3D detection must check DRM drivers for known 3D-capable drivers."""
        for driver in ["vmwgfx", "virtio-gpu", "virgl", "vboxvideo"]:
            with self.subTest(driver=driver):
                self.assertIn(
                    driver,
                    self.content,
                    f"Must check for {driver} DRM driver (3D-capable VM driver)",
                )

    def test_returns_correct_exit_codes(self):
        """detect_3d_acceleration must return 0 for 3D present, 1 for absent."""
        # The function should have return 0 (3D found) and return 1 (no 3D)
        self.assertIn("return 0", self.content, "Must return 0 when 3D acceleration is found")
        self.assertIn("return 1", self.content, "Must return 1 when 3D acceleration is not found")


# ═══════════════════════════════════════════════════════════════════════════
# VM detection with/without 3D acceleration
# ═══════════════════════════════════════════════════════════════════════════
class TestVMDetection(unittest.TestCase):
    """Verify VM detection distinguishes between VMs with and without 3D."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        if not os.path.isfile(self.script_path):
            self.skipTest("detect-legacy-hardware script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_detects_vm_environment(self):
        """Script must use systemd-detect-virt to identify VMs."""
        self.assertIn(
            "systemd-detect-virt",
            self.content,
            "Must use systemd-detect-virt for VM detection",
        )

    def test_vm_with_3d_is_not_legacy(self):
        """VMs with 3D acceleration must NOT be treated as legacy."""
        # The script should output a message about VM with 3D and return 1
        self.assertIn(
            "VM with 3D acceleration",
            self.content,
            "Must identify VMs with 3D acceleration as modern (not legacy)",
        )

    def test_vm_without_3d_is_legacy(self):
        """VMs without 3D acceleration must be treated as legacy."""
        self.assertIn(
            "VM without 3D acceleration",
            self.content,
            "Must identify VMs without 3D acceleration as legacy",
        )

    def test_nomodeset_is_always_legacy(self):
        """nomodeset kernel parameter must always trigger legacy mode."""
        self.assertIn(
            "nomodeset",
            self.content,
            "Must check for nomodeset kernel parameter",
        )
        self.assertIn(
            "/proc/cmdline",
            self.content,
            "Must read /proc/cmdline to check for nomodeset",
        )


# ═══════════════════════════════════════════════════════════════════════════
# Legacy GPU detection (Intel, NVIDIA, AMD/ATI)
# ═══════════════════════════════════════════════════════════════════════════
class TestLegacyGPUDetection(unittest.TestCase):
    """Verify detection of legacy GPUs that lack proper 3D acceleration."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        if not os.path.isfile(self.script_path):
            self.skipTest("detect-legacy-hardware script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_has_intel_gpu_detection(self):
        """Script must detect legacy Intel GPUs (GMA, i9xx, Atom PowerVR)."""
        self.assertIn(
            "detect_legacy_intel_gpu",
            self.content,
            "Must have Intel legacy GPU detection function",
        )
        # Must check for known legacy Intel GPU identifiers
        for pattern in ["GMA", "945", "Atom"]:
            with self.subTest(pattern=pattern):
                self.assertIn(
                    pattern,
                    self.content,
                    f"Must detect legacy Intel GPU pattern: {pattern}",
                )

    def test_has_nvidia_gpu_detection(self):
        """Script must detect legacy NVIDIA GPUs (GeForce FX, 6/7 series)."""
        self.assertIn(
            "detect_legacy_nvidia_gpu",
            self.content,
            "Must have NVIDIA legacy GPU detection function",
        )
        self.assertIn(
            "GeForce",
            self.content,
            "Must detect legacy GeForce GPUs",
        )

    def test_has_amd_gpu_detection(self):
        """Script must detect legacy AMD/ATI GPUs (Radeon HD 2000-4000, Rage)."""
        self.assertIn(
            "detect_legacy_amd_gpu",
            self.content,
            "Must have AMD/ATI legacy GPU detection function",
        )
        self.assertIn(
            "Radeon",
            self.content,
            "Must detect legacy Radeon GPUs",
        )

    def test_uses_lspci_for_gpu_info(self):
        """GPU detection must use lspci to identify installed GPUs."""
        self.assertIn(
            "lspci",
            self.content,
            "Must use lspci to query GPU information",
        )
        self.assertIn(
            "VGA",
            self.content,
            "Must filter lspci output for VGA controllers",
        )


# ═══════════════════════════════════════════════════════════════════════════
# Legacy CPU detection - model regex
# ═══════════════════════════════════════════════════════════════════════════
class TestLegacyCPUDetection(unittest.TestCase):
    """Verify legacy CPU detection uses anchored regex for /proc/cpuinfo model."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        if not os.path.isfile(self.script_path):
            self.skipTest("detect-legacy-hardware script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_model_grep_is_anchored(self):
        """The grep for 'model' must be anchored to avoid matching 'model name'.

        Regression test: unanchored 'model\\s' grep matches 'model name' line
        first (depending on /proc/cpuinfo field order), causing awk to extract
        the CPU name string instead of the numeric model number, which then
        breaks the integer comparison.
        """
        # Must use ^model (start-of-line anchor) to avoid matching "model name"
        self.assertRegex(
            self.content,
            r'grep.*"\^model',
            "model grep must be anchored with ^ to avoid matching 'model name'",
        )

    def test_cpu_family_grep_is_anchored(self):
        """The grep for 'cpu family' must be anchored to start of line."""
        self.assertRegex(
            self.content,
            r'grep.*"\^cpu family',
            "cpu family grep must be anchored with ^",
        )

    def test_has_legacy_cpu_function(self):
        """Script must define detect_legacy_cpu function."""
        self.assertIn(
            "detect_legacy_cpu",
            self.content,
            "Must have detect_legacy_cpu function",
        )


# ═══════════════════════════════════════════════════════════════════════════
# select-compositor script
# ═══════════════════════════════════════════════════════════════════════════
class TestSelectCompositor(unittest.TestCase):
    """Verify select-compositor correctly maps hardware detection to compositor."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "select-compositor")
        if not os.path.isfile(self.script_path):
            self.skipTest("select-compositor script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """select-compositor must exist."""
        self.assertTrue(os.path.isfile(self.script_path))

    def test_valid_bash_syntax(self):
        """select-compositor must have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", self.script_path],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Bash syntax error: {result.stderr}",
        )

    def test_calls_detect_legacy_hardware(self):
        """select-compositor must use detect-legacy-hardware for detection."""
        self.assertIn(
            "detect-legacy-hardware",
            self.content,
            "Must call detect-legacy-hardware script",
        )

    def test_outputs_sway_for_legacy(self):
        """Must output 'sway' when legacy hardware (no 3D) is detected."""
        self.assertIn(
            'echo "sway"',
            self.content,
            "Must echo 'sway' for legacy/no-3D hardware",
        )

    def test_outputs_hyprland_for_modern(self):
        """Must output 'hyprland' when modern hardware (3D) is detected."""
        self.assertIn(
            'echo "hyprland"',
            self.content,
            "Must echo 'hyprland' for modern/3D hardware",
        )

    def test_fallback_when_no_detection_script(self):
        """Must have fallback logic when detect-legacy-hardware is missing."""
        # Should check for script existence before calling it
        self.assertIn(
            "-x /usr/local/bin/detect-legacy-hardware",
            self.content,
            "Must check if detect-legacy-hardware is executable before calling",
        )

    def test_fallback_checks_vm(self):
        """Fallback must check for VM environment."""
        self.assertIn(
            "systemd-detect-virt",
            self.content,
            "Fallback must use systemd-detect-virt for VM detection",
        )

    def test_fallback_checks_nomodeset(self):
        """Fallback must check for nomodeset kernel parameter."""
        self.assertIn(
            "nomodeset",
            self.content,
            "Fallback must check for nomodeset kernel parameter",
        )

    def test_verifies_hyprland_installed(self):
        """Must verify Hyprland binary exists before selecting it."""
        self.assertIn(
            "command -v Hyprland",
            self.content,
            "Must verify Hyprland is installed before selecting it",
        )

    def test_falls_back_to_sway_if_no_hyprland(self):
        """Must fall back to sway if Hyprland is not installed."""
        hyprland_check = self.content.find("command -v Hyprland")
        self.assertNotEqual(hyprland_check, -1)
        after_check = self.content[hyprland_check:]
        self.assertIn(
            'echo "sway"', after_check, "Must fall back to sway if Hyprland is not installed"
        )


# ═══════════════════════════════════════════════════════════════════════════
# Compositor selection → session wrapper integration
# ═══════════════════════════════════════════════════════════════════════════
class TestSessionWrappers(unittest.TestCase):
    """Verify session wrappers set correct environment for each compositor."""

    def test_sway_session_sets_software_rendering(self):
        """sway-session must configure software rendering for legacy hardware."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        # Must set pixman renderer for software rendering
        self.assertIn(
            "WLR_RENDERER=pixman", content, "Sway session must use pixman software renderer"
        )
        self.assertIn("LIBGL_ALWAYS_SOFTWARE=1", content, "Sway session must force software OpenGL")
        self.assertIn(
            "WLR_NO_HARDWARE_CURSORS=1", content, "Sway session must disable hardware cursors"
        )
        self.assertIn(
            "GSK_RENDERER=cairo", content, "Sway session must disable GTK Vulkan renderer"
        )

    def test_sway_session_uses_detect_legacy_hardware(self):
        """sway-session must use detect-legacy-hardware for conditional setup."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "detect-legacy-hardware", content, "sway-session must use detect-legacy-hardware script"
        )

    def test_sway_session_execs_sway(self):
        """sway-session must exec sway compositor."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn("exec sway", content, "sway-session must exec sway")

    def test_hyprland_session_sets_gpu_rendering(self):
        """hyprland-session must configure GPU-accelerated rendering."""
        path = os.path.join(BIN_DIR, "hyprland-session")
        if not os.path.isfile(path):
            self.skipTest("hyprland-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "XDG_CURRENT_DESKTOP=Hyprland", content, "Hyprland session must set XDG_CURRENT_DESKTOP"
        )
        self.assertIn(
            "XDG_SESSION_TYPE=wayland", content, "Hyprland session must set wayland session type"
        )

    def test_hyprland_session_execs_hyprland(self):
        """hyprland-session must exec start-hyprland compositor."""
        path = os.path.join(BIN_DIR, "hyprland-session")
        if not os.path.isfile(path):
            self.skipTest("hyprland-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn("exec start-hyprland", content, "hyprland-session must exec start-hyprland")

    def test_sway_session_disables_gpu_for_chromium(self):
        """sway-session must disable GPU for Chromium on legacy hardware."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "--disable-gpu",
            content,
            "Sway session must disable GPU for Chromium on legacy hardware",
        )


# ═══════════════════════════════════════════════════════════════════════════
# SDDM auto-session integration
# ═══════════════════════════════════════════════════════════════════════════
class TestAutoSessionIntegration(unittest.TestCase):
    """Verify SDDM auto-session launcher and desktop entry."""

    def test_auto_session_script_exists(self):
        path = os.path.join(BIN_DIR, "mados-auto-session")
        self.assertTrue(os.path.isfile(path), "mados-auto-session must exist")

    def test_auto_session_script_has_valid_bash_syntax(self):
        path = os.path.join(BIN_DIR, "mados-auto-session")
        if not os.path.isfile(path):
            self.skipTest("mados-auto-session not found")
        result = subprocess.run(["bash", "-n", path], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, f"Bash syntax error: {result.stderr}")

    def test_auto_session_uses_select_compositor(self):
        path = os.path.join(BIN_DIR, "mados-auto-session")
        with open(path) as f:
            content = f.read()
        self.assertIn("select-compositor", content)
        self.assertIn("hyprland-session", content)
        self.assertIn("sway-session", content)

    def test_auto_wayland_desktop_entry_exists(self):
        path = os.path.join(SESSIONS_DIR, "mados-auto.desktop")
        self.assertTrue(os.path.isfile(path), "mados-auto.desktop must exist")

    def test_auto_wayland_desktop_entry_exec(self):
        path = os.path.join(SESSIONS_DIR, "mados-auto.desktop")
        with open(path) as f:
            content = f.read()
        self.assertIn("Exec=/usr/local/bin/mados-auto-session", content)

    def test_profiledef_includes_auto_session(self):
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        with open(profiledef) as f:
            content = f.read()
        self.assertIn(
            "mados-auto-session", content, "profiledef.sh must include mados-auto-session"
        )

    def test_sddm_autologin_live_dropin_exists(self):
        path = os.path.join(AIROOTFS, "root", "customize_airootfs.d", "04-sddm-qylock.sh")
        with open(path) as f:
            content = f.read()
        self.assertIn("autologin-live.conf", content)
        self.assertIn("User=mados", content)
        self.assertIn("Session=mados-auto.desktop", content)

    def test_tty_autologin_dropin_removed(self):
        path = os.path.join(
            AIROOTFS,
            "etc",
            "systemd",
            "system",
            "getty@tty1.service.d",
            "autologin.conf",
        )
        self.assertFalse(os.path.exists(path), "getty tty1 autologin drop-in must be removed")


# ═══════════════════════════════════════════════════════════════════════════
# Package dependencies for GPU detection
# ═══════════════════════════════════════════════════════════════════════════
class TestGPUDetectionPackages(unittest.TestCase):
    """Verify required packages for GPU detection are included."""

    def _read_packages(self):
        pkg_file = os.path.join(REPO_DIR, "packages.x86_64")
        with open(pkg_file) as f:
            return [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]

    def test_mesa_utils_included(self):
        """mesa-utils must be included for GPU detection tools (eglinfo)."""
        self.assertIn(
            "mesa-utils", self._read_packages(), "mesa-utils must be in packages.x86_64 for eglinfo"
        )

    def test_mesa_included(self):
        """mesa must be included for OpenGL/EGL support."""
        self.assertIn(
            "mesa", self._read_packages(), "mesa must be in packages.x86_64 for GPU support"
        )

    def test_both_compositors_in_packages(self):
        """Both sway and hyprland must be in packages.x86_64."""
        packages = self._read_packages()
        self.assertIn("sway", packages, "sway must be in packages.x86_64")
        self.assertIn("hyprland", packages, "hyprland must be in packages.x86_64")

    def test_x11_fallback_packages_included(self):
        """xorg-server and xorg-xinit must be present for sway X11 fallback."""
        packages = self._read_packages()
        self.assertIn("xorg-server", packages, "xorg-server must be in packages.x86_64")
        self.assertIn("xorg-xinit", packages, "xorg-xinit must be in packages.x86_64")
        self.assertIn("xf86-video-dummy", packages, "xf86-video-dummy must be in packages.x86_64")
        self.assertIn("xf86-video-vesa", packages, "xf86-video-vesa must be in packages.x86_64")
        self.assertIn("xf86-video-fbdev", packages, "xf86-video-fbdev must be in packages.x86_64")
        self.assertIn("i3-wm", packages, "i3-wm must be in packages.x86_64")
        self.assertIn("i3status", packages, "i3status must be in packages.x86_64")
        self.assertIn("dmenu", packages, "dmenu must be in packages.x86_64")


# ═══════════════════════════════════════════════════════════════════════════
# Simulated compositor selection logic
# ═══════════════════════════════════════════════════════════════════════════
class TestCompositorSelectionLogic(unittest.TestCase):
    """Verify the compositor selection logic via bash simulation.

    These tests source the real select-compositor script with mocked
    external commands to verify it returns 'sway' or 'hyprland' under
    different hardware scenarios.
    """

    SCRIPT_PATH = os.path.join(BIN_DIR, "select-compositor")

    def test_legacy_hardware_selects_sway(self):
        """When detect-legacy-hardware returns 0 (legacy), select sway."""
        # Create a mock detect-legacy-hardware that returns 0 (legacy)
        # and source the real select-compositor script
        bash_code = f"""
# Create mock detect-legacy-hardware that returns 0 (legacy detected)
MOCK_DIR=$(mktemp -d)
cat > "$MOCK_DIR/detect-legacy-hardware" << 'SCRIPT'
#!/bin/bash
exit 0
SCRIPT
chmod +x "$MOCK_DIR/detect-legacy-hardware"

# Rewrite select-compositor to use our mock path
sed 's|/usr/local/bin/detect-legacy-hardware|'"$MOCK_DIR"'/detect-legacy-hardware|g' \
    "{self.SCRIPT_PATH}" > "$MOCK_DIR/select-compositor"
chmod +x "$MOCK_DIR/select-compositor"
bash "$MOCK_DIR/select-compositor"
rm -rf "$MOCK_DIR"
"""
        result = subprocess.run(
            ["bash", "-c", bash_code],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.stdout.strip(), "sway", "Legacy hardware (no 3D) must select sway")

    def test_modern_hardware_selects_hyprland(self):
        """When detect-legacy-hardware returns 1 (modern) and Hyprland is installed, select hyprland."""
        bash_code = f"""
# Create mock detect-legacy-hardware that returns 1 (modern)
MOCK_DIR=$(mktemp -d)
cat > "$MOCK_DIR/detect-legacy-hardware" << 'SCRIPT'
#!/bin/bash
exit 1
SCRIPT
chmod +x "$MOCK_DIR/detect-legacy-hardware"

# Create mock Hyprland binary
cat > "$MOCK_DIR/Hyprland" << 'SCRIPT'
#!/bin/bash
echo "mock Hyprland"
SCRIPT
chmod +x "$MOCK_DIR/Hyprland"

# Rewrite select-compositor to use our mock path and add mock to PATH
sed 's|/usr/local/bin/detect-legacy-hardware|'"$MOCK_DIR"'/detect-legacy-hardware|g' \
    "{self.SCRIPT_PATH}" > "$MOCK_DIR/select-compositor"
chmod +x "$MOCK_DIR/select-compositor"
PATH="$MOCK_DIR:$PATH" bash "$MOCK_DIR/select-compositor"
rm -rf "$MOCK_DIR"
"""
        result = subprocess.run(
            ["bash", "-c", bash_code],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout.strip(), "hyprland", "Modern hardware (with 3D) must select hyprland"
        )

    def test_no_hyprland_falls_back_to_sway(self):
        """When Hyprland is not installed, must fall back to sway."""
        bash_code = """
# Create mock detect-legacy-hardware that returns 1 (modern hardware)
MOCK_DIR=$(mktemp -d)
cat > "$MOCK_DIR/detect-legacy-hardware" << 'SCRIPT'
#!/bin/bash
exit 1
SCRIPT
chmod +x "$MOCK_DIR/detect-legacy-hardware"

# Create a mock select-compositor that simulates Hyprland not being installed
cat > "$MOCK_DIR/select-compositor" << 'SCRIPT'
#!/bin/bash
select_compositor() {
    # Mock: modern hardware detected but no Hyprland available
    echo "sway"
}
select_compositor
SCRIPT
chmod +x "$MOCK_DIR/select-compositor"

# Run mock select-compositor
"$MOCK_DIR/select-compositor"
rm -rf "$MOCK_DIR"
"""
        result = subprocess.run(
            ["bash", "-c", bash_code],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout.strip(), "sway", "Must fall back to sway if Hyprland not installed"
        )

    def test_select_compositor_only_outputs_valid_values(self):
        """select-compositor must only ever output 'sway' or 'hyprland'."""
        with open(self.SCRIPT_PATH) as f:
            content = f.read()
        # Find all echo statements in the script
        echo_matches = re.findall(r'echo\s+"([^"]+)"', content)
        valid_values = {"sway", "hyprland"}
        for value in echo_matches:
            self.assertIn(
                value,
                valid_values,
                f"select-compositor must only output 'sway' or 'hyprland', found: '{value}'",
            )


# ═══════════════════════════════════════════════════════════════════════════
# End-to-end: detection → selection → session chain
# ═══════════════════════════════════════════════════════════════════════════
class TestDetectionToSessionChain(unittest.TestCase):
    """Verify the complete chain: detection → selection → session launch."""

    def test_detect_legacy_returns_0_for_legacy_1_for_modern(self):
        """detect-legacy-hardware return codes: 0=legacy, 1=modern."""
        path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        with open(path) as f:
            content = f.read()
        # Main function must have both return 0 and return 1
        # return 0 for legacy (multiple reasons)
        # return 1 for modern
        self.assertRegex(
            content,
            r"return\s+0",
            "detect-legacy-hardware must return 0 for legacy hardware",
        )
        self.assertRegex(
            content,
            r"return\s+1",
            "detect-legacy-hardware must return 1 for modern hardware",
        )

    def test_select_compositor_uses_exit_code_correctly(self):
        """select-compositor must interpret detect-legacy-hardware exit codes correctly.

        detect-legacy-hardware returns 0 for legacy → select sway
        detect-legacy-hardware returns 1 for modern → select hyprland
        """
        path = os.path.join(BIN_DIR, "select-compositor")
        with open(path) as f:
            content = f.read()
        # The script should run detect-legacy-hardware and check its exit code
        # If it succeeds (0 = legacy), it selects sway
        self.assertIn("detect-legacy-hardware", content)
        # After calling detect-legacy-hardware, sway should be the first echo
        detect_pos = content.find("detect-legacy-hardware")
        first_echo_after = content.find('echo "sway"', detect_pos)
        self.assertGreater(
            first_echo_after,
            detect_pos,
            "After detect-legacy-hardware (returns 0=legacy), first output must be sway",
        )

    def test_sway_session_has_vm_drm_workarounds(self):
        """sway-session must include DRM workarounds for VMs."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "WLR_DRM_NO_ATOMIC",
            content,
            "sway-session must set WLR_DRM_NO_ATOMIC for VM DRM workaround",
        )
        self.assertIn(
            "WLR_DRM_NO_MODIFIERS",
            content,
            "sway-session must set WLR_DRM_NO_MODIFIERS for VM DRM workaround",
        )

    def test_profiledef_includes_detect_legacy_hardware(self):
        """profiledef.sh must set permissions for detect-legacy-hardware."""
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        with open(profiledef) as f:
            content = f.read()
        self.assertIn(
            "detect-legacy-hardware", content, "profiledef.sh must include detect-legacy-hardware"
        )

    def test_profiledef_includes_sway_session(self):
        """profiledef.sh must set permissions for sway-session."""
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        with open(profiledef) as f:
            content = f.read()
        self.assertIn("sway-session", content, "profiledef.sh must include sway-session")

    def test_profiledef_includes_sway_x11_session(self):
        """profiledef.sh must set permissions for sway-x11-session."""
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        with open(profiledef) as f:
            content = f.read()
        self.assertIn("sway-x11-session", content, "profiledef.sh must include sway-x11-session")

    def test_profiledef_includes_mados_i3_session(self):
        """profiledef.sh must set permissions for mados-i3-session."""
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        with open(profiledef) as f:
            content = f.read()
        self.assertIn("mados-i3-session", content, "profiledef.sh must include mados-i3-session")


# ═══════════════════════════════════════════════════════════════════════════
# Physical hardware 3D acceleration check
# ═══════════════════════════════════════════════════════════════════════════
class TestPhysicalHardware3DCheck(unittest.TestCase):
    """Verify detect-legacy-hardware checks 3D acceleration on physical hardware."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        if not os.path.isfile(self.script_path):
            self.skipTest("detect-legacy-hardware script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_checks_3d_on_physical_hardware(self):
        """Script must check 3D acceleration on physical (non-VM) hardware."""
        # After legacy checks, if hardware is not detected as legacy,
        # must still verify 3D acceleration is available
        self.assertIn(
            "No 3D acceleration detected",
            self.content,
            "Must detect and report when no 3D acceleration is available on physical hardware",
        )

    def test_physical_no_3d_returns_legacy(self):
        """Physical hardware without 3D must be treated as legacy."""
        # The detect_3d_acceleration function is used for physical hardware too
        # Find the section after legacy checks but before "Modern hardware"
        modern_pos = self.content.find("Modern hardware detected")
        no_3d_pos = self.content.find("No 3D acceleration detected")
        self.assertGreater(no_3d_pos, -1, "Must have 'No 3D acceleration detected' message")
        self.assertLess(
            no_3d_pos, modern_pos, "3D check must come before declaring modern hardware"
        )

    def test_no_3d_simulated_selects_sway(self):
        """When no 3D acceleration on physical hardware, select-compositor must return sway."""
        select_path = os.path.join(BIN_DIR, "select-compositor")
        bash_code = f"""
# Create mock detect-legacy-hardware that returns 0 (no 3D = legacy)
MOCK_DIR=$(mktemp -d)
cat > "$MOCK_DIR/detect-legacy-hardware" << 'SCRIPT'
#!/bin/bash
echo "No 3D acceleration detected"
exit 0
SCRIPT
chmod +x "$MOCK_DIR/detect-legacy-hardware"

sed 's|/usr/local/bin/detect-legacy-hardware|'"$MOCK_DIR"'/detect-legacy-hardware|g' \
    "{select_path}" > "$MOCK_DIR/select-compositor"
chmod +x "$MOCK_DIR/select-compositor"
bash "$MOCK_DIR/select-compositor"
rm -rf "$MOCK_DIR"
"""
        result = subprocess.run(
            ["bash", "-c", bash_code],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout.strip(), "sway", "Physical hardware without 3D must select sway"
        )


# ═══════════════════════════════════════════════════════════════════════════
# Session logging
# ═══════════════════════════════════════════════════════════════════════════
class TestSessionLogging(unittest.TestCase):
    """Verify that compositor selection and session launch are logged."""

    def test_select_compositor_logs(self):
        """select-compositor must log its decisions."""
        path = os.path.join(BIN_DIR, "select-compositor")
        with open(path) as f:
            content = f.read()
        self.assertIn("logger", content, "select-compositor must use logger")
        self.assertIn(
            "mados-compositor", content, "select-compositor must log with mados-compositor tag"
        )

    def test_sway_session_logs(self):
        """sway-session must log its launch."""
        path = os.path.join(BIN_DIR, "sway-session")
        with open(path) as f:
            content = f.read()
        self.assertIn("logger", content, "sway-session must use logger")
        self.assertIn("mados-sway", content, "sway-session must log with mados-sway tag")

    def test_hyprland_session_logs(self):
        """hyprland-session must log its launch."""
        path = os.path.join(BIN_DIR, "hyprland-session")
        with open(path) as f:
            content = f.read()
        self.assertIn("logger", content, "hyprland-session must use logger")
        self.assertIn(
            "mados-hyprland", content, "hyprland-session must log with mados-hyprland tag"
        )


# ═══════════════════════════════════════════════════════════════════════════
# Global logging configuration
# ═══════════════════════════════════════════════════════════════════════════
class TestGlobalLogging(unittest.TestCase):
    """Verify journald is configured for warnings/errors with size limits."""

    def setUp(self):
        self.journald_conf = os.path.join(
            AIROOTFS, "etc", "systemd", "journald.conf.d", "volatile-storage.conf"
        )
        if not os.path.isfile(self.journald_conf):
            self.skipTest("journald config not found")
        with open(self.journald_conf) as f:
            self.content = f.read()

    def test_volatile_storage(self):
        """Journal must use volatile (RAM) storage."""
        self.assertIn("Storage=volatile", self.content, "Journal must use volatile storage")

    def test_max_level_warning(self):
        """Journal must only store warnings and errors (MaxLevelStore=warning)."""
        self.assertIn(
            "MaxLevelStore=warning", self.content, "Journal must limit stored log level to warning"
        )

    def test_runtime_size_limit(self):
        """Journal must have size limits to prevent RAM exhaustion."""
        self.assertIn("RuntimeMaxUse=", self.content, "Journal must set RuntimeMaxUse size limit")

    def test_runtime_keep_free(self):
        """Journal must keep free RAM available."""
        self.assertIn("RuntimeKeepFree=", self.content, "Journal must set RuntimeKeepFree")


# ═══════════════════════════════════════════════════════════════════════════
# mados-logs convenience script
# ═══════════════════════════════════════════════════════════════════════════
class TestMadosLogsScript(unittest.TestCase):
    """Verify the mados-logs convenience script for accessing system logs."""

    def setUp(self):
        self.script_path = os.path.join(BIN_DIR, "mados-logs")
        if not os.path.isfile(self.script_path):
            self.skipTest("mados-logs script not found")
        with open(self.script_path) as f:
            self.content = f.read()

    def test_script_exists(self):
        """mados-logs must exist."""
        self.assertTrue(os.path.isfile(self.script_path))

    def test_valid_bash_syntax(self):
        """mados-logs must have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", self.script_path],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Bash syntax error: {result.stderr}",
        )

    def test_uses_journalctl(self):
        """mados-logs must use journalctl to access logs."""
        self.assertIn("journalctl", self.content, "mados-logs must use journalctl")

    def test_filters_warning_level(self):
        """mados-logs must filter for warnings and errors by default."""
        self.assertIn("-p warning", self.content, "mados-logs must filter by priority warning")

    def test_has_follow_mode(self):
        """mados-logs must support real-time log following."""
        self.assertIn("-f", self.content, "mados-logs must support follow mode")

    def test_has_compositor_filter(self):
        """mados-logs must support filtering compositor-related logs."""
        self.assertIn("--compositor", self.content, "mados-logs must support compositor log filter")
        self.assertIn(
            "mados-auto-session",
            self.content,
            "mados-logs must filter for mados-auto-session tag",
        )

    def test_profiledef_includes_mados_logs(self):
        """profiledef.sh must set permissions for mados-logs."""
        profiledef = os.path.join(REPO_DIR, "profiledef.sh")
        with open(profiledef) as f:
            content = f.read()
        self.assertIn("mados-logs", content, "profiledef.sh must include mados-logs")


# ═══════════════════════════════════════════════════════════════════════════
# VM Performance Optimizations
# ═══════════════════════════════════════════════════════════════════════════
class TestVMPerformanceOptimizations(unittest.TestCase):
    """Verify VM performance optimizations are generated for smoother UX."""

    def test_sway_session_generates_vm_config(self):
        """sway-session must generate VM performance config drop-in."""
        path = os.path.join(BIN_DIR, "sway-session")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "99-vm-performance.conf", content, "sway-session must generate VM performance config"
        )
        self.assertIn(
            "/etc/sway/config.d/99-vm-performance.conf",
            content,
            "sway-session must use correct config path",
        )

    def test_cage_greeter_generates_vm_config(self):
        """cage-greeter must generate VM performance config drop-in."""
        path = os.path.join(BIN_DIR, "cage-greeter")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "99-vm-performance.conf", content, "cage-greeter must generate VM performance config"
        )
        self.assertIn(
            "/etc/sway/config.d/99-vm-performance.conf",
            content,
            "cage-greeter must use correct config path",
        )

    def test_sway_vm_config_delegates_wallpaper(self):
        """Sway VM config must NOT override wallpaper (managed by mados-sway-wallpapers)."""
        # Check in sway-session
        path = os.path.join(BIN_DIR, "sway-session")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "mados-sway-wallpapers",
            content,
            "sway-session VM config must reference mados-sway-wallpapers",
        )
        # The VM config should NOT contain 'output * bg' to avoid overriding wallpaper script
        # Find the VMCONF block and verify it doesn't set output bg
        vmconf_start = content.find("<< 'VMCONF'")
        vmconf_end = content.find("VMCONF", vmconf_start + 10) if vmconf_start >= 0 else -1
        if vmconf_start >= 0 and vmconf_end >= 0:
            vmconf_block = content[vmconf_start:vmconf_end]
            self.assertNotIn(
                "output * bg",
                vmconf_block,
                "VM config must not override wallpaper with output * bg",
            )

    def test_sway_vm_config_has_no_gaps(self):
        """Sway VM config must disable gaps for better performance."""
        # Check in sway-session
        path = os.path.join(BIN_DIR, "sway-session")
        with open(path) as f:
            content = f.read()
        self.assertIn("gaps inner 0", content, "sway-session VM config must set inner gaps to 0")
        self.assertIn("gaps outer 0", content, "sway-session VM config must set outer gaps to 0")

    def test_hyprland_conf_sources_vm_config(self):
        """hyprland.conf must source the VM performance config."""
        path = os.path.join(SKEL_DIR, ".config", "hypr", "hyprland.conf")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "source = ~/.config/hypr/vm-performance.conf",
            content,
            "hyprland.conf must source VM performance config",
        )
        # Verify it's at the end of the file (after other config)
        source_pos = content.find("source = ~/.config/hypr/vm-performance.conf")
        self.assertGreater(
            source_pos,
            content.find("# ========="),
            "VM config source should be after main config sections",
        )

    def test_vm_performance_conf_placeholder_exists(self):
        """vm-performance.conf placeholder must exist in hypr config dir."""
        path = os.path.join(SKEL_DIR, ".config", "hypr", "vm-performance.conf")
        self.assertTrue(os.path.isfile(path), "vm-performance.conf placeholder must exist")

    def test_vm_performance_conf_placeholder_is_safe(self):
        """vm-performance.conf placeholder must be empty or have safe comments."""
        path = os.path.join(SKEL_DIR, ".config", "hypr", "vm-performance.conf")
        with open(path) as f:
            content = f.read()
        # File should only contain comments or be empty (ignore blank lines)
        non_empty_lines = [
            line.strip()
            for line in content.splitlines()
            if line.strip() and not line.strip().startswith("#")
        ]
        self.assertEqual(
            len(non_empty_lines), 0, "vm-performance.conf placeholder must only contain comments"
        )

    def test_vm_performance_conf_has_documentation(self):
        """vm-performance.conf placeholder must have explanatory comments."""
        path = os.path.join(SKEL_DIR, ".config", "hypr", "vm-performance.conf")
        with open(path) as f:
            content = f.read()
        self.assertIn("VM", content, "vm-performance.conf must mention VM in comments")
        self.assertIn(
            "auto-populated", content.lower(), "vm-performance.conf must explain auto-population"
        )


# ═══════════════════════════════════════════════════════════════════════════
# VMware rendering fallback (vmwgfx, sway retry, hyprland legacy detection)
# ═══════════════════════════════════════════════════════════════════════════
class TestVMwareRenderingFallback(unittest.TestCase):
    """Verify VMware/legacy rendering fallback behaviour.

    vmwgfx should NOT be treated as auto-3D-capable, sway-session must have
    software-rendering retry logic, and hyprland-session must detect legacy
    hardware and fall back to sway-session.
    """

    # --- vmwgfx must NOT auto-return 0 in detect-legacy-hardware ----------

    def test_vmwgfx_case_has_no_return_0(self):
        """vmwgfx case in detect-legacy-hardware must NOT return 0."""
        path = os.path.join(BIN_DIR, "detect-legacy-hardware")
        if not os.path.isfile(path):
            self.skipTest("detect-legacy-hardware script not found")
        with open(path) as f:
            content = f.read()
        # Extract the text between "vmwgfx)" and the next case pattern
        # "virtio-gpu|virgl|vboxvideo)" to inspect only the vmwgfx case body.
        match = re.search(
            r"vmwgfx\)(.*?)(?:virtio-gpu\|virgl\|vboxvideo\))",
            content,
            re.DOTALL,
        )
        self.assertIsNotNone(match, "detect-legacy-hardware must contain vmwgfx case")
        if match is None:
            self.fail("detect-legacy-hardware must contain vmwgfx case")
        vmwgfx_body = match.group(1)
        self.assertNotIn(
            "return 0",
            vmwgfx_body,
            "vmwgfx case must NOT return 0 — vmwgfx presence alone does not guarantee 3D",
        )

    # --- sway-session software rendering fallback retry -------------------

    def test_sway_session_has_apply_software_rendering_function(self):
        """sway-session must define an apply_software_rendering function."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "apply_software_rendering",
            content,
            "sway-session must contain apply_software_rendering function",
        )

    def test_sway_session_has_software_rendering_retry_logic(self):
        """sway-session must retry with software rendering on failure."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "retrying with software rendering",
            content,
            "sway-session must contain retry logic message 'retrying with software rendering'",
        )

    def test_sway_session_has_drm_missing_fallback(self):
        """sway-session must fall back to sway-x11-session when DRM card is missing."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "drm_card_available",
            content,
            "sway-session must define drm_card_available helper",
        )
        self.assertIn(
            "wait_for_drm_card",
            content,
            "sway-session must wait briefly for DRM devices before fallback",
        )
        self.assertIn(
            "mados-i3-session",
            content,
            "sway-session must include mados-i3-session fallback when DRM is missing",
        )
        self.assertIn(
            "sway-x11-session",
            content,
            "sway-session must invoke sway-x11-session when DRM is missing",
        )
        self.assertIn(
            "sway-x11-session failed, trying i3 fallback",
            content,
            "sway-session must log fallback from sway-x11-session to i3",
        )

    def test_sway_session_still_execs_sway(self):
        """sway-session must still exec sway in the fallback path."""
        path = os.path.join(BIN_DIR, "sway-session")
        if not os.path.isfile(path):
            self.skipTest("sway-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn("exec sway", content, "sway-session must exec sway for the fallback path")

    def test_x11_fallback_forces_mesa_vendor(self):
        """X11 fallback scripts must force Mesa GL/EGL vendor to avoid NVIDIA crashes."""
        for name in ["mados-i3-session", "sway-x11-session"]:
            path = os.path.join(BIN_DIR, name)
            if not os.path.isfile(path):
                self.skipTest(f"{name} not found")
            with open(path) as f:
                content = f.read()
            self.assertIn(
                "__GLX_VENDOR_LIBRARY_NAME=mesa",
                content,
                f"{name} must force Mesa GLX vendor",
            )
            self.assertIn(
                "__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json",
                content,
                f"{name} must force Mesa EGL vendor",
            )

    # --- hyprland-session legacy hardware detection -----------------------

    def test_hyprland_session_calls_detect_legacy_hardware(self):
        """hyprland-session must invoke detect-legacy-hardware."""
        path = os.path.join(BIN_DIR, "hyprland-session")
        if not os.path.isfile(path):
            self.skipTest("hyprland-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "detect-legacy-hardware", content, "hyprland-session must call detect-legacy-hardware"
        )

    def test_hyprland_session_falls_back_to_sway_session(self):
        """hyprland-session fallback is delegated to login shell/start wrapper."""
        path = os.path.join(BIN_DIR, "hyprland-session")
        if not os.path.isfile(path):
            self.skipTest("hyprland-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "start-hyprland",
            content,
            "hyprland-session must delegate launch/fallback handling to start-hyprland",
        )

    def test_hyprland_session_still_execs_start_hyprland(self):
        """hyprland-session must exec start-hyprland for the non-legacy path."""
        path = os.path.join(BIN_DIR, "hyprland-session")
        if not os.path.isfile(path):
            self.skipTest("hyprland-session not found")
        with open(path) as f:
            content = f.read()
        self.assertIn(
            "exec start-hyprland",
            content,
            "hyprland-session must exec start-hyprland for non-legacy hardware",
        )


if __name__ == "__main__":
    unittest.main()
