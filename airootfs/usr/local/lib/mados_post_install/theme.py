"""
madOS Post-Installer - Theme
"""

from gi.repository import Gtk, Gdk

from .config import NORD


def apply_theme():
    """Apply GTK theme - High contrast for readability"""
    css = f"""
    * {{
        font-family: 'JetBrains Mono', 'Courier New', monospace;
        font-size: 10px;
    }}
    
    window {{
        background-color: {NORD["nord0"]};
        color: {NORD["nord5"]};
    }}
    
    .content-card {{
        background-color: {NORD["nord0"]};
        border: 1px solid {NORD["nord3"]};
        border-radius: 6px;
        padding: 8px;
        margin: 3px;
    }}
    
    .content-card label {{
        color: {NORD["nord5"]};
    }}
    
    .content-card frame {{
        background-color: {NORD["nord0"]};
    }}
    
    .content-card scrolledwindow {{
        background-color: {NORD["nord0"]};
    }}
    
    .package-list {{
        background-color: {NORD["nord0"]};
        border: 1px solid {NORD["nord3"]};
        border-radius: 4px;
    }}
    
    .package-list row {{
        padding: 4px 6px;
        border-bottom: 1px solid {NORD["nord2"]};
        background-color: {NORD["nord0"]};
    }}
    
    .package-list row label {{
        color: {NORD["nord5"]};
    }}
    
    .package-list row:hover {{
        background-color: {NORD["nord2"]};
    }}
    
    .package-list row:last-child {{
        border-bottom: none;
    }}
    
    progressbar {{
        min-height: 20px;
        border-radius: 4px;
        margin: 4px 0;
    }}
    
    progressbar progress {{
        background-color: {NORD["nord10"]};
        border-radius: 4px;
    }}
    
    progressbar trough {{
        background-color: {NORD["nord3"]};
        border-radius: 4px;
    }}
    
    progressbar text {{
        color: {NORD["nord6"]};
        font-weight: bold;
    }}
    
    label {{
        color: {NORD["nord5"]};
    }}
    
    button {{
        background-color: {NORD["nord9"]};
        color: {NORD["nord0"]};
        border: none;
        padding: 8px 28px;
        border-radius: 5px;
        font-weight: bold;
        font-size: 11px;
    }}
    
    button:hover {{
        background-color: {NORD["nord8"]};
        color: {NORD["nord0"]};
    }}
    
    .success-button {{
        background-color: {NORD["nord10"]};
        color: {NORD["nord0"]};
    }}
    
    .success-button:hover {{
        background-color: #88B076;
    }}
    
    button:disabled {{
        background-color: {NORD["nord2"]};
        color: {NORD["nord5"]};
    }}
    
    textview {{
        background-color: {NORD["nord0"]};
        color: {NORD["nord5"]};
        border: 1px solid {NORD["nord3"]};
        border-radius: 3px;
        padding: 4px;
    }}
    
    text {{
        background-color: {NORD["nord0"]};
        color: {NORD["nord5"]};
    }}
    
    scrollbar {{
        background-color: {NORD["nord1"]};
    }}
    
    scrollbar slider {{
        background-color: {NORD["nord4"]};
        border-radius: 3px;
        min-width: 10px;
    }}
    
    scrollbar slider:hover {{
        background-color: {NORD["nord5"]};
    }}
    
    scrolledwindow {{
        background-color: {NORD["nord0"]};
    }}
    
    scrolledwindow viewport {{
        background-color: {NORD["nord0"]};
    }}
    
    frame {{
        background-color: {NORD["nord0"]};
    }}
    
    frame > box {{
        background-color: {NORD["nord0"]};
    }}
    """
    
    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    screen = Gdk.Screen.get_default()
    Gtk.StyleContext.add_provider_for_screen(
        screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )
