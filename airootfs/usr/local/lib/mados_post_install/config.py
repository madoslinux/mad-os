"""
madOS Post-Installer - Configuration
"""

# ========== DEMO MODE ==========
# Set to True to run in demo mode (simulates installation)
# Set to False for real package installation
DEMO_MODE = False
# ================================

# Nord color palette
NORD = {
    "nord0": "#2E3440",
    "nord1": "#3B4252",
    "nord2": "#434C5E",
    "nord3": "#4C566A",
    "nord4": "#D8DEE9",
    "nord5": "#E5E9F0",
    "nord6": "#ECEFF4",
    "nord7": "#8FBCBB",
    "nord8": "#88C0D0",
    "nord9": "#81A1C1",
    "nord10": "#A3BE8C",
    "nord11": "#BF616A",
}

# Package groups (for reference, matches installer)
PACKAGE_GROUPS = {
    "dev_tools": {
        "name": "Development Tools",
        "icon": "🛠️",
    },
    "ai_ml": {
        "name": "AI/ML Tools",
        "icon": "🤖",
    },
    "multimedia": {
        "name": "Multimedia Production",
        "icon": "🎨",
    },
}
