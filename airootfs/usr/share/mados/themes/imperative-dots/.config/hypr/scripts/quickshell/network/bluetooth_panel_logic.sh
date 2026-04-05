#!/usr/bin/env bash

SCAN_LOG="$HOME/.cache/bt_scan.log"
PID_FILE="$HOME/.cache/bt_scan_pid"
CACHE_DIR="/tmp/quickshell_network_cache"
mkdir -p "$CACHE_DIR"

get_icon() {
    local type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local name=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    if [[ "$type" == *"headset"* ]] || [[ "$type" == *"headphone"* ]] || [[ "$name" == *"headphone"* ]] || [[ "$name" == *"buds"* ]] || [[ "$name" == *"pods"* ]]; then echo "🎧"
    elif [[ "$type" == *"audio"* ]] || [[ "$type" == *"speaker"* ]] || [[ "$type" == *"card"* ]] || [[ "$name" == *"speaker"* ]]; then echo "蓼"
    elif [[ "$type" == *"phone"* ]] || [[ "$name" == *"phone"* ]] || [[ "$name" == *"iphone"* ]] || [[ "$name" == *"android"* ]]; then echo ""
    elif [[ "$type" == *"mouse"* ]] || [[ "$name" == *"mouse"* ]]; then echo ""
    elif [[ "$type" == *"keyboard"* ]] || [[ "$name" == *"keyboard"* ]]; then echo ""
    elif [[ "$type" == *"controller"* ]] || [[ "$name" == *"controller"* ]]; then echo ""
    else echo ""
    fi
}

get_audio_profile() {
    local mac="$1"
    local mac_us=$(echo "$mac" | tr ':' '_')
    
    # Grab the block of text containing the specific device's card and extract its Active Profile
    local active=$(pactl list cards 2>/dev/null | grep -i -A 20 "Name:.*$mac_us" | grep -i "Active Profile:" | head -n 1 | cut -d: -f2 | xargs)
    
    if [[ -z "$active" || "$active" == "off" ]]; then echo "None"; return; fi
    
    local desc="Connected"
    if [[ "$active" == *"a2dp"* ]]; then desc="Hi-Fi (A2DP)"; fi
    if [[ "$active" == *"headset"* || "$active" == *"hfp"* ]]; then desc="Headset (HFP)"; fi
    
    echo "$desc"
}

get_status() {
    power="off"
    if bluetoothctl show | grep -q "Powered: yes"; then power="on"; fi

    connected_json="[]"
    devices_json="[]"

    if [ "$power" == "on" ]; then
        paired_macs=$(bluetoothctl devices Paired | cut -d ' ' -f 2)
        mapfile -t devices < <(bluetoothctl devices)

        connected_list_objs=()
        paired_list_objs=()
        discovered_list_objs=()

        # Get all connected devices
        mapfile -t connected_info_lines < <(bluetoothctl devices Connected)
        
        # Extract just the MACs of connected devices for filtering the main list later
        connected_macs=$(echo "${connected_info_lines[@]}" | awk '{for(i=1;i<=NF;i++) if($i~/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/) print $i}')

        for c_line in "${connected_info_lines[@]}"; do
            if [ -z "$c_line" ]; then continue; fi
            connected_mac=$(echo "$c_line" | cut -d ' ' -f 2)
            CACHE_FILE="$CACHE_DIR/bt_stat_${connected_mac//:/_}"

            # Profile, Name, and Icon do not change dynamically. Calculate ONCE.
            if [ -f "$CACHE_FILE" ]; then
                source "$CACHE_FILE"
            else
                name=$(echo "$c_line" | cut -d ' ' -f 3-)
                info=$(bluetoothctl info "$connected_mac")
                icon_type=$(echo "$info" | grep "Icon:" | cut -d: -f2 | xargs)
                icon=$(get_icon "$icon_type" "$name")
                profile=$(get_audio_profile "$connected_mac")
                
                echo "CACHE_NAME=\"$name\"" > "$CACHE_FILE"
                echo "CACHE_ICON=\"$icon\"" >> "$CACHE_FILE"
                echo "CACHE_PROFILE=\"$profile\"" >> "$CACHE_FILE"
                
                CACHE_NAME="$name"
                CACHE_ICON="$icon"
                CACHE_PROFILE="$profile"
            fi
            
            # Dynamically fetch ONLY the battery since it changes
            # Strictly extract whatever is inside the parenthesis (e.g. 100 from "0x64 (100)")
            bat=$(bluetoothctl info "$connected_mac" | awk '/Battery Percentage:/ {gsub(/.*\(/,""); gsub(/\).*/,""); print}')
            [ -z "$bat" ] && bat=$(bluetoothctl info "$connected_mac" | grep -i "Battery Percentage" | awk '{print $NF}' | tr -d '()')
            [ -z "$bat" ] || [ "$bat" == "?" ] && bat="0"

            obj=$(jq -n -c \
                --arg id "$connected_mac" \
                --arg name "$CACHE_NAME" \
                --arg mac "$connected_mac" \
                --arg icon "$CACHE_ICON" \
                --arg bat "$bat" \
                --arg profile "$CACHE_PROFILE" \
                '{id: $id, name: $name, mac: $mac, icon: $icon, battery: $bat, profile: $profile}')
            connected_list_objs+=("$obj")
        done

        if [ ${#connected_list_objs[@]} -gt 0 ]; then
            connected_json=$(printf '%s\n' "${connected_list_objs[@]}" | jq -s -c '.')
        fi

        for line in "${devices[@]}"; do
            if [ -z "$line" ]; then continue; fi
            mac=$(echo "$line" | cut -d ' ' -f 2)
            
            # Skip if this MAC is already in the connected list
            if echo "$connected_macs" | grep -q "$mac"; then continue; fi

            name=$(echo "$line" | cut -d ' ' -f 3-)
            icon=$(get_icon "unknown" "$name")

            if echo "$paired_macs" | grep -q "$mac"; then
                action="Connect"
                obj=$(jq -n -c --arg id "$mac" --arg name "$name" --arg mac "$mac" --arg icon "$icon" --arg action "$action" '{id: $id, name: $name, mac: $mac, icon: $icon, action: $action}')
                paired_list_objs+=("$obj")
            else
                action="Pair"
                obj=$(jq -n -c --arg id "$mac" --arg name "$name" --arg mac "$mac" --arg icon "$icon" --arg action "$action" '{id: $id, name: $name, mac: $mac, icon: $icon, action: $action}')
                discovered_list_objs+=("$obj")
            fi
        done

        all_objs=("${paired_list_objs[@]}" "${discovered_list_objs[@]}")
        if [ ${#all_objs[@]} -gt 0 ]; then
            devices_json=$(printf '%s\n' "${all_objs[@]}" | jq -s -c '.')
        fi
        if [ -z "$devices_json" ]; then devices_json="[]"; fi
    fi

    jq -n -c \
        --arg power "$power" \
        --argjson connected "${connected_json}" \
        --argjson devices "${devices_json:-[]}" \
        '{power: $power, connected: $connected, devices: $devices}'
}

toggle_power() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power off
    else
        bluetoothctl power on
    fi
    sleep 0.5
}

connect_dev() {
    local mac="$1"
    if [ -f "$PID_FILE" ]; then kill -STOP $(cat "$PID_FILE") 2>/dev/null; fi
    bluetoothctl trust "$mac" > /dev/null 2>&1
    bluetoothctl connect "$mac"
    if [ -f "$PID_FILE" ]; then kill -CONT $(cat "$PID_FILE") 2>/dev/null; fi
}

disconnect_dev() {
    local mac="$1"
    # Remove cache so a fresh connect regenerates the profile
    rm -f "/tmp/quickshell_network_cache/bt_stat_${mac//:/_}" 2>/dev/null
    bluetoothctl disconnect "$mac"
}

cmd="$1"
case $cmd in
    --status) get_status ;;
    --toggle) toggle_power ;;
    --connect) connect_dev "$2" ;;
    --disconnect) disconnect_dev "$2" ;;
esac
