#!/usr/bin/env bash

# Directory to save screenshots
SAVE_DIR="$HOME/Images/Screenshots"
mkdir -p "$SAVE_DIR"

# Define timestamp for filenames
time=$(date +'%Y-%m-%d-%H%M%S')
FILENAME="$SAVE_DIR/Screenshot_$time.png"

# Slurp Styling (Transparent)
SLURP_ARGS="-b 1B1F2844 -c E06B74ff -s C778DD0D -w 2"

# Notification Function
send_notification() {
    # -s checks if file exists AND size is greater than 0
    if [ -s "$FILENAME" ]; then
        notify-send -a "Screenshot" \
                    -i "$FILENAME" \
                    "Screenshot Saved" \
                    "File: Screenshot_$time.png\nFolder: $SAVE_DIR"
    fi
}

# Parse arguments
EDIT_MODE=false
for arg in "$@"; do
    case $arg in
        --edit) EDIT_MODE=true ;;
    esac
done

# 1. Select Region first. If user presses Esc, this variable will be empty.
GEOMETRY=$(slurp $SLURP_ARGS)

# 2. Check if selection was cancelled
if [ -z "$GEOMETRY" ]; then
    exit 0
fi

if [ "$EDIT_MODE" = true ]; then
    # Edit Mode: Capture region -> Open in Satty
    grim -g "$GEOMETRY" - | GSK_RENDERER=gl satty --filename - --output-filename "$FILENAME" --init-tool brush --copy-command wl-copy
    
    send_notification
else
    # Standard Mode: Capture region -> Save to file -> Copy to clipboard
    grim -g "$GEOMETRY" - | tee "$FILENAME" | wl-copy
    
    send_notification
fi
