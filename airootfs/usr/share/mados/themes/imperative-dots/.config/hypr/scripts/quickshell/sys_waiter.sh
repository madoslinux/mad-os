#!/usr/bin/env bash

# Kill any child listening jobs on exit so we don't spawn infinite zombies
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# Wrap each listener in a subshell that sleeps infinitely if the command fails.
# This prevents `wait -n` from triggering instantly on a missing dependency, 
# which causes Quickshell to rapid-loop and freeze updates.

( pactl subscribe 2>/dev/null | grep --line-buffered -E "Event 'change' on sink" | head -n 1 || sleep infinity ) &
( nmcli monitor 2>/dev/null | grep --line-buffered -E "connected|disconnected|unavailable|enabled|disabled" | head -n 1 || sleep infinity ) &
( dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.bluez.Device1'" 2>/dev/null | grep --line-buffered "interface" | head -n 1 || sleep infinity ) &
( udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep --line-buffered "change" | head -n 1 || sleep infinity ) &
( socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - 2>/dev/null | grep --line-buffered "activelayout" | head -n 1 || sleep infinity ) &

# MPRIS / Playerctl changes via DBus (Session Bus)
( dbus-monitor --session "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/mpris/MediaPlayer2'" 2>/dev/null | grep --line-buffered "interface" | head -n 1 || sleep infinity ) &

# Failsafe: Force a silent UI refresh every 60 seconds just in case an event is missed
sleep 60 &

# Wait for the *first* background job to successfully complete an event
wait -n
