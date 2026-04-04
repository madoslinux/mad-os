# AGENTS.md - Agentic Coding Guide for madOS

## Scope

This file is for coding agents working in `mad-os/`.
Follow repository conventions first; do not introduce unrelated tooling or style changes.

madOS is an Arch Linux distribution built with `archiso`, optimized for low-RAM systems (1.9 GB target), with Sway/Hyprland and GTK-based tools.

## Visual Style Source of Truth

Use `/home/madkoding/proyectos/assets` as the primary style reference for branding assets.
Official logos, wallpapers, and related art must be taken from that directory.
When implementing UI or docs visuals, keep consistency with these official assets.

## Build Commands

```bash
# Install build dependency (Arch)
sudo pacman -S archiso

# Build ISO from repository root
sudo mkarchiso -v -w work/ -o out/ .
```

Notes:
- Keep at least ~10 GB free disk space.
- `work/` contains temporary build artifacts; safe to remove after builds.
- Final ISO is written to `out/`.

## Lint / Format Commands

```bash
# Python lint
ruff check .

# Python lint with automatic fixes
ruff check --fix .

# Python formatting
ruff format .

# Shell lint (example target)
shellcheck airootfs/usr/local/bin/*.sh
```

Ruff settings are defined in `pyproject.toml`:
- line length `100`
- target version `py313`
- quote style `double`
- key lint families include `E,F,W,I,N,UP,B,C4`

## Pre-commit

```bash
# Install and enable hooks
python3 -m pip install pre-commit
pre-commit install

# Run all hooks manually
pre-commit run --all-files
```

Current hooks include:
- `shellcheck`
- `ruff`
- `ruff-format`
- `pytest` (selected test files)

## Test Commands

Unit tests use `pytest` with Python tests in `tests/test_*.py`.

```bash
# Run full unit suite
python3 -m pytest tests/ -v

# Run one test file
python3 -m pytest tests/test_boot_scripts.py -v

# Run one test case/function
python3 -m pytest tests/test_boot_scripts.py::TestBootScriptSyntax::test_all_boot_scripts_valid_syntax -v

# Run tests by pattern
python3 -m pytest tests/ -k "boot or liveusb" -v

# Stop on first failure
python3 -m pytest tests/ -x -v
```

Integration-style validation scripts are run via Docker:

```bash
docker run --privileged --rm -v $(pwd):/build archlinux:latest bash /build/tests/test-liveusb-persistence.sh
docker run --privileged --rm -v $(pwd):/build archlinux:latest bash /build/tests/test-first-boot-simulation.sh
docker run --privileged --rm -v $(pwd):/build archlinux:latest bash /build/tests/test-installer-python-validation.sh
```

## Code Style Guidelines

### Imports

- Group imports in this order: standard library, third-party, local project imports.
- Separate groups with one blank line.
- Prefer explicit imports over wildcard imports.

### Formatting

- Python formatting is enforced with `ruff format`.
- Maximum line length is 100.
- Use double quotes in Python unless escaping would be worse.
- Use 4 spaces (no tabs).

### Types

- Add type hints for new/modified public APIs and non-trivial internal helpers.
- Prefer concrete types when helpful (`list[str]`, `dict[str, str]`).
- Keep annotations readable; avoid over-engineered generic types.

### Naming

- `snake_case` for functions/variables/modules.
- `PascalCase` for classes.
- `UPPER_SNAKE_CASE` for constants.
- Keep filenames and script names aligned with existing `mados-*` naming patterns.

### Error Handling

- Raise/handle specific exceptions (`ValueError`, `OSError`, etc.).
- Avoid bare `except:`.
- Fail early on invalid inputs; include actionable error messages.
- In long-running setup scripts, log context before exiting.

### Python and Shell Conventions

- Python shebang: `#!/usr/bin/env python3`.
- Shell shebang: `#!/usr/bin/env bash`.
- Shell scripts should default to `set -euo pipefail` unless a script has a documented reason not to.
- Follow `shellcheck` guidance for shell changes.

## GTK / UI Conventions

- Installer and legacy tools use GTK3 (`gi.require_version("Gtk", "3.0")`).
- Some standalone tools use GTK4; match the existing file's GTK version.
- For headless testing of GTK-dependent code, use mocks from `tests/test_helpers.py`.

## Repository Guardrails

- Keep `python`, `python-gobject`, and `gtk3` in `packages.x86_64` (installer-critical).
- When adding executables under `airootfs/usr/local/bin/`, update `profiledef.sh` file permissions.
- Add packages one per line in `packages.x86_64`.
- Avoid heavy package additions without clear justification (low-RAM target).
- System name convention is `madOS` (lowercase in filenames, branded casing in UI/docs).

## Rules from Copilot / Cursor

Included source:
- `.github/copilot-instructions.md` (present and incorporated here).

Not found in this repository:
- `.cursorrules`
- `.cursor/rules/`

If these files are added later, update this AGENTS.md to mirror their constraints.

## CI Context

Primary pipeline: `.github/workflows/ci-cd.yml`
- Stage 1: unit + integration tests
- Stage 2: installer validation in Arch container
- Stage 3: ISO build (`mkarchiso`)
- Stage 4/5: release publication flow

When changing build/test behavior, keep CI parity with local commands.
