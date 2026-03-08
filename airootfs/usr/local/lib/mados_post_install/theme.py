"""
madOS Post-Installer - Theme
"""

from gi.repository import Gtk

from .config import NORD


def apply_theme():
    """Apply GTK theme - Modern compact design"""
    css = f"""
    * {{
        font-family: 'JetBrains Mono', 'Courier New', monospace;
        font-size: 10px;
    }}
    
    window {{
        background-color: {NORD["nord0"]};
        color: {NORD["nord6"]};
    }}
    
    .content-card {{
        background-color: {NORD["nord1"]};
        border: 1px solid {NORD["nord2"]};
        border-radius: 6px;
        padding: 8px;
        margin: 3px;
    }}
    
    .package-list {{
        background-color: {NORD["nord0"]};
        border: 1px solid {NORD["nord3"]};
        border-radius: 4px;
    }}
    
    .package-list row {{
        padding: 4px 6px;
        border-bottom: 1px solid {NORD["nord2"]};
        background: transparent;
    }}
    
    .package-list row:hover {{
        background-color: {NORD["nord1"]};
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
        background: linear-gradient(90deg, {NORD["nord10"]}, #88B076);
        border-radius: 4px;
    }}
    
    progressbar trough {{
        background-color: {NORD["nord2"]};
        border-radius: 4px;
    }}
    
    progressbar text {{
        color: {NORD["nord6"]};
        font-weight: bold;
    }}
    
    button {{
        background: linear-gradient(180deg, {NORD["nord3"]}, {NORD["nord2"]});
        color: {NORD["nord6"]};
        border: 1px solid {NORD["nord4"]};
        padding: 8px 28px;
        border-radius: 5px;
        font-weight: bold;
        font-size: 11px;
    }}
    
    button:hover {{
        background: linear-gradient(180deg, {NORD["nord4"]}, {NORD["nord3"]});
        color: {NORD["nord0"]};
    }}
    
    button:active {{
        background: {NORD["nord9"]};
    }}
    
    .success-button {{
        background: linear-gradient(180deg, {NORD["nord10"]}, #88B076);
        color: {NORD["nord0"]};
        border: 1px solid #7FA374;
    }}
    
    .success-button:hover {{
        background: linear-gradient(180deg, #88B076, #94C084);
    }}
    
    .success-button:active {{
        background: {NORD["nord10"]};
    }}
    
    button:disabled {{
        background-color: {NORD["nord2"]};
        color: {NORD["nord4"]};
        border-color: {NORD["nord3"]};
    }}
    
    textview {{
        background-color: {NORD["nord0"]};
        color: {NORD["nord5"]};
        border: 1px solid {NORD["nord2"]};
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
        background-color: {NORD["nord3"]};
        border-radius: 3px;
    }}
    
    scrollbar slider:hover {{
        background-color: {NORD["nord4"]};
    }}
    """
    
    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    screen = Gdk.Screen.get_default()
    Gtk.StyleContext.add_provider_for_screen(
        screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )


from gi.repository import Gdk
