#!/bin/bash
# Test script for madOS Post-Installer DEMO MODE
# Run this to test the post-installer without installing packages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="${SCRIPT_DIR}/airootfs/usr/local/lib"

echo "══════════════════════════════════════════════════════════════"
echo "  madOS Post-Installer - DEMO MODE"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Checking PYTHONPATH and imports..."
echo ""

export PYTHONPATH="${LIB_PATH}:${PYTHONPATH}"

# Check if all modules can be imported
python3 -c "
from mados_post_install.config import DEMO_MODE, NORD, PACKAGE_GROUPS
print(f'✓ DEMO_MODE: {DEMO_MODE}')
print(f'✓ Nord colors: {len(NORD)} defined')
print(f'✓ Package groups: {len(PACKAGE_GROUPS)}')
print()
print('Configuration loaded successfully!')
"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Starting GUI Demo..."
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "NOTE: If you see 'cannot open display' error, you need to:"
echo "  1. Have X server running"
echo "  2. Set DISPLAY environment variable (e.g., export DISPLAY=:0)"
echo "  3. Allow X11 forwarding if using SSH (ssh -X)"
echo ""
echo "Starting post-installer GUI..."
echo ""

python3 -m mados_post_install

echo ""
echo "Demo completed!"
