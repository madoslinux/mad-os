# Third-Party Licenses

This document summarizes the license status of third-party software included or installed by default in madOS builds.

## madOS License

- madOS project code (this repository): `AGPL-3.0-only`
- File: `LICENSE`

The madOS repository license applies to madOS code and assets, not automatically to all third-party packages shipped in the ISO.

## Third-Party Components (Not Exhaustive)

### Components that are not fully free or are commonly treated as non-free

- `intel-ucode` (CPU microcode)
- `amd-ucode` (CPU microcode)
- `linux-firmware` (firmware blobs)
- `alsa-firmware` (firmware blobs)
- `sof-firmware` (firmware blobs)
- `steam` (proprietary client/software distribution platform)

These components are included for hardware compatibility and user experience, but they may not satisfy strict "100% free software" criteria.

### Components with license/distribution status that should be reviewed periodically

- `opencode`
- `ollama`
- Tools installed by `airootfs/root/customize_airootfs.d/09-ai-tools.sh`:
  - `openclaw` (npm)
  - `forge` / `forgecode` (remote install script)
  - `qwen` (remote install script)

Because these tools can change distribution method, packaging, or terms over time, verify upstream license and redistribution terms before release.

## Upstream Sources in Build Scripts

madOS build scripts clone/install third-party projects from upstream repositories (for example, GitHub). Their licenses are defined by each upstream project and may differ from `AGPL-3.0-only`.

Examples include:

- madOS native app repos installed by `airootfs/root/customize_airootfs.d/03-apps.sh`
- Qylock theme assets installed by `airootfs/root/customize_airootfs.d/04-sddm-qylock.sh`
- Theme assets installed from `theme-imperative-dots`

## Policy Notes

- Keeping madOS under `AGPL-3.0-only` is compatible with distributing third-party software under different licenses.
- For strict free-software distributions, create a separate package profile that removes non-free firmware, microcode, and proprietary apps.

## Maintainer Checklist Before Release

- Review `packages.x86_64` for proprietary/non-free packages.
- Review `airootfs/root/customize_airootfs.d/09-ai-tools.sh` for external installers.
- Confirm upstream licenses for dynamically cloned/installed projects.
- Update this file if package selections change.
