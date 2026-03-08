# madOS

**madOS** is a Linux distribution based on Arch Linux, designed to be modern, minimalist, and highly customizable. It uses the Sway tiling window manager with Wayland by default and follows best practices for security and performance.

## 📋 Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

- **Arch Linux Base**: Access to AUR repository and rolling release updates
- **Sway + Wayland**: Modern tiling window manager with full Wayland support
- **Nord Theme**: Pleasant and consistent color scheme
- **Custom Installer**: Graphical and terminal installation tool
- **Package Profiles**: Multiple configurations (minimal, standard, developer, media)
- **Security**: Hardened configurations by default
- **AI-Powered**: Built-in OpenCode AI assistant for development assistance

## 💻 System Requirements

### Minimum
- **Processor**: x86_64 compatible (Intel/AMD)
- **RAM**: 4 GB
- **Storage**: 20 GB
- **Resolution**: 1024x768

### Recommended
- **Processor**: Dual-core 2.0 GHz or higher
- **RAM**: 8 GB or more
- **Storage**: 50 GB SSD
- **Resolution**: 1920x1080 or higher

## 📥 Installation

### From ISO

1. Download the latest ISO from [Releases](https://github.com/madkoding/mad-os/releases)
2. Burn the ISO to a bootable USB:
   ```bash
   sudo dd if=mados.iso of=/dev/sdX bs=4M status=progress
   ```
3. Boot from USB
4. Follow the installation wizard

### Build Your Own ISO

```bash
# Clone the repository
git clone https://github.com/madkoding/mad-os.git
cd mad-os

# Install archiso (Arch Linux)
sudo pacman -S archiso

# Build the ISO
./build-iso.sh

# The ISO will be in out/ directory
```

## 🏗️ Project Structure

```
mad-os/
├── airootfs/              # Root filesystem for the ISO
│   ├── etc/              # Configuration files
│   ├── home/             # Default user home directory
│   ├── root/             # Root user directory
│   ├── usr/              # User programs and data
│   │   ├── local/bin/    # Custom scripts
│   │   └── local/lib/    # Python modules
│   │       ├── mados_installer/      # Installer GUI
│   │       ├── mados_post_install/   # Post-installation setup
│   │       └── mados_apps/           # madOS applications
│   └── share/            # Shared data
├── packages.x86_64        # Package list for ISO
├── packages-*.x86_64      # Profile-specific package lists
├── profiledef.sh         # ISO builder configuration
├── build-iso.sh          # Build script
├── tests/                # Automated tests
└── README.md             # This file
```

## 🛠️ Development

### Prerequisites

- Arch Linux (or Arch-based distro)
- `archiso` package
- `git`
- `python3`

### Setup Development Environment

```bash
# Clone repository
git clone https://github.com/madkoding/mad-os.git
cd mad-os

# Install dependencies
sudo pacman -S archiso python-pytest shellcheck-py

# Run tests
python3 -m pytest tests/ -v

# Build ISO
./build-iso.sh
```

### Running Tests

```bash
# All tests
python3 -m pytest tests/ -v

# Specific test suite
python3 -m pytest tests/test_installer_installation.py -v

# With coverage
python3 -m pytest tests/ --cov=airootfs/usr/local/lib
```

## 📦 Package Profiles

madOS includes multiple package profiles for different use cases:

- **Minimal**: Base system only (~1.5 GB)
- **Standard**: Desktop environment + essential apps (~3 GB)
- **Developer**: Development tools, IDEs, compilers (~5 GB)
- **Media**: Multimedia production tools (~6 GB)

You can mix and match profiles during installation.

## 🎯 Post-Installation

After installing madOS, the post-installer will automatically run on first boot to:

- Install selected additional packages
- Configure user preferences
- Set up system services
- Apply customizations

## 🔧 Custom Scripts

madOS includes several custom scripts in `/usr/local/bin/`:

- `mados-update` - System update with madOS-specific optimizations
- `mados-health-check` - System health diagnostics
- `mados-logs` - Log viewer
- `mados-wallpaper-glitch` - Dynamic wallpaper effects
- `mados-audio-quality` - High-quality audio configuration
- `mados-installer-autostart` - Auto-start installer in live session

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks

Example: `feat(installer): add dark mode to package selection`

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Releases**: https://github.com/madkoding/mad-os/releases
- **Issues**: https://github.com/madkoding/mad-os/issues
- **Discussions**: https://github.com/madkoding/mad-os/discussions

## 🙏 Acknowledgments

- Arch Linux community for excellent documentation
- SwayWM developers for amazing tiling window manager
- Nord theme creators for beautiful color scheme
- All open-source contributors

---

**Built with ❤️ using Arch Linux and AI assistance**
