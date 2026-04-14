# madOS-lite

Arch Linux distribution built with `archiso`. Targets legacy hardware (1.9GB RAM) with Intel Atom processors, featuring OpenCode AI assistant, Sway desktop environment, and a GTK graphical installer.

madOS-lite uses greetd + tuigreet as display manager and is optimized for systems without 3D hardware acceleration.

## Features

- **Low RAM optimized**: Runs on systems with as little as 1.9GB RAM
- **Software Rendering**: Sway compositor with llvmpipe/pixman
- **AI Assistant**: OpenCode integrated out-of-the-box
- **Persistence**: Dynamic USB persistence with ext4 partition
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

- **Minimum**: Intel Atom, 1.9GB RAM, no 3D GPU
- **Recommended**: Intel integrated graphics, 2GB+ RAM

## Differences from madOS

| Feature | madOS | madOS-lite |
|---------|-------|------------|
| Compositor | Sway | Sway only |
| Display Manager | SDDM | greetd + tuigreet |
| GPU Support | NVIDIA, AMD, Intel (modern) | Software rendering only |
| RAM Target | 1.9GB+ | 1.5GB+ |
| Optional Heavy | GIMP, LibreOffice langs | None |

## Project Structure

```
.
├── airootfs/              # Root filesystem for the ISO
│   ├── etc/               # System configuration
│   │   ├── skel/          # User skeleton files (.config for Sway)
│   │   └── systemd/       # Systemd units
│   └── usr/local/bin/     # Custom scripts
│       └── mados-*        # madOS utilities
├── efiboot/               # UEFI boot configuration (systemd-boot)
├── syslinux/              # BIOS boot configuration
├── packages.x86_64         # Main package list
└── profiledef.sh           # ISO profile definition
```

## Boot Options

- **Normal**: Standard boot with Sway
- **Software Rendering**: Forced llvmpipe/pixman
- **Safe Compat**: nomodeset for problematic hardware

## Documentation

- [Persistence](docs/PERSISTENCE.md) - USB persistence setup
- [Debugging](docs/DEBUGGING.md) - Troubleshooting guide
