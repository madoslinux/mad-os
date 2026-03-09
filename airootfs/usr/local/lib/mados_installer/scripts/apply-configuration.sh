# Enable vmwgfx detector service (runs early at boot)
systemctl enable vmwgfx-detector.service 2>/dev/null || true

# Run detector immediately to configure vmwgfx for current hardware
if [ -x /usr/local/bin/vmwgfx-detector ]; then
    /usr/local/bin/vmwgfx-detector
fi