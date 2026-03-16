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
        git pull --ff-only origin master 2>/dev/null || git pull --ff-only origin main 2>/dev/null || true
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
done

# Also install mados-installer (has different structure)
INSTALLER_APP="mados-installer"
INSTALLER_DIR="/usr/local/lib/${INSTALLER_APP}"
INSTALLER_PYTHON_DIR="/usr/local/lib/mados_installer"
INSTALLER_LAUNCHER="/usr/local/bin/${INSTALLER_APP}"

if [[ -d "$INSTALLER_PYTHON_DIR/.git" ]]; then
    echo "Updating $INSTALLER_APP..."
    cd "$INSTALLER_PYTHON_DIR"
    git pull --ff-only origin master 2>/dev/null || git pull --ff-only origin main 2>/dev/null || true
    cd /
else
    echo "Installing $INSTALLER_APP from GitHub..."
    rm -rf "$INSTALLER_DIR" "$INSTALLER_PYTHON_DIR"
    INSTALLER_BUILD_DIR=$(mktemp -d)
    if git clone --depth=1 "https://github.com/${GITHUB_REPO}/${INSTALLER_APP}.git" "$INSTALLER_BUILD_DIR/${INSTALLER_APP}" 2>&1; then
        mkdir -p /usr/local/lib
        mv "$INSTALLER_BUILD_DIR/${INSTALLER_APP}" "$INSTALLER_PYTHON_DIR"
        ln -sf "$INSTALLER_PYTHON_DIR" "$INSTALLER_DIR"
        
        # Create launcher script
        cat > "$INSTALLER_LAUNCHER" << 'EOF'
#!/bin/bash
# madOS Installer - Launcher script
cd "/usr/local/lib/mados_installer"
exec python3 -m mados_installer "$@"
EOF
        chmod +x "$INSTALLER_LAUNCHER"
        echo "✓ $INSTALLER_APP installed"
    else
        echo "⚠ Failed to install $INSTALLER_APP"
    fi
    rm -rf "$INSTALLER_BUILD_DIR"
fi

echo "✓ madOS applications suite installed"

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

echo "=== madOS: Pre-installation complete ==="
