#!/bin/bash
# Wait for GPU modules to load. If no GPU is present, this is not an error.
for i in /sys/class/drm/card*/device/driver; do
    driver=$(basename "$(readlink "$i" 2>/dev/null)" 2>/dev/null)
    case "$driver" in
        i915|amdgpu|nouveau|virtio-gpu|vmwgfx) exit 0 ;;
    esac
done
# No GPU found - this is not an error, exit gracefully
exit 0
