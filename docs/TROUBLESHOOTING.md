# Troubleshooting

## Installation

| Issue | Solution |
|-------|----------|
| No disks detected | Check connections, run `lsblk` |
| Pacstrap fails | Verify internet connection |
| GRUB install error | Check UEFI/BIOS boot mode |

## Boot

| Issue | Solution |
|-------|----------|
| Won't boot | Verify BIOS boot order |
| Kernel panic | Boot with `systemd.unit=rescue.target` |
| No display | Try different TTY (Ctrl+Alt+F2-F6), check GPU drivers |
| Black screen with NVIDIA | Nouveau may need `nomodeset` kernel parameter |
| AMD screen flicker | Update kernel or try `amdgpu.dc=0` parameter |

## Performance

| Issue | Solution |
|-------|----------|
| High RAM usage | Check `htop`, disable unused services |
| Slow compositor | Consider i3 or dwm instead of Sway |
| ZRAM issues | `systemctl status systemd-zram-setup@zram0` |
| Graphical glitches | Force software rendering: `WLR_RENDERER=pixman sway` |
| Sway crashes on start | Check if legacy hardware detected: `/usr/local/bin/detect-legacy-hardware` |
| Poor performance on old GPU | Software rendering is auto-enabled, verify with `echo $WLR_RENDERER` |

## Performance Monitoring

```bash
# Monitor RAM usage
htop
free -h

# Check ZRAM status
zramctl

# View system services
systemctl list-units --type=service

# Remove orphaned packages
sudo pacman -Rns $(pacman -Qtdq)
```
