#!/bin/bash
# madOS Framebuffer Resolution Configuration
# Runs early to ensure optimal resolution before Plymouth splash
set -euo pipefail

LOG() {
    echo "[mados-fb-resolution] $*"
}

ERROR() {
    echo "[mados-fb-resolution] ERROR: $*" >&2
}

wait_for_drm() {
    local timeout=30
    local counter=0
    
    LOG "Waiting for DRM device..."
    
    while [ ! -e /dev/dri/card0 ] && [ $counter -lt $timeout ]; do
        sleep 0.5
        counter=$((counter + 1))
    done
    
    if [ $counter -ge $timeout ]; then
        ERROR "Timeout waiting for DRM device"
        return 1
    fi
    
    LOG "DRM available after $((counter * 500))ms"
    return 0
}

detect_gpu_driver() {
    local driver=""
    
    for card in /sys/class/drm/card*/device/driver; do
        if [ -d "$card" ]; then
            driver=$(basename "$(readlink "$card")")
            break
        fi
    done
    
    echo "$driver"
}

get_connected_display() {
    local display=""
    
    for conn in /sys/class/drm/card*-*; do
        if [ -d "$conn" ]; then
            local status=$(cat "$conn/status" 2>/dev/null || echo "unknown")
            if [ "$status" = "connected" ]; then
                display=$(basename "$conn")
                break
            fi
        fi
    done
    
    echo "$display"
}

get_native_resolution() {
    local display="$1"
    local edid_file="/sys/class/drm/$display/edid"
    
    if [ -s "$edid_file" ]; then
        parse_edid_resolution "$edid_file"
    fi
}

parse_edid_resolution() {
    local edid="$1"
    local width=0
    local height=0
    
    if command -v edid-decode &>/dev/null; then
        local modeline
        modeline=$(edid-decode "$edid" 2>/dev/null | grep "Preferred mode" | head -1 || true)
        if [ -n "$modeline" ]; then
            width=$(echo "$modeline" | grep -oP '\d+(?=x)' | head -1 || true)
            height=$(echo "$modeline" | grep -oP '(?<=x)\d+' | head -1 || true)
        fi
    fi
    
    if [ "$width" -gt 0 ] && [ "$height" -gt 0 ]; then
        echo "${width}x${height}"
    fi
}

configure_framebuffer() {
    local resolution="${1:-}"
    
    if [ -z "$resolution" ]; then
        LOG "No resolution specified, skipping fbset"
        return 0
    fi
    
    if ! command -v fbset &>/dev/null; then
        LOG "fbset not available, skipping"
        return 0
    fi
    
    local fb_device=""
    for fb in /dev/fb*; do
        if [ -e "$fb" ]; then
            fb_device="$fb"
            break
        fi
    done
    
    if [ -z "$fb_device" ]; then
        LOG "No framebuffer device found"
        return 0
    fi
    
    LOG "Configuring $fb_device to $resolution"
    
    if fbset -fb "$fb_device" "$resolution" -depth 32 &>/dev/null; then
        LOG "Framebuffer configured successfully"
    else
        LOG "fbset failed - keeping current framebuffer mode"
        return 0
    fi
}

main() {
    LOG "Starting framebuffer resolution configuration..."
    
    wait_for_drm || exit 0
    
    local driver=$(detect_gpu_driver)
    LOG "GPU driver: ${driver:-unknown}"
    
    local display=$(get_connected_display)
    if [ -n "$display" ]; then
        LOG "Connected display: $display"
        
        local resolution=$(get_native_resolution "$display")
        if [ -n "$resolution" ]; then
            LOG "Native resolution: $resolution"
            configure_framebuffer "$resolution"
        fi
    else
        LOG "No connected display detected"
    fi
    
    LOG "Framebuffer configuration complete"
}

main "$@"
