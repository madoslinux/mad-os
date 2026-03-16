#!/usr/bin/env python3
"""
madOS Installer - Launcher script
Thin wrapper that imports and runs the modular installer package
from /usr/local/lib/mados_installer/
"""

import os
import sys

INSTALLER_DIR = "/usr/local/lib/mados_installer"

os.chdir(INSTALLER_DIR)
sys.path.insert(0, "/usr/local/lib")
sys.path.insert(0, INSTALLER_DIR)

from mados_installer import main

main()
