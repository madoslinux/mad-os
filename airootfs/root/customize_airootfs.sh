#!/usr/bin/env bash
# customize_airootfs.sh - Pre-install Oh My Zsh and OpenCode during ISO build
#
# This script is executed by mkarchiso inside the chroot after packages are
# installed. It pre-installs Oh My Zsh and OpenCode so they are available
# immediately in the live environment without needing network at boot.

set -e

echo "=== madOS: Pre-installing Oh My Zsh and OpenCode ==="

# ── Nordic GTK Theme (from EliverLara/Nordic) ─────────────────────────────
NORDIC_DIR="/usr/share/themes/Nordic"

if [[ -d "$NORDIC_DIR" ]]; then
    echo "✓ Nordic GTK theme already installed"
else
    echo "Installing Nordic GTK theme..."
    NORDIC_BUILD_DIR=$(mktemp -d)
    if git clone --depth=1 https://github.com/EliverLara/Nordic.git "$NORDIC_BUILD_DIR/Nordic" 2>&1; then
        mkdir -p /usr/share/themes
        cp -a "$NORDIC_BUILD_DIR/Nordic" "$NORDIC_DIR"
        # Clean up unnecessary files to save space
        rm -rf "$NORDIC_DIR/.git" "$NORDIC_DIR/.gitignore" "$NORDIC_DIR/Art" "$NORDIC_DIR/LICENSE" "$NORDIC_DIR/README.md" "$NORDIC_DIR/KDE" "$NORDIC_DIR/Wallpaper"
        echo "✓ Nordic GTK theme installed"
    else
        echo "⚠ Failed to clone Nordic GTK theme"
    fi
    [[ -n "$NORDIC_BUILD_DIR" ]] && rm -rf "$NORDIC_BUILD_DIR"
fi

# ── Nordzy Icon Theme (from MolassesLover/Nordzy-icon) ─────────────────────
NORDZY_DIR="/usr/share/icons/Nordzy-dark"

if [[ -d "$NORDZY_DIR" ]]; then
    echo "✓ Nordzy-dark icon theme already installed"
else
    echo "Installing Nordzy-dark icon theme..."
    NORDZY_BUILD_DIR=$(mktemp -d)
    if git clone --depth=1 https://github.com/MolassesLover/Nordzy-icon.git "$NORDZY_BUILD_DIR/Nordzy-icon" 2>&1; then
        cd "$NORDZY_BUILD_DIR/Nordzy-icon"
        bash install.sh -d /usr/share/icons -c dark -t default
        # Clean up build directory
        cd /
        echo "✓ Nordzy-dark icon theme installed"
    else
        echo "⚠ Failed to clone Nordzy icon theme"
    fi
    [[ -n "$NORDZY_BUILD_DIR" ]] && rm -rf "$NORDZY_BUILD_DIR"
fi

# ── Michroma Font (from Google Fonts - Direct Download) ────────────────────
MICHROMA_DIR="/usr/share/fonts/truetype/michroma"

if [[ -d "$MICHROMA_DIR" ]] && [[ -f "$MICHROMA_DIR/Michroma-Regular.ttf" ]]; then
    echo "✓ Michroma font already installed"
else
    echo "Installing Michroma font..."
    mkdir -p "$MICHROMA_DIR"
    if curl -fsSL "https://github.com/google/fonts/raw/main/ofl/michroma/Michroma-Regular.ttf" -o "$MICHROMA_DIR/Michroma-Regular.ttf" 2>&1; then
        echo "✓ Michroma font installed"
    else
        echo "⚠ Failed to install Michroma font"
    fi
fi

# ════════════════════════════════════════════════════════════════════════════
# madOS Applications Suite - Download from GitHub
# ════════════════════════════════════════════════════════════════════════════

MADOS_APPS=(
    "mados-audio-player"
    "mados-equalizer"
    "mados-launcher"
    "mados-pdf-viewer"
    "mados-photo-viewer"
    "mados-video-player"
    "mados-wallpaper"
)

GITHUB_REPO="madoslinux"

for app in "${MADOS_APPS[@]}"; do
    APP_DIR="/usr/local/lib/${app}"
    PYTHON_APP_NAME="${app//-/_}"
    PYTHON_APP_DIR="/usr/local/lib/${PYTHON_APP_NAME}"
    LAUNCHER="/usr/local/bin/${app}"
    APP_NAME="${app#mados-}"
    
    if [[ -d "$PYTHON_APP_DIR/.git" ]]; then
        echo "Updating $app..."
        cd "$PYTHON_APP_DIR"
        git pull --ff-only origin main 2>/dev/null || true
        cd /
    else
        echo "Installing $app from GitHub..."
        rm -rf "$APP_DIR" "$PYTHON_APP_DIR"
        APP_BUILD_DIR=$(mktemp -d)
        if git clone --depth=1 "https://github.com/${GITHUB_REPO}/${app}.git" "$APP_BUILD_DIR/${app}" 2>&1; then
            mkdir -p /usr/local/lib
            # Rename directory to use underscores for Python module
            mv "$APP_BUILD_DIR/${app}" "$PYTHON_APP_DIR"
            
            # Create launcher script - run as module from app directory
            cat > "$LAUNCHER" << EOF
#!/bin/bash
# madOS ${APP_NAME^} - Launcher script
cd "/usr/local/lib/${PYTHON_APP_NAME}"
export PYTHONPATH="/usr/local/lib:${PYTHONPATH}"
exec python3 -m "${PYTHON_APP_NAME}" "\$@"
EOF
            chmod +x "$LAUNCHER"
            echo "✓ $app installed"
        else
            echo "⚠ Failed to install $app"
        fi
        rm -rf "$APP_BUILD_DIR"
    fi
    
    # Fix mados-wallpaper: needs GTK3 fixes and no CSS
    if [[ "$app" == "mados-wallpaper" && -f "$PYTHON_APP_DIR/workspace_card.py" ]]; then
        # Fix GTK version
        sed -i 's/gi.require_version("Gtk", "4.0")/gi.require_version("Gtk", "3.0")/' "$PYTHON_APP_DIR/workspace_card.py"
        sed -i 's/gi.require_version("Gdk", "4.0")/gi.require_version("Gdk", "3.0")/' "$PYTHON_APP_DIR/workspace_card.py"
        # Remove all EventController (GTK4) and use VBox instead
        sed -i 's/class WorkspaceCard(Gtk.Box)/class WorkspaceCard(Gtk.VBox)/g' "$PYTHON_APP_DIR/workspace_card.py"
        sed -i 's/set_css_classes/get_style_context().add_class/g' "$PYTHON_APP_DIR/workspace_card.py"
        # Fix GTK4 Picture to GTK3 Image
        sed -i 's/Gtk.Picture.new_for_pixbuf/Gtk.Image().set_from_pixbuf/g' "$PYTHON_APP_DIR/workspace_card.py"
        # Remove EventController and GestureClick
        sed -i '/EventController/d' "$PYTHON_APP_DIR/workspace_card.py"
        sed -i '/GestureClick/d' "$PYTHON_APP_DIR/workspace_card.py"
        sed -i '/add_controller/d' "$PYTHON_APP_DIR/workspace_card.py"
        # Add Pango import
        sed -i '/from gi.repository import Gtk, Gdk/ a from gi.repository import Pango' "$PYTHON_APP_DIR/workspace_card.py"
    fi
    
    # Fix app.py for GTK3 - remove CSS and use show_all
    if [[ "$app" == "mados-wallpaper" && -f "$PYTHON_APP_DIR/app.py" ]]; then
        sed -i 's/window.show()/window.show_all()/g' "$PYTHON_APP_DIR/app.py"
        sed -i 's/add_provider_for_display/add_provider_for_screen/g' "$PYTHON_APP_DIR/app.py"
        sed -i 's/Gdk\.Display\.get_default()/Gdk.Screen.get_default()/g' "$PYTHON_APP_DIR/app.py"
        # Replace CSS with simple header
        sed -i '/css = f"""{/,/^        """/d' "$PYTHON_APP_DIR/app.py"
        sed -i '/provider = Gtk.CssProvider()/,/Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION/d' "$PYTHON_APP_DIR/app.py"
    fi
done

# ── Post-install mados-wallpaper: desktop entry, icon, and default wallpapers ──
WALLPAPER_APP_DIR="/usr/local/lib/mados_wallpaper"
if [[ -d "$WALLPAPER_APP_DIR" ]]; then
    echo "Setting up mados-wallpaper desktop entry and icons..."

    # Copy .desktop file to system applications
    if [[ -f "$WALLPAPER_APP_DIR/mados-wallpaper.desktop" ]]; then
        cp "$WALLPAPER_APP_DIR/mados-wallpaper.desktop" /usr/share/applications/
        echo "  → Desktop entry installed"
    else
        echo "  → WARNING: mados-wallpaper.desktop not found"
    fi

    # Copy icon to system icons
    if [[ -f "$WALLPAPER_APP_DIR/mados-wallpaper.svg" ]]; then
        mkdir -p /usr/share/icons/hicolor/scalable/apps
        cp "$WALLPAPER_APP_DIR/mados-wallpaper.svg" /usr/share/icons/hicolor/scalable/apps/mados-wallpaper.svg
        mkdir -p /usr/share/icons/hicolor/48x48/apps
        cp "$WALLPAPER_APP_DIR/mados-wallpaper.svg" /usr/share/icons/hicolor/48x48/apps/mados-wallpaper.svg 2>/dev/null || true
        echo "  → Icon installed"
    else
        echo "  → WARNING: mados-wallpaper.svg not found"
    fi

    # Copy default wallpapers to skel for new users
    if [[ -d "$WALLPAPER_APP_DIR" ]]; then
        wp_count=$(ls -1 "$WALLPAPER_APP_DIR"/*.png 2>/dev/null | wc -l)
        echo "  → Found $wp_count wallpapers in repo"
        
        mkdir -p /etc/skel/.local/share/mados/wallpapers
        cp "$WALLPAPER_APP_DIR"/*.png /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null || true
        copied_skel=$(ls -1 /etc/skel/.local/share/mados/wallpapers/ 2>/dev/null | wc -l)
        echo "  → $copied_skel wallpapers copied to skel"

        # Also copy wallpapers to /usr/share/backgrounds for daemon
        mkdir -p /usr/share/backgrounds
        cp "$WALLPAPER_APP_DIR"/*.png /usr/share/backgrounds/ 2>/dev/null || true
        wp_sys=$(ls -1 /usr/share/backgrounds/*.png 2>/dev/null | wc -l)
        echo "  → $wp_sys wallpapers copied to /usr/share/backgrounds"

        # Also copy wallpapers to existing mados user (for live ISO)
        if [[ -d /home/mados ]]; then
            mkdir -p /home/mados/.local/share/mados/wallpapers
            cp "$WALLPAPER_APP_DIR"/*.png /home/mados/.local/share/mados/wallpapers/ 2>/dev/null || true
            chown -R 1000:1000 /home/mados/.local/share/mados
            copied_home=$(ls -1 /home/mados/.local/share/mados/wallpapers/ 2>/dev/null | wc -l)
            echo "  → $copied_home wallpapers copied to /home/mados"
        fi
    else
        echo "  → ERROR: $WALLPAPER_APP_DIR not found"
    fi
else
    echo "  → ERROR: mados-wallpaper not installed at $WALLPAPER_APP_DIR"
fi

# Also install mados-installer (has different structure)
INSTALLER_APP="mados-installer"
INSTALLER_DIR="/usr/local/lib/${INSTALLER_APP}"
INSTALLER_PYTHON_DIR="/usr/local/lib/mados_installer"
INSTALLER_LAUNCHER="/usr/local/bin/${INSTALLER_APP}"

if [[ -d "$INSTALLER_PYTHON_DIR/.git" ]]; then
    echo "Updating $INSTALLER_APP..."
    cd "$INSTALLER_PYTHON_DIR"
        git pull --ff-only origin main 2>/dev/null || true
    cd /
else
    echo "Installing $INSTALLER_APP from GitHub..."
    rm -rf "$INSTALLER_DIR" "$INSTALLER_PYTHON_DIR"
    INSTALLER_BUILD_DIR=$(mktemp -d)
    if git clone --depth=1 "https://github.com/${GITHUB_REPO}/${INSTALLER_APP}.git" "$INSTALLER_BUILD_DIR/${INSTALLER_APP}" 2>&1; then
        mkdir -p /usr/local/lib
        mv "$INSTALLER_BUILD_DIR/${INSTALLER_APP}" "$INSTALLER_PYTHON_DIR"
        ln -sf "$INSTALLER_PYTHON_DIR" "$INSTALLER_DIR"
        
    else
        echo "⚠ Failed to install $INSTALLER_APP"
    fi
    rm -rf "$INSTALLER_BUILD_DIR"
fi

# Create launcher script (always, whether new or update)
if [[ -d "$INSTALLER_PYTHON_DIR" ]]; then
    cat > "$INSTALLER_LAUNCHER" << 'EOF'
#!/bin/bash
# madOS Installer - Launcher script
export PYTHONPATH="/usr/local/lib:${PYTHONPATH}"
cd "/usr/local/lib/mados_installer"
exec python3 -m mados_installer "$@"
EOF
    chmod +x "$INSTALLER_LAUNCHER"
    echo "✓ $INSTALLER_APP launcher created at $INSTALLER_LAUNCHER"
fi

echo "✓ madOS applications suite installed"

# ── mados-updater (OTA update client from madkoding) ─────────────────────
UPDATER_APP="mados-updater"
UPDATER_DIR="/usr/local/lib/${UPDATER_APP}"
UPDATER_PYTHON_DIR="/usr/local/lib/mados_updater"
UPDATER_LAUNCHER="/usr/local/bin/${UPDATER_APP}"
UPDATER_GITHUB_REPO="madkoding"

if [[ -d "$UPDATER_PYTHON_DIR/.git" ]]; then
    echo "Updating $UPDATER_APP..."
    cd "$UPDATER_PYTHON_DIR"
    git pull --ff-only origin main 2>/dev/null || true
    cd /
else
    echo "Installing $UPDATER_APP from GitHub..."
    rm -rf "$UPDATER_DIR" "$UPDATER_PYTHON_DIR"
    UPDATER_BUILD_DIR=$(mktemp -d)
    if git clone --depth=1 "https://github.com/${UPDATER_GITHUB_REPO}/${UPDATER_APP}.git" "$UPDATER_BUILD_DIR/${UPDATER_APP}" 2>&1; then
        mkdir -p /usr/local/lib
        mv "$UPDATER_BUILD_DIR/${UPDATER_APP}" "$UPDATER_PYTHON_DIR"
        ln -sf "$UPDATER_PYTHON_DIR" "$UPDATER_DIR"
        echo "✓ $UPDATER_APP installed"
    else
        echo "⚠ Failed to install $UPDATER_APP"
    fi
    rm -rf "$UPDATER_BUILD_DIR"
fi

# Create launcher script (always, whether new or update)
if [[ -d "$UPDATER_PYTHON_DIR" ]]; then
    cat > "$UPDATER_LAUNCHER" << 'EOF'
#!/bin/bash
# madOS Updater - OTA update client
export PYTHONPATH="/usr/local/lib:${PYTHONPATH}"
cd "/usr/local/lib/mados_updater"
exec python3 -m mados_updater "$@"
EOF
    chmod +x "$UPDATER_LAUNCHER"
    echo "✓ $UPDATER_APP launcher created at $UPDATER_LAUNCHER"
fi

# Install systemd units for mados-updater
if [[ -d "$UPDATER_PYTHON_DIR" ]]; then
    mkdir -p /etc/systemd/system
    cat > /etc/systemd/system/mados-updater.service << 'EOF'
[Unit]
Description=mados-updater check for updates
Documentation=https://github.com/madkoding/mados-updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mados-updater --check
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/mados-updater.timer << 'EOF'
[Unit]
Description=mados-updater periodic update check
Documentation=https://github.com/madkoding/mados-updater

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF
    chmod 644 /etc/systemd/system/mados-updater.service
    chmod 644 /etc/systemd/system/mados-updater.timer
    echo "✓ $UPDATER_APP systemd units installed"
fi

# ════════════════════════════════════════════════════════════════════════════
# NVM (Node Version Manager) y Node
# NOTA: No se instala en la imagen ISO para reducir tamaño.
# Se instalará automáticamente post-instalación para el usuario.
# ════════════════════════════════════════════════════════════════════════════
echo "NVM and Node installation skipped (will be installed post-installation)"

# ── Oh My Zsh ────────────────────────────────────────────────────────────
# Instala en /usr/share - los usuarios usan symlinks para ahorrar ~400-600MB en la ISO
OMZ_DIR="/usr/share/oh-my-zsh"

if [[ ! -d "$OMZ_DIR" ]]; then
    echo "Installing Oh My Zsh to /usr/share..."
    if git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR" 2>&1; then
        echo "✓ Oh My Zsh installed to /usr/share"
        
        # Crear symlinks para usuarios (después de que archiso copie skel)
        if [[ -d /home/mados ]]; then
            rm -rf /home/mados/.oh-my-zsh
            ln -sf /usr/share/oh-my-zsh /home/mados/.oh-my-zsh
            chown -h 1000:1000 /home/mados/.oh-my-zsh
            echo "  → Linked Oh My Zsh to /home/mados"
        fi
        
        rm -rf /root/.oh-my-zsh
        ln -sf /usr/share/oh-my-zsh /root/.oh-my-zsh
        echo "  → Linked Oh My Zsh to /root"
    else
        echo "⚠ Failed to clone Oh My Zsh (will install at boot)"
    fi
else
    echo "✓ Oh My Zsh already present in /usr/share"
fi

# Also create in /etc/skel so installer can copy it
if [[ -d "$OMZ_DIR" && ! -d /etc/skel/.oh-my-zsh ]]; then
    ln -sf /usr/share/oh-my-zsh /etc/skel/.oh-my-zsh
    echo "  → Linked Oh My Zsh to /etc/skel (for installer)"
fi

# Copy .zshrc to mados user
if [[ -d /home/mados && ! -f /home/mados/.zshrc && -f /etc/skel/.zshrc ]]; then
    cp /etc/skel/.zshrc /home/mados/.zshrc
    chown 1000:1000 /home/mados/.zshrc
    echo "  → Copied .zshrc to /home/mados"
fi

# Copy .zshrc to root if not present
if [[ ! -f /root/.zshrc && -f /etc/skel/.zshrc ]]; then
    cp /etc/skel/.zshrc /root/.zshrc
    echo "  → Copied .zshrc to /root"
fi

# ── Hide unwanted .desktop entries from application menu ──────────────────
echo "Hiding unwanted application menu entries..."
for desktop_file in \
    /usr/share/applications/xgps.desktop \
    /usr/share/applications/xgpsspeed.desktop \
    /usr/share/applications/pcmanfm-desktop-pref.desktop \
    /usr/share/applications/qv4l2.desktop \
    /usr/share/applications/qvidcap.desktop \
    /usr/share/applications/mpv.desktop; do
    if [[ -f "$desktop_file" ]]; then
        echo -e "[Desktop Entry]\nNoDisplay=true\nHidden=true\nType=Application" > "$desktop_file"
        echo "  → Hidden: $(basename "$desktop_file")"
    fi
done
echo "✓ Unwanted desktop entries hidden"

# ════════════════════════════════════════════════════════════════════════════
# Clean up package cache to reduce ISO size
# ════════════════════════════════════════════════════════════════════════════
echo "Cleaning up package cache..."
rm -rf /var/cache/pacman/pkg/*

echo "Removing unnecessary files (docs, man pages, locales)..."
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*
rm -rf /usr/share/locale/*
rm -rf /usr/share/gtk-doc/*
find /usr/share/gnome/help -type f -delete 2>/dev/null || true
find /usr/share/gnome/parsers -type f -delete 2>/dev/null || true

echo "Cleaning up npm cache..."
rm -rf /root/.npm 2>/dev/null || true
rm -rf /home/mados/.npm 2>/dev/null || true
rm -rf /root/.cache/npm 2>/dev/null || true
rm -rf /home/mados/.cache/npm 2>/dev/null || true

echo "Removing package test files..."
find /usr/lib/python3.*/site-packages -type d -name "test*" -exec rm -rf {} + 2>/dev/null || true
find /usr/lib/python3.*/site-packages -type d -name "*_tests" -exec rm -rf {} + 2>/dev/null || true
find /usr/lib/python3.*/site-packages -name "test_*.py" -delete 2>/dev/null || true
find /usr/lib/python3.*/site-packages -name "*_test.py" -delete 2>/dev/null || true
find /usr/lib/python3.*/site-packages -name "conftest.py" -delete 2>/dev/null || true

echo "Removing debug symbols and unnecessary binaries..."
find /usr -name "*.debug" -type f -delete 2>/dev/null || true
find /usr -name "*.pyc" -type f -delete 2>/dev/null || true
find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

echo "Removing unused fonts and icons..."
rm -rf /usr/share/fonts/truetype/hints 2>/dev/null || true
rm -rf /usr/share/fonts/truetype/arphic 2>/dev/null || true
rm -rf /usr/share/fonts/truetype/dejavu 2>/dev/null || true
rm -rf /usr/share/fonts/truetype/liberation 2>/dev/null || true
rm -rf /usr/share/icons/hicolor 2>/dev/null || true
rm -rf /usr/share/icons/Adwaita 2>/dev/null || true
rm -rf /usr/share/pixmaps/gnome 2>/dev/null || true

echo "Updating font cache..."
fc-cache -f /usr/share/fonts/truetype/ 2>/dev/null || true

echo "Removing unnecessary locales (keeping en_US, es_ES)..."
for lang in /usr/share/locale/*; do
    lang_name=$(basename "$lang")
    if [[ "$lang_name" != "en_US" && "$lang_name" != "es_ES" && "$lang_name" != "locale.alias" ]]; then
        rm -rf "$lang"
    fi
done

echo "✓ Package cache cleaned"
echo "✓ Unnecessary files removed"

echo "=== madOS: Ensuring executable permissions ==="
chmod +x /usr/local/bin/mados-help
chmod +x /usr/local/bin/mados-power

echo "=== madOS: Configuring ollama and opencode for wheel group ==="
if id 1000 &>/dev/null; then
    # Ensure wheel group exists with GID 10
    groupadd -g 10 wheel 2>/dev/null || true
    usermod -aG wheel 1000 2>/dev/null || true
    
    # Set ownership to root:wheel - everyone can execute, but only wheel can sudo
    # This allows: normal users to run ollama/opencode, wheel users can sudo them
    for bin in ollama opencode; do
        for path in /usr/bin/$bin /usr/local/bin/$bin; do
            if [[ -f "$path" ]]; then
                chown root:wheel "$path"
                chmod 755 "$path"
                echo "  → Configured: $path (root:wheel, 755)"
            fi
        done
    done
fi

# ── Fix pacman %INSTALLED_DB% warning ────────────────────────────────────────
# Clean unknown %INSTALLED_DB% entries from local pacman DB
# This prevents warnings when pacman version differs between build host and live system
echo "=== madOS: Cleaning pacman local database ==="
PACMAN_LOCAL_DB="/var/lib/pacman/local"
if [[ -d "$PACMAN_LOCAL_DB" ]]; then
    cleaned=0
    for desc_file in "$PACMAN_LOCAL_DB"/*/desc; do
        if [[ -f "$desc_file" ]] && grep -q "^%INSTALLED_DB%$" "$desc_file" 2>/dev/null; then
            sed -i '/^%INSTALLED_DB%$/,+1d' "$desc_file"
            ((cleaned++)) || true
        fi
    done
    echo "  → Cleaned $cleaned package entries"
fi

# ════════════════════════════════════════════════════════════════════════════
# Yay (AUR helper) - Pre-install from binary
# ════════════════════════════════════════════════════════════════════════════
YAY_VERSION="12.4.1"
    YAY_BIN="$HOME/.local/bin/yay"

if command -v yay &>/dev/null; then
    echo "✓ yay already installed"
else
    echo "Installing yay ${YAY_VERSION}..."
    YAY_TMP="/tmp/yay.tar.gz"
    YAY_URL="https://github.com/Jguer/yay/releases/download/v${YAY_VERSION}/yay_${YAY_VERSION}_x86_64.tar.gz"
    if curl -fsSL --proto '=https' --tlsv1.2 -o "$YAY_TMP" "$YAY_URL" 2>&1; then
        tar -xzf "$YAY_TMP" -C /tmp
        mkdir -p "$HOME/.local/bin"
        mv "/tmp/yay_${YAY_VERSION}_x86_64/yay" "$YAY_BIN"
        rm -rf "$YAY_TMP" "/tmp/yay_${YAY_VERSION}_x86_64"
        chmod +x "$YAY_BIN"
        echo "✓ yay installed to $YAY_BIN"
    else
        echo "⚠ Failed to download yay"
    fi
fi

echo "=== madOS: Pre-installation complete ==="

# ── Replace gufw.desktop with our sudo-enabled version ────────────────────
# The package installs its own .desktop with Exec=gufw (which uses pkexec and fails in Wayland).
# We must replace it after pacman installation.
rm -f /usr/share/applications/gufw.desktop
cat > /usr/share/applications/gufw.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Name=Firewall Configuration
Comment=Configure firewall with GUFW
Exec=sudo gufw
Icon=gufw
Terminal=false
Type=Application
Categories=System;Settings;Security;
Keywords=firewall;ufw;security;
EOF
chmod 644 /usr/share/applications/gufw.desktop
echo "  → Replaced gufw.desktop with sudo-enabled version"
cat /usr/share/applications/gufw.desktop | grep "^Exec="
