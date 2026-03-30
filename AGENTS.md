# AGENTS.md - Agentic Coding Guidelines for madOS

## Project Overview

madOS is an AI-orchestrated Arch Linux distribution built using `archiso`. It targets low-RAM systems (1.9GB) with Intel Atom processors and integrates OpenCode as an AI assistant. The project produces a custom live/installer ISO with a GTK graphical installer and pre-configured Sway desktop environment.

---

## Build Commands

```bash
# Build the ISO (requires Arch Linux with archiso installed)
sudo pacman -S archiso
sudo mkarchiso -v -w work/ -o out/ .
```

- Build requires ~10GB free disk space
- Build artifacts go in `work/` (safe to delete after build)
- Final ISO appears in `out/`
- Build time: ~10-20 minutes

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

- `grub/` — GRUB bootloader config (UEFI)
- `syslinux/` — Syslinux config (BIOS)
- `efiboot/` — EFI boot loader configuration

### Root Filesystem (`airootfs/`)

- `airootfs/etc/` — System configuration (sysctl, systemd, skel configs)
- `airootfs/usr/local/bin/` — Custom scripts and executables
- `airootfs/usr/local/lib/` — Python library modules for tools

### Key Scripts

- `airootfs/usr/local/bin/mados-installer-autostart` — Launcher for external installer
- `airootfs/usr/local/bin/setup-opencode.sh` — OpenCode setup script
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
