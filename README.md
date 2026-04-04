# madOS

AI-orchestrated Arch Linux distribution built with `archiso`. Targets low-RAM systems (1.9GB) with Intel Atom processors, featuring OpenCode AI assistant, Sway/Hyprland desktop environments, and a GTK graphical installer.

## Features

- **Low RAM optimized**: Runs on systems with as little as 1.9GB RAM
- **Dual Compositors**: Sway (software rendering) and Hyprland (modern GPU)
- **AI Assistant**: OpenCode integrated out-of-the-box
- **Persistence**: Dynamic USB persistence with ext4 partition
- **Multi-GPU Support**: Intel, AMD, and NVIDIA drivers included
- **GTK Installer**: External installer (`/usr/local/bin/mados-installer`) for disk installation

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

## Project Structure

```
.
├── airootfs/              # Root filesystem for the ISO
│   ├── etc/               # System configuration
│   │   ├── skel/          # User skeleton files (.config for Sway/Hyprland)
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

## CI/CD Pipeline

1. **Stage 1**: Unit tests + integration tests (parallel)
2. **Stage 2**: Installer validation in Arch container
3. **Stage 3**: ISO build with mkarchiso
4. **Stage 4**: Upload to Internet Archive
5. **Stage 5**: GitHub Release + website update

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [AGENTS.md](AGENTS.md) - Agentic coding guidelines
- `airootfs/usr/share/doc/madOS/` - In-system documentation

## License

See [LICENSE](LICENSE) for details.

## Resources

- [GitHub](https://github.com/madkoding/mad-os)
- [Issues](https://github.com/madkoding/mad-os/issues)
- [Discussions](https://github.com/madkoding/mad-os/discussions)
