# madOS

Arch Linux distribution built with `archiso`. Targets modern hardware with GPU acceleration, featuring OpenCode AI assistant, Hyprland desktop environment, and a GTK graphical installer.

## Features

- **Modern GPU Acceleration**: Hyprland compositor with Vulkan/OpenGL support
- **Multi-GPU Support**: NVIDIA, AMD, and Intel drivers included
- **CUDA Support**: NVIDIA CUDA toolkit for GPU computing
- **AI Assistant**: OpenCode integrated out-of-the-box
- **GTK Installer**: External installer (`/usr/local/bin/mados-installer`) for disk installation

## Hardware Targets

- **Minimum**: Intel/AMD integrated graphics, 2GB+ RAM
- **Recommended**: Dedicated GPU (NVIDIA/AMD), 4GB+ RAM

## Differences from madOS-lite

| Feature | madOS | madOS-lite |
|---------|-------|------------|
| Compositor | Hyprland only | Sway only |
| Display Manager | SDDM | greetd + tuigreet |
| GPU Support | NVIDIA, AMD, Intel (modern) | Software rendering only |
| RAM Target | 2GB+ | 1.5GB+ |
| CUDA | ✅ | ❌ |

## Quick Start

```bash
# Build the ISO (requires Arch Linux with archiso)
sudo pacman -S archiso
sudo mkarchiso -v -w work/ -o out/ .
```

Build requirements:
- ~10GB free disk space
- Build artifacts: `work/` (safe to delete after)
- Final ISO: `out/`
- Build time: ~10-20 minutes

## Hardware Targets

- **Minimum**: Intel Atom, 1.9GB RAM
- **Recommended**: Intel/AMD integrated graphics, 4GB+ RAM

## Package Profiles

- `packages.x86_64` is the main profile with GPU acceleration and CUDA support
- `packages.optional-heavy.x86_64` contains optional desktop-heavy extras
- To install extras on an installed system: `sudo pacman -S --needed - < packages.optional-heavy.x86_64`
- Base profile includes Steam + LibreOffice for Word/Excel/PowerPoint support

## Project Structure

```
.
├── airootfs/              # Root filesystem for the ISO
│   ├── etc/               # System configuration
│   │   ├── skel/          # User skeleton files (.config for Hyprland)
│   │   └── systemd/       # Systemd units
│   └── usr/local/bin/     # Custom scripts
│       └── mados-*        # madOS utilities
├── tests/                 # Unit and integration tests
├── .github/               # CI/CD workflows and agents
├── profiledef.sh          # ISO metadata and file permissions
├── packages.x86_64        # Package list
└── pacman.conf            # Pacman configuration
```

## Development

### Common Scripts

```bash
# Main workflow
./build-iso.sh
./run-qemu.sh

# Optional: share built ISO
./serve-iso.sh

# Optional: advanced debugging helpers
./scripts/debug/run-serial.sh
./scripts/debug/run-debug.sh
./scripts/debug/run-no-kvm.sh
./scripts/debug/run-monitor.sh
```

### Testing

```bash
# Run all unit tests
python3 -m pytest tests/ -v

# Run a single test file
python3 -m pytest tests/test_boot_scripts.py -v
```

### Linting

```bash
# Install tools
pip install ruff
pacman -S shellcheck

# Run linters
ruff check .
ruff format .
shellcheck airootfs/usr/local/bin/*.sh
```

### Pre-commit Hooks

```bash
pip install pre-commit
pre-commit install
```

### Launcher (Quickshell) Config

The shell theme is installed from [theme-imperative-dots](https://github.com/madkoding/theme-imperative-dots) during ISO build.

Layout contract used by madOS:

- Theme startup entrypoint: `/usr/share/mados/themes/imperative-dots/scripts/start/start.sh`
- Hypr helper scripts source: `/usr/share/mados/themes/imperative-dots/config/hypr/scripts/`
- Quickshell widgets source: `/usr/share/mados/themes/imperative-dots/scripts/quickshell/`

- Main UI and behavior: `/usr/share/mados/themes/imperative-dots/scripts/quickshell/widgets/launcher/LauncherPopup.qml`
- App discovery and metadata: `/usr/share/mados/themes/imperative-dots/scripts/quickshell/widgets/launcher/list_apps.py`
- Launcher tuning (ranking/UI): `/usr/share/mados/themes/imperative-dots/scripts/quickshell/widgets/launcher/config.json`
- Default hidden apps rules: `/usr/share/mados/themes/imperative-dots/scripts/quickshell/widgets/launcher/hidden-apps.json`

## CI/CD Pipeline

1. **Stage 1**: Unit tests + integration tests (parallel)
2. **Stage 2**: Installer validation in Arch container
3. **Stage 3**: ISO build with mkarchiso
4. **Stage 4**: Upload to Internet Archive
5. **Stage 5**: GitHub Release + website update

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [AGENTS.md](AGENTS.md) - Agentic coding guidelines
- [docs/HARDWARE_QUIRKS.md](docs/HARDWARE_QUIRKS.md) - Hardware compatibility quirks and disable switches
- `airootfs/usr/share/doc/madOS/` - In-system documentation

## License

This project is licensed under `AGPL-3.0-only` (GNU Affero General Public License v3.0 only).
See [LICENSE](LICENSE) for the full text.

madOS is licensed under `AGPL-3.0-only`; the ISO image may include third-party software subject to different licenses.

Third-party packages included in the ISO may use different licenses. See [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
## Resources

- [GitHub](https://github.com/madkoding/mad-os)
- [Issues](https://github.com/madkoding/mad-os/issues)
- [Discussions](https://github.com/madkoding/mad-os/discussions)
