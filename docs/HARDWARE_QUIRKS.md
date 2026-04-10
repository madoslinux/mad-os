# madOS Hardware Quirks

This document describes the hardware-conditional quirk framework and active quirk rules.

## Framework

- Runner: `airootfs/usr/local/bin/mados-hw-quirks.sh`
- Rules directory: `airootfs/usr/local/lib/mados-hw-quirks.d/`
- Helper library: `airootfs/usr/local/lib/mados-hw-quirks-lib.sh`
- Service: `airootfs/etc/systemd/system/mados-hw-quirks.service`

The service runs early in boot, before NetworkManager, and executes all quirk rules.

## Disable Switches

- Global disable: `mados.disable_quirks=1`
- Group disable: `mados.disable_quirks=wifi,gpu,audio,storage,usb,acpi,suspend`

Examples:

- Disable all quirks:
  - `... mados.disable_quirks=1`
- Disable only Wi-Fi and GPU quirks:
  - `... mados.disable_quirks=wifi,gpu`

## Active Quirks

- `10-rtl8723de-rtw88.sh`
  - Detects Realtek RTL8723DE (`10ec:d723`)
  - Reloads `rtw88` modules with conservative power settings

- `20-intel-wifi-power-save-off.sh`
  - Detects Intel network controllers (`8086:*`)
  - Reloads `iwlwifi` with `power_save=0`

- `21-realtek-rtl8821ce.sh`
  - Detects Realtek RTL8821CE (`10ec:c821`)
  - Reloads `rtl8821ce` with power-save and ASPM disabled

- `30-intel-i915-legacy-stability.sh`
  - Detects Intel VGA hardware
  - Reloads `i915` with `enable_psr=0 enable_fbc=0`

- `31-amdgpu-stability.sh`
  - Detects AMD VGA hardware
  - Reloads `amdgpu` with `aspm=0`

- `40-nvme-conservative-power.sh`
  - Detects NVMe controllers (`class 0108`)
  - Reloads `nvme_core` with `default_ps_max_latency_us=0`

- `50-audio-hda-fallback.sh`
  - Detects missing active sound cards on systems with audio controllers
  - Reloads `snd_hda_intel` with conservative fallback options

- `51-audio-sof-to-hda-fallback.sh`
  - Detects Intel audio with no active card
  - Prefers legacy HDA (`snd_intel_dspcfg dsp_driver=1`)

- `60-usb-wifi-autosuspend-off.sh`
  - Detects known unstable USB Wi-Fi adapters
  - Disables USB autosuspend (`usbcore autosuspend=-1`)

- `70-acpi-backlight-dmi.sh`
  - DMI match for selected ASUS/Lenovo families
  - Loads `video` module when backlight nodes are missing

- `80-suspend-prefer-s2idle-dmi.sh`
  - DMI match for selected laptop families
  - Prefers `s2idle` over `deep` when both are available

- `81-suspend-resume-network-reset.sh`
  - DMI + network-controller match
  - Enables resume marker for network recovery path

- `mados-resume-network-reset` (system-sleep hook)
  - On resume (`post`), restarts NetworkManager and unblocks rfkill when marker exists

## Boot Profiles

- Normal boot entry (default)
- Software Rendering entry
- Safe Compat entry (third option)

Safe Compat uses conservative kernel options for difficult hardware.

## Adding a New Quirk Rule

Use this checklist to keep behavior predictable:

1. Create a new executable rule in `airootfs/usr/local/lib/mados-hw-quirks.d/` with numeric prefix ordering (for example `90-foo-bar.sh`).
2. Use strict mode and source the helper library:
   - `set -euo pipefail`
   - `source /usr/local/lib/mados-hw-quirks-lib.sh` (when present)
3. Gate the quirk by hardware evidence first (PCI/USB/DMI/sysfs checks), then apply the smallest effective change.
4. Respect group disable switches using `hwq_is_group_disabled`.
5. Fail safe: non-matching systems must exit without side effects.
6. Add file permissions in `profiledef.sh` and tests in `tests/test_wifi_quirks.py`.

Preferred matching strategy:

- Exact IDs (`lspci -nn`, `lsusb`) over vendor-only matches.
- DMI checks should require both vendor/product context for laptop families.
- Avoid broad module parameter changes unless there is a known regression pattern.
