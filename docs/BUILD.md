# Building the ISO

## Requirements

- Arch Linux or Arch-based system
- `archiso` package
- ~10GB free disk space
- Root access

## Local Build

```bash
# Install archiso
sudo pacman -S archiso

# Build the ISO
sudo mkarchiso -v -w work/ -o out/ .

# Output location
ls -lh out/madOS-*.iso
```

Build time: ~10-20 minutes

## GitHub Actions

ISO builds automatically on push to `main`:

1. Push to main branch
2. Monitor build in GitHub Actions tab (~15 minutes)
3. Download ISO from Artifacts
