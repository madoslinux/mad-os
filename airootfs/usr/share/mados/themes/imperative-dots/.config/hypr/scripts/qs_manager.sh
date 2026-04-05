#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CONSTANTS & ARGUMENTS
# -----------------------------------------------------------------------------
QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
BT_SCAN_LOG="$HOME/.cache/bt_scan.log"
SRC_DIR="$HOME/Images/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"

IPC_FILE="/tmp/qs_widget_state"
NETWORK_MODE_FILE="/tmp/qs_network_mode"
PREV_FOCUS_FILE="/tmp/qs_prev_focus"

ACTION="$1"
TARGET="$2"
SUBTARGET="$3"

# -----------------------------------------------------------------------------
# FAST PATH: WORKSPACE SWITCHING
# -----------------------------------------------------------------------------
if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    WORKSPACE_NUM="$ACTION"
    MOVE_OPT="$2"
    
    echo "close" > "$IPC_FILE"
    
    CMD="workspace $WORKSPACE_NUM"
    [[ "$MOVE_OPT" == "move" ]] && CMD="movetoworkspace $WORKSPACE_NUM"

    TARGET_ADDR=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $WORKSPACE_NUM and .class != \"qs-master\") | .address" | head -n 1)

    if [[ -n "$TARGET_ADDR" && "$TARGET_ADDR" != "null" ]]; then
        hyprctl --batch "dispatch $CMD ; keyword cursor:no_warps true ; dispatch focuswindow address:$TARGET_ADDR ; keyword cursor:no_warps false"
    else
        hyprctl --batch "dispatch $CMD ; keyword cursor:no_warps true ; dispatch focuswindow qs-master ; keyword cursor:no_warps false"
    fi

    exit 0
fi

# -----------------------------------------------------------------------------
# PREP FUNCTIONS
# -----------------------------------------------------------------------------
handle_wallpaper_prep() {
    mkdir -p "$THUMB_DIR"
    (
        for thumb in "$THUMB_DIR"/*; do
            [ -e "$thumb" ] || continue
            filename=$(basename "$thumb")
            clean_name="${filename#000_}"
            if [ ! -f "$SRC_DIR/$clean_name" ]; then
                rm -f "$thumb"
            fi
        done

        for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif,mp4,mkv,mov,webm}; do
            [ -e "$img" ] || continue
            filename=$(basename "$img")
            extension="${filename##*.}"

            if [[ "${extension,,}" == "webp" ]]; then
                new_img="${img%.*}.jpg"
                magick "$img" "$new_img"
                rm -f "$img"
                img="$new_img"
                filename=$(basename "$img")
                extension="jpg"
            fi

            if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                thumb="$THUMB_DIR/000_$filename"
                [ -f "$THUMB_DIR/$filename" ] && rm -f "$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                     ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 -f image2 -q:v 2 "$thumb" > /dev/null 2>&1
                fi
            else
                thumb="$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                    magick "$img" -resize x420 -quality 70 "$thumb"
                fi
            fi
        done
    ) &

    TARGET_THUMB=""
    CURRENT_SRC=""

    if pgrep -a "mpvpaper" > /dev/null; then
        CURRENT_SRC=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -z "$CURRENT_SRC" ] && command -v swww >/dev/null; then
        CURRENT_SRC=$(swww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -n "$CURRENT_SRC" ]; then
        EXT="${CURRENT_SRC##*.}"
        if [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
            TARGET_THUMB="000_$CURRENT_SRC"
        else
            TARGET_THUMB="$CURRENT_SRC"
        fi
    fi
    
    export WALLPAPER_THUMB="$TARGET_THUMB"
}

handle_network_prep() {
    echo "" > "$BT_SCAN_LOG"
    { echo "scan on"; sleep infinity; } | stdbuf -oL bluetoothctl > "$BT_SCAN_LOG" 2>&1 &
    echo $! > "$BT_PID_FILE"
    (nmcli device wifi rescan) &
}

# -----------------------------------------------------------------------------
# ENSURE MASTER WINDOW & TOP BAR ARE ALIVE (ZOMBIE WATCHDOG)
# -----------------------------------------------------------------------------
MAIN_QML_PATH="$HOME/.config/hypr/scripts/quickshell/Main.qml"
BAR_QML_PATH="$HOME/.config/hypr/scripts/quickshell/TopBar.qml"

QS_PID=$(pgrep -f "quickshell.*Main\.qml")
WIN_EXISTS=$(hyprctl clients -j | grep "qs-master")
BAR_PID=$(pgrep -f "quickshell.*TopBar\.qml")

if [[ -z "$QS_PID" ]] || [[ -z "$WIN_EXISTS" ]]; then
    if [[ -n "$QS_PID" ]]; then
        kill -9 $QS_PID 2>/dev/null
    fi
    
    # Bypass NixOS symlink resolution by using the direct ~/.config path
    quickshell -p "$MAIN_QML_PATH" >/dev/null 2>&1 &
    disown
    
    for _ in {1..20}; do
        if hyprctl clients -j | grep -q "qs-master"; then
            sleep 0.1
            break
        fi
        sleep 0.05
    done
fi

if [[ -z "$BAR_PID" ]]; then
    quickshell -p "$BAR_QML_PATH" >/dev/null 2>&1 &
    disown
fi

# -----------------------------------------------------------------------------
# FOCUS MANAGEMENT
# -----------------------------------------------------------------------------
save_and_focus_widget() {
    # Only save if the currently focused window is NOT the widget container
    local current_window=$(hyprctl activewindow -j 2>/dev/null)
    local current_title=$(echo "$current_window" | jq -r '.title // empty')
    local current_addr=$(echo "$current_window" | jq -r '.address // empty')

    if [[ "$current_title" != "qs-master" && -n "$current_addr" && "$current_addr" != "null" ]]; then
        echo "$current_addr" > "$PREV_FOCUS_FILE"
    fi

    # Dispatch focus without warping the cursor (run async with a tiny delay to allow QML to move the window first)
    (
        sleep 0.05
        hyprctl --batch "keyword cursor:no_warps true ; dispatch focuswindow title:^qs-master$ ; keyword cursor:no_warps false" >/dev/null 2>&1
    ) &
}

restore_focus() {
    if [[ -f "$PREV_FOCUS_FILE" ]]; then
        local prev_addr=$(cat "$PREV_FOCUS_FILE")
        if [[ -n "$prev_addr" && "$prev_addr" != "null" ]]; then
            # Restore focus to the previous window without warping the cursor
            hyprctl --batch "keyword cursor:no_warps true ; dispatch focuswindow address:$prev_addr ; keyword cursor:no_warps false" >/dev/null 2>&1
        fi
        rm -f "$PREV_FOCUS_FILE"
    fi
}

# -----------------------------------------------------------------------------
# REMAINING ACTIONS (OPEN / CLOSE / TOGGLE)
# -----------------------------------------------------------------------------
if [[ "$ACTION" == "close" ]]; then
    echo "close" > "$IPC_FILE"
    restore_focus
    if [[ "$TARGET" == "network" || "$TARGET" == "all" || -z "$TARGET" ]]; then
        if [ -f "$BT_PID_FILE" ]; then
            kill $(cat "$BT_PID_FILE") 2>/dev/null
            rm -f "$BT_PID_FILE"
        fi
        bluetoothctl scan off > /dev/null 2>&1
    fi
    exit 0
fi

if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    ACTIVE_WIDGET=$(cat /tmp/qs_active_widget 2>/dev/null)
    CURRENT_MODE=$(cat "$NETWORK_MODE_FILE" 2>/dev/null)

    # Dynamically fetch focused monitor geometry and adjust for Wayland layout scale
    ACTIVE_MON=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true)')
    MX=$(echo "$ACTIVE_MON" | jq -r '.x // 0')
    MY=$(echo "$ACTIVE_MON" | jq -r '.y // 0')
    MW=$(echo "$ACTIVE_MON" | jq -r '(.width / (.scale // 1)) | round // 1920')
    MH=$(echo "$ACTIVE_MON" | jq -r '(.height / (.scale // 1)) | round // 1080')

    MON_DATA="${MX}:${MY}:${MW}:${MH}"

    if [[ "$TARGET" == "network" ]]; then
        if [[ "$ACTION" == "toggle" && "$ACTIVE_WIDGET" == "network" ]]; then
            if [[ -n "$SUBTARGET" ]]; then
                if [[ "$CURRENT_MODE" == "$SUBTARGET" ]]; then
                    echo "close" > "$IPC_FILE"
                    restore_focus
                else
                    echo "$SUBTARGET" > "$NETWORK_MODE_FILE"
                    save_and_focus_widget
                fi
            else
                echo "close" > "$IPC_FILE"
                restore_focus
            fi
        else
            handle_network_prep
            if [[ -n "$SUBTARGET" ]]; then
                echo "$SUBTARGET" > "$NETWORK_MODE_FILE"
            fi
            echo "$TARGET::$MON_DATA" > "$IPC_FILE"
            save_and_focus_widget
        fi
        exit 0
    fi

    # Intercept toggle logic for all other widgets so we can restore focus properly
    if [[ "$ACTION" == "toggle" && "$ACTIVE_WIDGET" == "$TARGET" ]]; then
        echo "close" > "$IPC_FILE"
        restore_focus
        exit 0
    fi

    if [[ "$TARGET" == "wallpaper" ]]; then
        handle_wallpaper_prep
        echo "$TARGET:$WALLPAPER_THUMB:$MON_DATA" > "$IPC_FILE"
    else
        echo "$TARGET::$MON_DATA" > "$IPC_FILE"
    fi
    
    save_and_focus_widget
    exit 0
fi
