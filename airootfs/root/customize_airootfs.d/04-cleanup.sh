#!/usr/bin/env bash
# 04-cleanup.sh - Clean up caches and unnecessary files
# Atomic module for cleanup operations
set -euo pipefail

clean_pacman_cache() {
    echo "Cleaning pacman cache..."
    rm -rf /var/cache/pacman/pkg/*
    echo "✓ Pacman cache cleaned"
}

clean_docs_man_locales() {
    echo "Removing docs and man pages..."
    rm -rf /usr/share/doc/*
    rm -rf /usr/share/man/*
    rm -rf /usr/share/gtk-doc/*
    find /usr/share/gnome/help -type f -delete 2>/dev/null || true
    find /usr/share/gnome/parsers -type f -delete 2>/dev/null || true
    echo "✓ Docs/man cleaned"
}

clean_npm_cache() {
    echo "Cleaning npm cache..."
    rm -rf /root/.npm 2>/dev/null || true
    rm -rf /home/mados/.npm 2>/dev/null || true
    rm -rf /root/.cache/npm 2>/dev/null || true
    rm -rf /home/mados/.cache/npm 2>/dev/null || true
    echo "✓ npm cache cleaned"
}

clean_python_tests() {
    echo "Removing Python test files..."
    find /usr/lib/python3.*/site-packages -type d -name "test*" -exec rm -rf {} + 2>/dev/null || true
    find /usr/lib/python3.*/site-packages -type d -name "*_tests" -exec rm -rf {} + 2>/dev/null || true
    find /usr/lib/python3.*/site-packages -name "test_*.py" -delete 2>/dev/null || true
    find /usr/lib/python3.*/site-packages -name "*_test.py" -delete 2>/dev/null || true
    find /usr/lib/python3.*/site-packages -name "conftest.py" -delete 2>/dev/null || true
    echo "✓ Python tests cleaned"
}

clean_debug_symbols() {
    echo "Removing debug symbols..."
    find /usr -name "*.debug" -type f -delete 2>/dev/null || true
    find /usr -name "*.pyc" -type f -delete 2>/dev/null || true
    find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "✓ Debug symbols cleaned"
}

clean_unused_fonts_icons() {
    echo "Removing unused fonts and icons..."
    rm -rf /usr/share/fonts/truetype/hints 2>/dev/null || true
    rm -rf /usr/share/fonts/truetype/arphic 2>/dev/null || true
    rm -rf /usr/share/fonts/truetype/dejavu 2>/dev/null || true
    rm -rf /usr/share/fonts/truetype/liberation 2>/dev/null || true
    rm -rf /usr/share/icons/hicolor 2>/dev/null || true
    rm -rf /usr/share/icons/Adwaita 2>/dev/null || true
    rm -rf /usr/share/pixmaps/gnome 2>/dev/null || true
    echo "✓ Fonts/icons cleaned"
}

keep_only_supported_locales() {
    echo "Keeping locale support for 9 languages..."
    local supported_prefixes=(
        en
        es
        fr
        de
        it
        pt
        ru
        ja
        zh
    )

    for lang in /usr/share/locale/*; do
        local lang_name
        lang_name=$(basename "$lang")

        if [[ "$lang_name" == "locale.alias" ]]; then
            continue
        fi

        local keep=false
        local prefix
        for prefix in "${supported_prefixes[@]}"; do
            if [[ "$lang_name" == "$prefix" || "$lang_name" == "${prefix}_"* ]]; then
                keep=true
                break
            fi
        done

        if [[ "$keep" == false ]]; then
            rm -rf "$lang"
        fi
    done
    echo "✓ 9-language locale set applied"
}

clean_pacman_db() {
    echo "Cleaning pacman local database..."
    local pacman_local_db="/var/lib/pacman/local"
    if [[ -d "$pacman_local_db" ]]; then
        local cleaned=0
        for desc_file in "$pacman_local_db"/*/desc; do
            if [[ -f "$desc_file" ]] && grep -q "^%INSTALLED_DB%$" "$desc_file" 2>/dev/null; then
                sed -i '/^%INSTALLED_DB%$/,+1d' "$desc_file"
                ((cleaned++)) || true
            fi
        done
        echo "  → Cleaned $cleaned package entries"
    fi
}

set_executable_permissions() {
    echo "Setting executable permissions..."
    chmod +x /usr/local/bin/mados-help 2>/dev/null || true
    chmod +x /usr/local/bin/mados-power 2>/dev/null || true
    echo "✓ Permissions set"
}

hide_unwanted_desktop_entries() {
    echo "Hiding unwanted desktop entries..."
    local unwanted=(
        /usr/share/applications/xgps.desktop
        /usr/share/applications/xgpsspeed.desktop
        /usr/share/applications/pcmanfm-desktop-pref.desktop
        /usr/share/applications/qv4l2.desktop
        /usr/share/applications/qvidcap.desktop
        /usr/share/applications/mpv.desktop
        /usr/share/applications/uuctl.desktop
        /usr/share/applications/foot-server.desktop
        /usr/share/applications/footclient.desktop
    )
    
    for desktop_file in "${unwanted[@]}"; do
        if [[ -f "$desktop_file" ]]; then
            cat > "$desktop_file" << 'EOF'
[Desktop Entry]
NoDisplay=true
Hidden=true
Type=Application
EOF
            echo "  → Hidden: $(basename "$desktop_file")"
        fi
    done
    echo "✓ Desktop entries hidden"
}

install_yay() {
    local yay_version="12.5.7"
    local yay_bin="/usr/local/bin/yay"
    local yay_tmp="/tmp/yay.tar.gz"
    local yay_url="https://github.com/Jguer/yay/releases/download/v${yay_version}/yay_${yay_version}_x86_64.tar.gz"
    
    if command -v yay &>/dev/null && yay --version &>/dev/null; then
        echo "yay already installed"
        return 0
    fi
    
    if [[ -x "$yay_bin" ]] && "$yay_bin" --version &>/dev/null; then
        echo "yay binary found in /usr/local/bin (offline mode)"
        return 0
    fi
    
    echo "Installing yay ${yay_version}..."
    if curl -fsSL --proto '=https' --tlsv1.2 -o "$yay_tmp" "$yay_url" 2>&1; then
        tar -xzf "$yay_tmp" -C /tmp
        mkdir -p /usr/local/bin
        mv "/tmp/yay_${yay_version}_x86_64/yay" "$yay_bin"
        rm -rf "$yay_tmp" "/tmp/yay_${yay_version}_x86_64"
        chmod +x "$yay_bin"
        if "$yay_bin" --version &>/dev/null; then
            echo "✓ yay installed to $yay_bin"
        else
            rm -f "$yay_bin"
            echo "WARNING: yay downloaded but failed to run (libalpm mismatch)."
        fi
    else
        echo "WARNING: Failed to download yay (offline mode requires pre-built ISO)"
    fi
    return 0
}

configure_wheel_group() {
    echo "Configuring wheel group and permissions..."
    if id 1000 &>/dev/null; then
        groupadd -g 10 wheel 2>/dev/null || true
        usermod -aG wheel 1000 2>/dev/null || true
        usermod -aG input 1000 2>/dev/null || true
        usermod -aG video 1000 2>/dev/null || true
        
        for bin in ollama opencode openclaw forge forgecode; do
            for path in /usr/bin/$bin /usr/local/bin/$bin; do
                if [[ -f "$path" ]]; then
                    chown root:wheel "$path"
                    chmod 755 "$path"
                    echo "  → Configured: $path"
                fi
            done
        done
    fi
    echo "✓ Wheel group configured"
}

cleanup_all() {
    clean_pacman_cache
    clean_docs_man_locales
    clean_npm_cache
    clean_python_tests
    clean_debug_symbols
    clean_unused_fonts_icons
    keep_only_supported_locales
    clean_pacman_db
    set_executable_permissions
    hide_unwanted_desktop_entries
    install_yay
    configure_wheel_group
    echo "✓ All cleanup complete"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== madOS Cleanup ==="
    cleanup_all
    echo "=== Cleanup complete ==="
fi
