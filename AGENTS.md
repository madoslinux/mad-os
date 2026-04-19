# AGENTS.md - Agentic Coding Guidelines for madOS-lite

## Project Overview

madOS-lite is a lightweight Arch Linux distribution built using `archiso`. It targets legacy hardware (1.9GB RAM) with Intel Atom processors and integrates OpenCode as an AI assistant. The project produces a custom live/installer ISO with a GTK graphical installer and pre-configured Sway desktop environment.

madOS-lite targets systems without 3D hardware acceleration.
- **Live ISO**: Uses TTY-based autologin (no greetd/sddm) to avoid TTY allocation failures in QEMU/legacy environments
- **Normal ISO**: Uses greetd + tuigreet as display manager for proper login management

### imperative-dots Live/Local Workflow

- `../theme-imperative-dots` is the canonical working repository used to iterate on imperative-dots theme fixes.
- The same theme is consumed by madOS during build/install under `/usr/share/mados/themes/imperative-dots`.
- Development flow: edit and test behavior live from `theme-imperative-dots` against the local madOS environment, validate fixes in-session, then commit changes back to `theme-imperative-dots`.
- When investigating visual mismatches, compare all theme files between the local runtime copy and `theme-imperative-dots` before fixing issues.

### Live ISO Boot Flow

#### Autologin via mados-autologin.service
- `airootfs/root/customize_airootfs.d/10-autologin-sway.sh` installs `mados-autologin.service`
- Service runs as `mados` user on TTY1 (graphics session)
- Autologin configured in systemd conf: `/etc/systemd/system/getty@.service.d/autologin.conf`
- TTY policy: **tty1** for Sway desktop, **tty2** for system shell access

#### Desktop Startup via mados-start-desktop
- Entry point: `/usr/local/bin/mados-start-desktop`
- Script handles display environment setup and startup sequence
- Logs to `/var/log/mados-desktop.log` for troubleshooting

#### Logging to /var/log/mados-desktop.log
Startup log captures:
- Kernel cmdline and early boot journal snapshot (`journalctl -b`)
- Runtime environment variables (`DISPLAY`, `XDG_*`, `WAYLAND_DISPLAY`)
- Display device detection (`/dev/dri`, `/dev/fb*`)
- Xorg startup state and socket readiness (`/tmp/.X11-unix/X0`)
- Sway launch attempt and runtime errors

#### TTY Policy
- **tty1**:graphics session (Sway via autologin)
- **tty2**: system shell access (for troubleshooting without network)
- Prevents conflict between graphical session and system shell

### Live ISO Debug Protocol (Mandatory)

- For remote live debugging, connect explicitly with `ssh -p 2222 mados@127.0.0.1` (password `mados`).
- Do not switch to alternate SSH ports when the session is expected on `2222`.
- When the desktop fails to start, inspect `/var/log/mados-desktop.log` first; this file captures boot-to-graphics bring-up details.
- Primary desktop startup path for no-DRM environments: `Xorg` + `sway` with `WLR_BACKENDS=x11` (no DRM in legacy/QEMU).
- Assume legacy/QEMU targets may not expose `/dev/dri`; do not require DRM for live-session bring-up.
- Do not enable `greetd` for live ISO bring-up; it fails with "no terminal specified" in these environments.
- Keep Safe Compat entries as verbose/debug-friendly boot options.

### Plymouth + Framebuffer Policy

- Plymouth is enabled for normal live boot entries and configured with framebuffer renderer:
  - `airootfs/etc/plymouth/plymouthd.conf` uses `Renderer=frame-buffer`
  - normal entries use `quiet splash` with loglevel=3
  - Handoff: Plymouth retain-splash + 400ms delay for X11 backend startup
- Safe Compat keeps Plymouth disabled (`plymouth.enable=0`) for diagnostics.
- Do not keep an empty override at `airootfs/etc/systemd/system/plymouth.service` because it can suppress Plymouth startup.

### Sway + X11 Backend

- Why we use `WLR_BACKENDS=x11`: No DRM in legacy/QEMU environments; X11 backend provides compatibility
- Xorg startup with fbdev config if `/dev/fb0` exists (fallback for legacy hardware)
- Handoff: Plymouth `retain-splash` + 400ms delay ensures smooth transition from Plymouth to X11/Sway

### Removed Components

- **No greetd**: Fails in live ISO without proper TTY allocation in legacy/QEMU environments
- **No skwd-wall**: Not part of codebase; legacy wallpaper tool replaced by mados-wallpaper
- **No mados-auto-session**: Session management handled by mados-autologin.service
- **No auto-hyprland session**: hyprland disabled; sway is the primary compositor
- **No mados-gamepad-wm**: Not packaged in the distribution
- **No HYPRELAND_INSTANCE_SIGNATURE checks**: hyprland-related logic removed

---

## Build + Debug Commands

```bash
# Build standard ISO (syslinux BIOS + systemd-boot UEFI)
sudo mkarchiso -v -w work/ -o out/ .

# Build with timestamped workdir
sudo mkarchiso -v -w work-$(date +%Y%m%d-%H%M%S)/ -o out/ .

# Serve ISO via HTTP (default port 8000)
./serve-iso.sh
./serve-iso.sh 8080        # custom port
./serve-iso.sh 9000 out/   # custom port and directory

# Boot ISO in QEMU
./run-qemu.sh
```

### Build Requirements
- ~10GB free disk space
- archiso, xorriso, qemu-system-x86_64 installed
- sudo privileges

### Build Artifacts
- `work-*/` — Working directory (safe to delete after build)
- `out/` — Final ISO output
- `out/madOS-dev-x86_64.iso` — Base ISO with syslinux/systemd-boot

---

## Linting Commands

```bash
# Install ruff and shellcheck
pip install ruff
pacman -S shellcheck  # Arch Linux

# Run ruff linter (auto-fix issues where possible)
ruff check .

# Run ruff with fixes
ruff check --fix .

# Run ruff formatter
ruff format .

# Run both lint and format
ruff check --fix . && ruff format .
```

### ShellCheck (Shell Scripts)

```bash
# Install shellcheck (Arch Linux)
sudo pacman -S shellcheck

# Run shellcheck on all executable scripts
find airootfs/usr/local/bin -type f -executable | while read -r script; do
  if head -1 "$script" | grep -qE "(bash|sh)$"; then
    shellcheck -s bash --severity=error "$script"
  fi
done

# Run shellcheck on installer scripts
if [ -d airootfs/usr/local/lib/mados_installer/scripts ]; then
  find airootfs/usr/local/lib/mados_installer/scripts -type f -name "*.sh" | while read -r script; do
    shellcheck -s bash --severity=error "$script"
  done
fi
```

### Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

### Ruff Configuration (pyproject.toml)

```toml
[tool.ruff]
line-length = 100
target-version = "py313"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "C4"]
ignore = ["E501", "E402", "F401"]
```

**Per-file ignores** (defined in `pyproject.toml`):
- `tests/*`: B011, F841, I001, F811, N806, E741, UP015, W293, W291, B905, B007, N802, UP024
- `airootfs/usr/local/lib/mados_*/**`: E402, F401, I001, B904, UP024, W293, W291, UP041, UP015, B905, UP032, B007, F541, F841
- `airootfs/usr/local/bin/*`: I001

---

## Testing Commands

```bash
# Run all unit tests
python3 -m pytest tests/ -v

# Run a single test file
python3 -m pytest tests/test_boot_scripts.py -v

# Run a single test function
python3 -m pytest tests/test_boot_scripts.py::TestBootScriptSyntax::test_all_boot_scripts_valid_syntax -v

# Run tests matching a pattern
python3 -m pytest -k "boot_scripts" -v

# Run with verbose output
python3 -m pytest tests/ -vv

# Run with less output
python3 -m pytest tests/ -q
```

### Integration Tests (require Docker with Arch Linux container)

```bash
# USB Persistence tests
docker run --privileged --rm -v $(pwd):/build archlinux:latest bash /build/tests/test-liveusb-persistence.sh

# First-boot simulation
docker run --privileged --rm -v $(pwd):/build archlinux:latest bash /build/tests/test-first-boot-simulation.sh

# Installer Python validation
docker run --privileged --rm -v $(pwd):/build archlinux:latest bash /build/tests/test-installer-python-validation.sh
```

---

## Code Style Guidelines

### Python

- **Shebang**: `#!/usr/bin/env python3`
- **Formatter**: ruff with double quotes, 100 char line length
- **Target version**: Python 3.13
- **Imports**: Group in order: stdlib, third-party, local; each group separated by blank line
  ```python
  import sys
  import types
  
  from pathlib import Path
  
  from tests.test_helpers import install_gtk_mocks
  ```
- **Types**: Use type hints where beneficial; prefer explicit over implicit
- **Error handling**: Use specific exceptions; avoid bare `except:`
  ```python
  # Good
  except FileNotFoundError as e:
      log.error(f"Config missing: {e}")
  
  # Bad
  except:
      pass
  ```
- **Naming**: snake_case for functions/variables, PascalCase for classes, UPPER_SNAKE for constants
- **Strings**: Use double quotes consistently
- **Docstrings**: Use triple double quotes, present tense, imperative mood

### Shell Scripts

- **Shebang**: `#!/usr/bin/env bash`
- **Linter**: shellcheck (follow shellcheck guidelines)
- **Strict mode**: Use `set -euo pipefail` for all scripts
- **Exception**: Setup scripts that run as systemd services may skip strict mode if they have their own graceful error handling

### GTK/Python Installer

- Uses GTK3 with Nord color scheme (polar night background, frost accents)
- Some standalone tools (`mados-help`, `mados-power`) use GTK4 for better theming
- Check existing scripts to determine which GTK version to use:
  - GTK3: `gi.require_version("Gtk", "3.0")` — Installer and older tools
  - GTK4: `gi.require_version("Gtk", "4.0")` — Standalone UI tools (help, power menu)
- Both versions require `python-gobject` and `gtk3`/`gtk4` packages respectively
- For headless testing, use mocks from `tests/test_helpers.py`:
  ```python
  from tests.test_helpers import install_gtk_mocks
  install_gtk_mocks()
  ```

---

## Repository Structure

### Core archiso Files

- `profiledef.sh` — ISO metadata (name, publisher, version) and file permissions
- `packages.x86_64` — Package list for the ISO (one package per line)
- `pacman.conf` — Pacman configuration for the build

### Boot Configuration

- `grub/` — GRUB bootloader config (UEFI) - deprecated, using systemd-boot
- `syslinux/` — Syslinux config (BIOS)
- `efiboot/` — EFI boot loader configuration

### Root Filesystem (`airootfs/`)

- `airootfs/etc/` — System configuration (sysctl, systemd, skel configs)
- `airootfs/usr/local/bin/` — Custom scripts and executables
- `airootfs/usr/local/lib/` — Python library modules for tools
- `airootfs/root/customize_airootfs.d/` — Post-install customization modules

### Build Scripts

- `serve-iso.sh` — HTTP server for ISO distribution
- `run-qemu.sh` — QEMU launcher with GTK display, UEFI, serial log

### Key Scripts

- `airootfs/root/customize_airootfs.d/03-apps.sh` — App installer (clones from GitHub)
- `airootfs/usr/local/bin/mados-installer-autostart` — Launcher for external installer
- `airootfs/usr/local/bin/setup-persistence.sh` — Persistent storage setup
- `airootfs/usr/local/lib/mados_installer/` — Installer Python modules

### Test Structure

- Unit tests: `tests/test_*.py` (Python, pytest with unittest conventions)
- Integration tests: `tests/test-*.sh` (Shell scripts)
- Test helpers: `tests/test_helpers.py` (GTK mocks for headless testing)

### Documentation

- `docs/` — Project documentation and GitHub Pages site
- `docs/PERSISTENCE.md` — Persistent storage documentation
- `docs/DEBUGGING.md` — Debugging guide

---

## Apps Installation (03-apps.sh)

The `03-apps.sh` script installs madOS native applications during ISO build:

```bash
# Key variables
BUILD_DIR="/root/build_tmp"  # Working directory for git clones
INSTALL_DIR="/opt/mados"      # Where apps are installed
BIN_DIR="/usr/local/bin"      # Wrapper scripts location
```

### App Installation Flow
1. Clone repo to `/root/build_tmp/{module_name}_$$/`
2. Move to `/opt/mados/{module_name}/`
3. Create wrapper script in `/usr/local/bin/{app-name}`
4. Copy `.desktop` file to `/usr/share/applications/`

### App Wrapper Patterns

Most apps use `python3 -m {module_name}`:
```bash
#!/bin/bash
export PYTHONPATH="/opt/mados:${PYTHONPATH:-}"
cd "/opt/mados/{module_name}"
exec python3 -m "{module_name}" "$@"
```

**Exception**: mados-installer uses `python3 __main__.py`:
```bash
#!/bin/bash
cd "/opt/mados/mados_installer"
exec python3 __main__.py "$@"
```

### App Repos and Structure

All apps follow a standardized structure with `app.py` as entry point:

| App | Repo | Module Name | Special Handling |
|-----|------|-------------|------------------|
| mados-audio-player | madoslinux | mados_audio_player | Standard `python3 -m` |
| mados-equalizer | madoslinux | mados_equalizer | Standard `python3 -m` |
| mados-launcher | madoslinux | mados_launcher | Standard `python3 -m` |
| mados-pdf-viewer | madoslinux | mados_pdf_viewer | Standard `python3 -m` |
| mados-photo-viewer | madoslinux | mados_photo_viewer | Standard `python3 -m` |
| mados-video-player | madoslinux | mados_video_player | Standard `python3 -m` |
| mados-wallpaper | madoslinux | mados_wallpaper | Has `daemon/` subpackage, uses `python3 -m daemon` |
| mados-installer | madoslinux | mados_installer | Uses `python3 __main__.py` |
| mados-updater | madkoding | mados_updater | Standard `python3 -m` |

### App Structure (Standard)
```
{app_name}/
├── app.py           # Main application code
├── __main__.py      # Entry point for python3 -m
├── {app_name}.desktop  # Desktop entry file
└── ...other files
```

### mados-wallpaper Special Structure
```
mados_wallpaper/
├── app.py
├── __main__.py
├── daemon/
│   ├── __init__.py
│   └── __main__.py      # daemon entry point
└── ...
```

### 03-apps.sh Error Handling
- Script stops on first failure (no `|| true`)
- 3 retry attempts with 2 second delays for git clone
- Builds in `/root/build_tmp` instead of `/tmp` (more stable in chroot)

---

## Important Guidelines

- Keep `python`, `python-gobject`, and `gtk3` in `packages.x86_64` (required for the installer)
- RAM optimizations target 1.9GB systems — avoid adding heavy packages without justification
- When adding new scripts to `airootfs/usr/local/bin/`, update `profiledef.sh` with proper permissions (0:0:755)
- When modifying the installer, update tests in `tests/test_installer_config.py`
- Desktop configs live in `airootfs/etc/skel/.config/` (Sway, Waybar, Foot, Wofi)
- System name: "madOS" (all lowercase in filenames, styled in display text)
- File permissions: New executable scripts must be added to `profiledef.sh` `file_permissions` array
- Package additions: Add one package per line to `packages.x86_64`
- ZRAM and kernel tuning configs are in `airootfs/etc/sysctl.d/` and `airootfs/etc/systemd/`

---

## CI/CD Pipeline

The CI/CD pipeline (`.github/workflows/ci-cd.yml`) runs in stages:

1. **Stage 1** — Unit tests (pytest, parallel matrix) and integration tests run in parallel
2. **Stage 2** — Installer validation in Arch container (requires Stage 1)
3. **Stage 3** — ISO build with mkarchiso (only on tags or manual trigger)
4. **Stage 4** — Upload to Internet Archive
5. **Stage 5** — GitHub Release and website update (stable releases only)

GitHub Pages deployment is in `.github/workflows/pages.yml`.

---

## Troubleshooting

### QEMU Display Issues
- If SDL fails, use `-display gtk` instead
- If `-soundpcspk` fails, remove it (not supported in newer QEMU versions)
- Ensure `/dev/kvm` is accessible for KVM acceleration

### Git Clone Failures in 03-apps.sh
- Check network connectivity in chroot environment
- Use `ping github.com` to verify
- 03-apps.sh now has retry logic (3 attempts)

### ISO Boot Issues
- Check `out/mados-serial.log` for boot errors
- Use `run-qemu.sh` with serial logging enabled
