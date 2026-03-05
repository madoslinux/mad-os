# Desktop Environment

- **Sway** - i3-compatible Wayland compositor with Nord theme
- **Waybar** - Customizable status bar
- **Wofi** - Application launcher
- **Foot** - Fast terminal emulator
- **Mako** - Notification daemon

## Applications

- **Chromium** - Web browser
- **VS Code** - Code editor
- **PCManFM** - File manager
- **LXAppearance** - Theme configuration

## madOS Native Apps

- **madOS Equalizer** (`mados-equalizer`) - 8-band audio equalizer with PipeWire/PulseAudio
- **madOS PDF Viewer** (`mados-pdf-viewer`) - PDF viewer with annotations and digital signatures
- **madOS Photo Viewer** (`mados-photo-viewer`) - Photo viewer/editor with video playback
- **madOS WiFi** - Native tray applet via `nm-applet` (NetworkManager)
- **madOS Bluetooth** - Native tray applet via `blueman-applet`

## Audio Quality

- **Auto-Detection** - Automatically detects and applies maximum audio quality (up to 192kHz/32-bit)
- **High-Quality Resampling** - PipeWire configured with quality level 10 (maximum)
- **Hardware Optimization** - Optimal buffer sizes and sample rates for your audio hardware
- See [Audio Quality Documentation](AUDIO_QUALITY.md) for details

## Developer Tools

- **OpenCode** - AI assistant (`opencode` command)
- **Node.js 24.x** & npm
- **Git** - Version control
- **fastfetch** - System information tool
- **htop** - System monitor
- **Vim & Nano** - Text editors

### fastfetch example output

```
   /\      mados@mados
  /  \     -----------
 /\   \    OS → madOS (Arch Linux)
/  ..  \   Host → Intel NUC / Custom PC
/  '  '\  Kernel → 6.12.8-arch1-1
/ ..'   \  Uptime → 2 hours, 15 mins
/..'  ..'\ Packages → 324 (pacman)
 `..'..'`  Shell → zsh 5.9
            WM → sway
            Terminal → foot
            CPU → Intel Atom x5-Z8350 (4) @ 1.92GHz
            GPU → Intel HD Graphics 400
            Memory → 487MiB / 1872MiB
            Swap → 128MiB / 936MiB
            Disk (/) → 8.2GiB / 32.0GiB (26%)
            Local IP (wlan0) → 192.168.1.42/24

            🟦🟦🟦🟦🟦🟦🟦🟦
```

> **Note**: fastfetch reads `/etc/os-release` to display **madOS (Arch Linux)** as the distro name. The output above is an example — actual values depend on your hardware.

## System Optimizations

- **ZRAM** - Compressed swap using 50% RAM with zstd
- **EarlyOOM** - Out-of-memory killer to prevent freezes
- **Kernel tuning** - `vm.swappiness=5`, `vm.vfs_cache_pressure=200`
- **Network stack** - Optimized TCP buffers for low memory

## GPU Drivers (Open Source)

- **Intel** - intel-media-driver, vulkan-intel, libva-intel-driver
- **AMD** - xf86-video-amdgpu, vulkan-radeon
- **NVIDIA** - xf86-video-nouveau (open source driver)
- **Mesa** - OpenGL/Vulkan implementation for all GPUs

## Adaptive Rendering

madOS automatically detects hardware capabilities and optimizes rendering:

- **Modern hardware** - Hardware-accelerated OpenGL/Vulkan rendering
- **Legacy hardware** - Software rendering (pixman) for:
  - Old CPUs (Intel Atom, Celeron N, Pentium N, pre-Sandy Bridge)
  - Legacy Intel GPUs (Gen 1-6, GMA series, Atom integrated graphics)
  - Systems with <2GB RAM
  - Virtual machines
  - Safe graphics mode (`nomodeset` kernel parameter)

The system automatically switches to software rendering when legacy hardware is detected, ensuring compatibility and stability on older systems while maximizing performance on modern hardware.
