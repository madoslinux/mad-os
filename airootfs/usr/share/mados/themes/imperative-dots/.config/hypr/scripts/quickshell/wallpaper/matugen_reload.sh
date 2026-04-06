#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# 1. Flatten Matugen v4.0 Nested JSON for Quickshell
# ------------------------------------------------------------------------------
# Updated to match your config.toml output path
QS_JSON="/tmp/qs_colors.json"

python3 -c '
import json
import sys

def flatten_colors(obj):
    if isinstance(obj, dict):
        if "color" in obj and isinstance(obj["color"], str):
            return obj["color"]
        return {k: flatten_colors(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [flatten_colors(x) for x in obj]
    return obj

target_file = sys.argv[1]
try:
    with open(target_file, "r") as f:
        data = json.load(f)
    
    flat_data = flatten_colors(data)
    
    with open(target_file, "w") as f:
        json.dump(flat_data, f, indent=4)
        
except FileNotFoundError:
    pass
except Exception as e:
    print(f"Error flattening JSON: {e}")
' "$QS_JSON"

# ------------------------------------------------------------------------------
# 2. Flatten Matugen v4.0 Output in Standard Text Configs
# ------------------------------------------------------------------------------
# If Tera dumped {"color": "#hex"} into your text files, this strips it to #hex.
TEXT_FILES=(
    "$HOME/.config/hypr/matugen-colors.conf"
    "/tmp/kitty-matugen-colors.conf"
    "$HOME/.config/nvim/matugen_colors.lua"
    "$HOME/.config/cava/colors"
    "$HOME/.config/swayosd/style.css"
    "$HOME/.config/swaync/style.css"
    "$HOME/.config/rofi/theme.rasi"
    "$HOME/.config/wofi/style.css"
    "$HOME/.config/mako/config"
    "$HOME/.config/qt5ct/colors/matugen.conf"
    "$HOME/.config/qt6ct/colors/matugen.conf"
    "$HOME/.config/gtk-3.0/gtk.css"
    "$HOME/.config/gtk-4.0/gtk.css"
    "/usr/share/sddm/themes/matugen-minimal/Colors.qml"
)

for file in "${TEXT_FILES[@]}"; do
    # Check if file exists and we have write permissions (avoids sudo password hangs on SDDM)
    if [ -f "$file" ] && [ -w "$file" ]; then
        # Looks for {"color": "#abcdef"} and replaces it with #abcdef
        sed -i -E 's/\{[[:space:]]*"color":[[:space:]]*"([^"]+)"[[:space:]]*\}/\1/g' "$file"
    elif [ -f "$file" ]; then
        echo "Warning: No write permission for $file (Skipping text clean-up)"
    fi
done

# ------------------------------------------------------------------------------
# 3. Reload System Components
# ------------------------------------------------------------------------------

# Reload Kitty instances
killall -USR1 kitty

# Reload CAVA
if pgrep -x "cava" > /dev/null; then
    # Rebuild the final config file from the base and newly generated colors
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    # Tell CAVA to reload the config
    killall -USR1 cava
fi

# Reload SwayNC CSS styling dynamically without killing the daemon
if command -v swaync-client &> /dev/null; then
    swaync-client -rs
fi

if command -v makoctl >/dev/null 2>&1; then
    makoctl reload >/dev/null 2>&1 || true
fi

# Reload Hyprland to apply matugen-colors.conf
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# Keep GTK settings files aligned with runtime theme so apps start correctly
GTK3_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS="$HOME/.config/gtk-4.0/settings.ini"
DESIRED_GTK_THEME="$(grep -m1 '^gtk-theme-name=' "$GTK3_SETTINGS" 2>/dev/null | cut -d= -f2- || true)"
if [[ -z "$DESIRED_GTK_THEME" ]] && command -v gsettings >/dev/null 2>&1; then
    DESIRED_GTK_THEME="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || true)"
fi
[[ -z "$DESIRED_GTK_THEME" ]] && DESIRED_GTK_THEME="Adwaita"

# Apply GTK preference for both GTK3/GTK4 apps
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$DESIRED_GTK_THEME" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface icon-theme "Nordzy-dark" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface cursor-theme "Adwaita" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" >/dev/null 2>&1 || true
fi

# Ensure a theme key exists, but do not override user-selected GTK theme.
ensure_gtk_theme_name() {
    local settings_file="$1"
    local current_theme=""

    if [[ ! -f "$settings_file" ]]; then
        cat > "$settings_file" <<EOF
[Settings]
gtk-theme-name=${DESIRED_GTK_THEME}
EOF
        return
    fi

    if grep -q '^gtk-theme-name=' "$settings_file"; then
        current_theme="$(grep -m1 '^gtk-theme-name=' "$settings_file" | cut -d= -f2-)"
        if [[ -z "$current_theme" ]]; then
            sed -i "s/^gtk-theme-name=.*/gtk-theme-name=${DESIRED_GTK_THEME}/" "$settings_file"
        fi
    elif grep -q '^\[Settings\]' "$settings_file"; then
        printf 'gtk-theme-name=%s\n' "$DESIRED_GTK_THEME" >> "$settings_file"
    else
        printf '\n[Settings]\ngtk-theme-name=%s\n' "$DESIRED_GTK_THEME" >> "$settings_file"
    fi
}

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
ensure_gtk_theme_name "$GTK3_SETTINGS"
ensure_gtk_theme_name "$GTK4_SETTINGS"

# GTK apps often need restart to apply regenerated css
for gtk_proc in pcmanfm lxappearance gnome-text-editor gedit nautilus; do
    pkill -x "$gtk_proc" >/dev/null 2>&1 || true
done

# Putting swayosd reload into the background to not clutter the reloading process
if systemctl --user is-active --quiet swayosd.service; then
    systemctl --user restart swayosd.service &
fi

wait
