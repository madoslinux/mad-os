#!/usr/bin/env python3
"""Tests for suspend/resume network recovery hook."""

import os
import stat
import subprocess
import tempfile
import unittest


REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
HOOK_PATH = os.path.join(
    REPO_DIR,
    "airootfs",
    "usr",
    "lib",
    "systemd",
    "system-sleep",
    "mados-resume-network-reset",
)


class TestSuspendResumeHook(unittest.TestCase):
    """Validate resume hook behavior with and without marker."""

    def _write_exec(self, path, content):
        with open(path, "w") as f:
            f.write(content)
        os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR)

    def test_valid_bash_syntax(self):
        result = subprocess.run(["bash", "-n", HOOK_PATH], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, f"Bash syntax error: {result.stderr}")

    def test_pre_suspend_does_not_run_actions(self):
        with tempfile.TemporaryDirectory() as tmp:
            marker = os.path.join(tmp, "marker")
            calls = os.path.join(tmp, "calls.log")
            mockbin = os.path.join(tmp, "bin")
            os.makedirs(mockbin, exist_ok=True)

            self._write_exec(
                os.path.join(mockbin, "systemctl"),
                '#!/usr/bin/env bash\nprintf \'systemctl %s\\n\' "$*" >> "$CALLS"\n',
            )
            self._write_exec(
                os.path.join(mockbin, "rfkill"),
                '#!/usr/bin/env bash\nprintf \'rfkill %s\\n\' "$*" >> "$CALLS"\n',
            )
            self._write_exec(os.path.join(mockbin, "logger"), "#!/usr/bin/env bash\nexit 0\n")

            env = dict(os.environ)
            env["PATH"] = f"{mockbin}:{env.get('PATH', '')}"
            env["MADOS_SUSPEND_RESET_MARKER"] = marker
            env["CALLS"] = calls

            result = subprocess.run(
                ["bash", HOOK_PATH, "pre"], env=env, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 0)
            self.assertFalse(os.path.exists(calls), "No actions expected on pre-suspend")

    def test_post_resume_runs_network_recovery_with_marker(self):
        with tempfile.TemporaryDirectory() as tmp:
            marker = os.path.join(tmp, "marker")
            calls = os.path.join(tmp, "calls.log")
            mockbin = os.path.join(tmp, "bin")
            os.makedirs(mockbin, exist_ok=True)

            with open(marker, "w") as f:
                f.write("1\n")

            self._write_exec(
                os.path.join(mockbin, "systemctl"),
                '#!/usr/bin/env bash\nprintf \'systemctl %s\\n\' "$*" >> "$CALLS"\n',
            )
            self._write_exec(
                os.path.join(mockbin, "rfkill"),
                '#!/usr/bin/env bash\nprintf \'rfkill %s\\n\' "$*" >> "$CALLS"\n',
            )
            self._write_exec(os.path.join(mockbin, "logger"), "#!/usr/bin/env bash\nexit 0\n")

            env = dict(os.environ)
            env["PATH"] = f"{mockbin}:{env.get('PATH', '')}"
            env["MADOS_SUSPEND_RESET_MARKER"] = marker
            env["CALLS"] = calls

            result = subprocess.run(
                ["bash", HOOK_PATH, "post"], env=env, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 0)

            with open(calls) as f:
                content = f.read()

            self.assertIn("systemctl try-restart NetworkManager.service", content)
            self.assertIn("rfkill unblock all", content)


if __name__ == "__main__":
    unittest.main()
