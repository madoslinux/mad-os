"""
madOS Post-Installer - Theme
"""

from gi.repository import Gtk

from .config import NORD


def apply_theme():
    """Apply GTK theme - High contrast for readability"""
    css = f"""
    * {{
        font-family: 'JetBrains Mono', 'Courier New', monospace;
        font-size: 10px;
    }}
    
    window {{
        background-color: {NORD["nord0"]} !important;
        color: {NORD["nord5"]} !important;
    }}
    
    .content-card {{
        background-color: {NORD["nord0"]} !important;
        border: 1px solid {NORD["nord3"]};
        border-radius: 6px;
        padding: 8px;
        margin: 3px;
    }}
    
    .content-card * {{
        color: {NORD["nord5"]} !important;
    }}
    
    .package-list {{
        background-color: {NORD["nord0"]} !important;
        border: 1px solid {NORD["nord3"]};
        border-radius: 4px;
    }}
    
    .package-list row {{
        padding: 4px 6px;
        border-bottom: 1px solid {NORD["nord2"]};
        background-color: {NORD["nord0"]} !important;
    }}
    
    .package-list row * {{
        color: {NORD["nord5"]} !important;
    }}
    
    .package-list row:hover {{
        background-color: {NORD["nord2"]} !important;
    }}
    
    .package-list row:last-child {{
        border-bottom: none;
    }}
    
    progressbar {{
        min-height: 20px;
        border-radius: 4px;
        margin: 4px 0;
        background-color: {NORD["nord3"]} !important;
    }}
    
    progressbar progress {{
        background-color: {NORD["nord10"]} !important;
        border-radius: 4px;
    }}
    
    progressbar text {{
        color: {NORD["nord6"]} !important;
        font-weight: bold;
        font-size: 10px;
    }}
    
    label {{
        color: {NORD["nord5"]} !important;
    }}
    
    button {{
        background-color: {NORD["nord9"]} !important;
        color: {NORD["nord0"]} !important;
        border: none;
        padding: 8px 28px;
        border-radius: 5px;
        font-weight: bold;
        font-size: 11px;
    }}
    
    button:hover {{
        background-color: {NORD["nord8"]} !important;
        color: {NORD["nord0"]} !important;
    }}
    
    .success-button {{
        background-color: {NORD["nord10"]} !important;
        color: {NORD["nord0"]} !important;
    }}
    
    .success-button:hover {{
        background-color: #88B076 !important;
    }}
    
    button:disabled {{
        background-color: {NORD["nord2"]} !important;
        color: {NORD["nord5"]} !important;
    }}
    
    textview {{
        background-color: {NORD["nord0"]} !important;
        color: {NORD["nord5"]} !important;
        border: 1px solid {NORD["nord3"]};
        border-radius: 3px;
        padding: 4px;
    }}
    
    text {{
        color: {NORD["nord5"]} !important;
    }}
    
    scrollbar {{
        background-color: {NORD["nord1"]} !important;
    }}
    
    scrollbar slider {{
        background-color: {NORD["nord4"]} !important;
        border-radius: 3px;
        min-width: 10px;
    }}
    
    scrollbar slider:hover {{
        background-color: {NORD["nord5"]} !important;
    }}
    
    scrolledwindow {{
        background-color: {NORD["nord0"]} !important;
    }}
    
    scrolledwindow * {{
        background-color: {NORD["nord0"]} !important;
    }}
    
    frame {{
        background-color: {NORD["nord0"]} !important;
    }}
    
    frame border {{
        background-color: {NORD["nord0"]} !important;
    }}
    """
    
    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    screen = Gdk.Screen.get_default()
    Gtk.StyleContext.add_provider_for_screen(
        screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )


from gi.repository import Gdk
