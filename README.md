<div align="center">

![madOS Logo](docs/mados-logo.png)

# madOS

**AI-Orchestrated Arch Linux System**

[![Build Status](https://img.shields.io/github/actions/workflow/status/madkoding/mad-os/ci-cd.yml?branch=main&style=flat-square)](https://github.com/madkoding/mad-os/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Arch Linux](https://img.shields.io/badge/Arch-Linux-blue?style=flat-square)](https://archlinux.org)

[![Version](https://img.shields.io/github/v/release/madkoding/mad-os?logo=github)](https://github.com/madkoding/mad-os/releases) 
[![Beta](https://img.shields.io/badge/Beta-develop-purple)](https://madkoding.github.io/mad-os/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://www.python.org)
</div>

madOS is a custom Arch Linux distribution optimized for low-RAM systems (1.9GB), featuring integrated OpenCode AI assistance for intelligent system management and orchestration.

## Download

- **Stable:** [madOS Website](https://madkoding.github.io/mad-os/) (recommended)
- **Beta:** [Beta Downloads](https://madkoding.github.io/mad-os/) (latest development build)

## Quick Start

### Installation

1. **Create bootable USB:**
   ```bash
   sudo dd if=madOS-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

2. **Boot from USB** - Sway will auto-start in the live environment

3. **Run the installer:**
   ```bash
   sudo install-mados
   ```

4. **Follow the installer** (~10 minutes)

5. **Reboot** into your new madOS system

## Features

- **OpenCode Integration** - AI-powered system orchestration
- **Low-RAM Optimized** - Designed for 1.9GB+ RAM systems
- **Lightweight Desktop** - Sway Wayland compositor (~67MB RAM)
- **Developer Ready** - Node.js, npm, Git, VS Code pre-installed
- **Performance Tuned** - ZRAM compression, EarlyOOM, kernel optimizations
- **Steam Deck Ready** - Optimized for handheld gaming
- **Xbox Controller Ready** - Plug & play support

See [docs/FEATURES.md](docs/FEATURES.md) for detailed features.

## Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | Intel Atom | Any x86_64 |
| RAM | 1.9GB | 2GB+ |
| Storage | 25GB | 64GB+ |

See [docs/HARDWARE.md](docs/HARDWARE.md) for full specifications.

## Building the ISO

```bash
sudo pacman -S archiso
sudo mkarchiso -v -w work/ -o out/ .
```

See [docs/BUILD.md](docs/BUILD.md) for complete build instructions.

## Using OpenCode

```bash
# Start interactive session
opencode

# Send direct message
opencode --message "optimize system performance"
```

## Customization

- **Packages**: Edit `packages.x86_64`
- **Desktop**: Config files in `airootfs/etc/skel/.config/`
- **Installer**: Modify `airootfs/usr/local/bin/install-mados.sh`

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for detailed customization options.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No disks detected | Run `lsblk` |
| Boot problems | Check BIOS boot order |
| Graphics issues | Try `nomodeset` kernel parameter |

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for comprehensive troubleshooting guide.

## Resources

- **Website:** https://madkoding.github.io/mad-os/
- **Documentation:** [docs/](docs/)
- **Issues:** [GitHub Issues](https://github.com/madkoding/mad-os/issues)

## Contributing

Contributions are welcome - themes, packages, tuning, documentation, and bug fixes.

## License

- Custom configurations and scripts: **MIT License**
- Based on Arch Linux and archiso

## Credits

See [docs/CREDITS.md](docs/CREDITS.md) for full credits.

---

**Última actualización:** 2026-03-05
