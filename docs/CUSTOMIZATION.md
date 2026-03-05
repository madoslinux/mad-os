# Customization

## Add/Remove Packages

Edit `packages.x86_64` (one package per line):

```bash
# Add package
echo "firefox" >> packages.x86_64

# Remove package
sed -i '/chromium/d' packages.x86_64
```

## Desktop Configuration

Default user configurations:

| Component | Location |
|-----------|----------|
| Sway | `airootfs/etc/skel/.config/sway/config` |
| Waybar | `airootfs/etc/skel/.config/waybar/` |
| Terminal | `airootfs/etc/skel/.config/foot/foot.ini` |

## Modify Installer

Edit `airootfs/usr/local/bin/install-mados.sh` to customize:
- Partition layout and sizes
- Default packages
- Installation flow

## Key Bindings

| Shortcut | Action |
|----------|--------|
| `Super+Enter` | Open terminal |
| `Super+D` | Application launcher |
| `Super+Shift+Q` | Close window |
| `Super+1-9` | Switch workspace |
| `Super+Shift+E` | Exit Sway |

## System Architecture

```
madOS Architecture
├── Hardware (1.9GB RAM, Intel/AMD/NVIDIA GPU)
├── Kernel (Linux latest + ZRAM + sysctl tuning)
├── Services (systemd, EarlyOOM, iwd, PipeWire)
├── Display (Wayland via Sway)
├── Desktop (Sway, Waybar, Wofi, Nord theme)
├── Applications (Chromium, VS Code, dev tools)
└── AI Layer (OpenCode system orchestration)
```
