#!/usr/bin/env bash

# --- Special Cleanup for Network/Bluetooth ---
# The network toggle starts a background bluetooth scan that must be killed explicitly.
BT_PID_FILE="$HOME/.cache/bt_scan_pid"

if [ -f "$BT_PID_FILE" ]; then
    kill $(cat "$BT_PID_FILE") 2>/dev/null
    rm -f "$BT_PID_FILE"
fi

# Ensure bluetooth scan is explicitly turned off
bluetoothctl scan off > /dev/null 2>&1
# ---------------------------------------------

# Configuration: How many workspaces do you want to show?
SEQ_END=4

print_workspaces() {
    # Get raw data
    spaces=$(hyprctl workspaces -j)
    active=$(hyprctl activeworkspace -j | jq '.id')

    # Generate the JSON
    # ADDED: --unbuffered so the file updates instantly for TopBar.qml
    echo "$spaces" | jq --unbuffered --argjson a "$active" --arg end "$SEQ_END" -c '
        # Create a map of workspace ID -> workspace data for easy lookup
        (map( { (.id|tostring): . } ) | add) as $s
        |
        # Iterate from 1 to SEQ_END
        [range(1; ($end|tonumber) + 1)] | map(
            . as $i |
            # Determine state: active -> occupied -> empty
            (if $i == $a then "active"
             elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied"
             else "empty" end) as $state |

            # Get window title for tooltip (if exists)
            (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Empty" end) as $win |

            {
                id: $i,
                state: $state,
                tooltip: $win
            }
        )
    '
}

# Print initial state
print_workspaces

# Ensure the cache file exists immediately for TopBar reader
mkdir -p /tmp
print_workspaces > /tmp/qs_workspaces.json

# Listen to Hyprland socket
# ADDED: focusedmon, activewindow, and destroyworkspace to perfectly sync all UI shifts
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
    case "$line" in
        workspace*|focusedmon*|activewindow*|createwindow*|closewindow*|movewindow*|destroyworkspace*)
            print_workspaces
            ;;
    esac
done
