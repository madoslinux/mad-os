#!/usr/bin/env bash

# Enable monitor mode so background jobs get placed in their own process groups.
# This allows us to cleanly kill the subshells AND all of their children (pactl, nmcli, grep).
set -m

cleanup() {
    # Send SIGTERM to all process groups associated with our background jobs, leaving no orphans.
    for pid in $(jobs -p); do
        kill -TERM -$pid 2>/dev/null
    done
}
trap cleanup EXIT

# Run listeners. We redirect ALL output to /dev/null so Quickshell doesn't
# hang trying to read an inherited file descriptor.
# Notice the removal of "|| sleep infinity". If a service is down, we WANT it to fail
# so the script can quickly restart and try connecting again.
( pactl subscribe 2>/dev/null | grep --line-buffered -E "Event 'change' on sink" | head -n 1 ) >/dev/null 2>&1 &
( nmcli monitor 2>/dev/null | grep --line-buffered -E "connected|disconnected|unavailable|enabled|disabled" | head -n 1 ) >/dev/null 2>&1 &
( dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.bluez.Device1'" 2>/dev/null | grep --line-buffered "interface" | head -n 1 ) >/dev/null 2>&1 &
( udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep --line-buffered "change" | head -n 1 ) >/dev/null 2>&1 &
( socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - 2>/dev/null | grep --line-buffered "activelayout" | head -n 1 ) >/dev/null 2>&1 &
( playerctl metadata --follow --format '{{status}} {{title}}' 2>/dev/null | grep -m 2 "" | tail -n 1 | grep -q . ) >/dev/null 2>&1 &

# Failsafe: Force a silent UI refresh every 60 seconds
sleep 60 >/dev/null 2>&1 &

# Wait for the *first* background job to successfully complete an event
# (or exit instantly if a service is completely down at boot).
wait -n 2>/dev/null

# Delay slightly to prevent 100% CPU usage looping if a service is completely down
# and crashing its monitor instantly.
sleep 1
