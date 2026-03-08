"""
madOS Post-Installer - Theme
"""

from gi.repository import Gtk

from .config import NORD


def apply_theme():
    """Apply GTK theme"""
    css = f"""
    * {{
        font-family: 'JetBrains Mono', 'Courier New', monospace;
    }}
    
    window {{
        background-color: {NORD["nord0"]};
        color: {NORD["nord6"]};
    }}
    
    .content-card {{
        background-color: {NORD["nord1"]};
        border-radius: 8px;
        padding: 10px;
        margin: 5px;
    }}
    
    .package-list {{
        background-color: {NORD["nord0"]};
        border: 1px solid {NORD["nord2"]};
        border-radius: 4px;
    }}
    
    .package-list row {{
        padding: 8px;
        border-bottom: 1px solid {NORD["nord2"]};
    }}
    
    .package-list row:last-child {{
        border-bottom: none;
    }}
    
    progressbar {{
        min-height: 25px;
        border-radius: 4px;
    }}
    
    progressbar progress {{
        background-color: {NORD["nord10"]};
        border-radius: 4px;
    }}
    
    progressbar trough {{
        background-color: {NORD["nord2"]};
        border-radius: 4px;
    }}
    
    button {{
        background-color: {NORD["nord3"]};
        color: {NORD["nord6"]};
        border: none;
        padding: 10px 24px;
        border-radius: 4px;
        font-weight: bold;
    }}
    
    button:hover {{
        background-color: {NORD["nord4"]};
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
        color: {NORD["nord4"]};
    }}
    
    textview {{
        background-color: {NORD["nord0"]};
        color: {NORD["nord5"]};
    }}
    """
    
    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    screen = Gdk.Screen.get_default()
    Gtk.StyleContext.add_provider_for_screen(
        screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )


from gi.repository import Gdk
