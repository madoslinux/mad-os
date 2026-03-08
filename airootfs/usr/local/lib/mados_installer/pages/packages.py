"""
madOS Installer - Package Selection Page with Tabs

Allows users to select optional package groups by category.
"""

import os
from gi.repository import Gtk

from .base import create_page_header, create_nav_buttons
from ..config import NORD_SNOW_STORM, NORD_FROST, NORD_POLAR_NIGHT, NORD_AURORA

# Package groups organized by tabs
PACKAGE_GROUPS = {
    "dev_tools": {
        "name_key": "pkg_dev_tools",
        "desc_key": "pkg_dev_tools_desc",
        "icon": "🛠️",
        "packages": [
            {"id": "base-devel", "name": "Base Development Tools", "default": True},
            {"id": "git", "name": "Git", "default": True},
            {"id": "code", "name": "Visual Studio Code", "default": False},
            {"id": "neovim", "name": "Neovim", "default": False},
            {"id": "docker", "name": "Docker & Docker Compose", "default": False},
            {"id": "podman", "name": "Podman", "default": False},
            {"id": "terraform", "name": "Terraform", "default": False},
            {"id": "ansible", "name": "Ansible", "default": False},
            {"id": "kubectl", "name": "Kubernetes CLI", "default": False},
        ],
    },
    "ai_ml": {
        "name_key": "pkg_ai_ml",
        "desc_key": "pkg_ai_ml_desc",
        "icon": "🤖",
        "packages": [
            {"id": "ollama", "name": "Ollama", "default": False},
            {"id": "opencode", "name": "OpenCode", "default": False},
            {"id": "python-transformers", "name": "HuggingFace Transformers", "default": False},
            {"id": "python-pytorch", "name": "PyTorch", "default": False},
            {"id": "python-tensorflow", "name": "TensorFlow", "default": False},
            {"id": "python-scikit-learn", "name": "Scikit-learn", "default": False},
            {"id": "jupyterlab", "name": "JupyterLab", "default": False},
            {"id": "python-matplotlib", "name": "Matplotlib", "default": False},
        ],
    },
    "multimedia": {
        "name_key": "pkg_multimedia",
        "desc_key": "pkg_multimedia_desc",
        "icon": "🎨",
        "packages": [
            {"id": "kdenlive", "name": "Kdenlive (Video Editor)", "default": False},
            {"id": "obs-studio", "name": "OBS Studio", "default": False},
            {"id": "blender", "name": "Blender (3D)", "default": False},
            {"id": "gimp", "name": "GIMP (Image Editor)", "default": False},
            {"id": "inkscape", "name": "Inkscape (Vector)", "default": False},
            {"id": "krita", "name": "Krita (Digital Painting)", "default": False},
            {"id": "darktable", "name": "Darktable (RAW Photo)", "default": False},
            {"id": "ardour", "name": "Ardour (Audio DAW)", "default": False},
            {"id": "audacity", "name": "Audacity", "default": False},
            {"id": "lmms", "name": "LMMS (Music Production)", "default": False},
        ],
    },
    "office": {
        "name_key": "pkg_office",
        "desc_key": "pkg_office_desc",
        "icon": "📄",
        "packages": [
            {"id": "libreoffice-fresh", "name": "LibreOffice (Office Suite)", "default": False},
            {"id": "onlyoffice", "name": "ONLYOFFICE", "default": False},
            {"id": "evince", "name": "Evince (PDF Viewer)", "default": True},
            {"id": "thunderbird", "name": "Thunderbird (Email)", "default": False},
            {"id": "geary", "name": "Geary (Email)", "default": False},
        ],
    },
    "internet": {
        "name_key": "pkg_internet",
        "desc_key": "pkg_internet_desc",
        "icon": "🌐",
        "packages": [
            {"id": "firefox", "name": "Firefox", "default": False},
            {"id": "chromium", "name": "Chromium", "default": False},
            {"id": "brave-browser", "name": "Brave Browser", "default": False},
            {"id": "transmission-gtk", "name": "Transmission (Torrent)", "default": False},
            {"id": "qbittorrent", "name": "qBittorrent", "default": False},
            {"id": "discord", "name": "Discord", "default": False},
            {"id": "telegram-desktop", "name": "Telegram Desktop", "default": False},
            {"id": "zoom", "name": "Zoom", "default": False},
        ],
    },
}


class PackageSelectionPage(Gtk.Box):
    """Package selection page with tabbed interface."""

    def __init__(self, app, parent_box):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.app = app
        self.parent_box = parent_box
        
        # Store selected packages
        self.selected_packages = set()
        self.tab_checkboxes = {}  # tab_name -> {package_id -> checkbox}
        
        self._build_ui()
    
    def _build_ui(self):
        """Build the package selection UI with tabs."""
        # Header
        header = create_page_header(
            self.app, 
            self.app.t("pkg_select_title"), 
            step_num=5, 
            total_steps=8
        )
        self.pack_start(header, False, False, 0)
        
        # Scrollable content
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_margin_start(20)
        scroll.set_margin_end(20)
        scroll.set_margin_top(10)
        scroll.set_margin_bottom(10)
        self.pack_start(scroll, False, True, 0)
        
        # Main content box
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        content.set_margin_start(20)
        content.set_margin_end(20)
        scroll.add(content)
        
        # Description
        desc_label = Gtk.Label()
        desc_label.set_markup(
            f'<span size="11000" foreground="{NORD_SNOW_STORM["nord5"]}">'
            f'{self.app.t("pkg_select_desc")}'
            "</span>"
        )
        desc_label.set_line_wrap(True)
        desc_label.set_halign(Gtk.Align.CENTER)
        content.pack_start(desc_label, False, False, 0)
        
        # Create tabs
        notebook = Gtk.Notebook()
        notebook.set_tab_pos(Gtk.PositionType.TOP)
        content.pack_start(notebook, True, True, 8)
        
        # Add tab for each category
        for group_id, group_data in PACKAGE_GROUPS.items():
            tab_label = f'{group_data["icon"]}  {self.app.t(group_data["name_key"])}'
            tab_page = self._create_tab_content(group_id, group_data)
            notebook.append_page(tab_page, Gtk.Label(label=tab_label))
        
        # Navigation buttons
        nav_box = create_nav_buttons(
            self.app,
            self._on_back,
            self._on_next,
            next_label=self.app.t("next"),
            next_class="success-button",
        )
        nav_box.set_margin_top(10)
        nav_box.set_margin_bottom(20)
        nav_box.set_margin_end(20)
        content.pack_start(nav_box, False, False, 0)
        
        # Initialize with defaults
        self._apply_defaults()
    
    def _create_tab_content(self, group_id, group_data):
        """Create content for a package group tab."""
        frame = Gtk.Frame()
        frame.get_style_context().add_class("package-group-frame")
        frame.set_margin_bottom(8)
        
        # Frame content box
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(12)
        box.set_margin_bottom(12)
        box.set_margin_start(12)
        box.set_margin_end(12)
        frame.add(box)
        
        # Group header
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        header_box.set_margin_bottom(8)
        box.pack_start(header_box, False, False, 0)
        
        icon_label = Gtk.Label()
        icon_label.set_markup(f'<span size="16000">{group_data["icon"]}</span>')
        header_box.pack_start(icon_label, False, False, 0)
        
        name_label = Gtk.Label()
        name_label.set_markup(
            f'<span size="12000" weight="bold" foreground="{NORD_FROST["nord8"]}">'
            f'{self.app.t(group_data["name_key"])}'
            "</span>"
        )
        name_label.set_halign(Gtk.Align.START)
        header_box.pack_start(name_label, False, False, 0)
        
        # Description
        desc_label = Gtk.Label()
        desc_label.set_markup(
            f'<span size="10000" foreground="{NORD_SNOW_STORM["nord4"]}">'
            f'{self.app.t(group_data["desc_key"])}'
            "</span>"
        )
        desc_label.set_line_wrap(True)
        desc_label.set_halign(Gtk.Align.START)
        box.pack_start(desc_label, False, False, 5)
        
        # Packages checklist
        pkg_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        pkg_box.set_margin_top(8)
        pkg_box.set_margin_start(20)
        box.pack_start(pkg_box, False, False, 0)
        
        self.tab_checkboxes[group_id] = {}
        for pkg in group_data["packages"]:
            checkbox = Gtk.CheckButton(label=pkg["name"])
            checkbox.set_active(pkg["default"])
            checkbox.set_margin_start(10)
            pkg_box.pack_start(checkbox, False, False, 0)
            self.tab_checkboxes[group_id][pkg["id"]] = checkbox
        
        return frame
    
    def _apply_defaults(self):
        """Apply default package selections."""
        self._update_selection()
    
    def _update_selection(self):
        """Update the set of selected packages from checkboxes."""
        self.selected_packages.clear()
        for group_id, checkboxes in self.tab_checkboxes.items():
            for pkg_id, checkbox in checkboxes.items():
                if checkbox.get_active():
                    self.selected_packages.add(pkg_id)
    
    def _on_back(self, button):
        """Handle back button"""
        self._update_selection()
        self.app.notebook.prev_page()
    
    def _on_next(self, button):
        """Handle next button"""
        self._update_selection()
        self.app.package_selection = sorted(list(self.selected_packages))
        self.app.show_page("summary")
    
    def get_selected_summary(self):
        """Get human-readable summary of selected packages."""
        self._update_selection()
        
        if not self.selected_packages:
            return self.app.t("pkg_no_selection") if hasattr(self.app, 't') else "No additional packages selected"
        
        selected = []
        for group_id, group_data in PACKAGE_GROUPS.items():
            group_selected = []
            for pkg in group_data["packages"]:
                if pkg["id"] in self.selected_packages:
                    group_selected.append(pkg["name"])
            
            if group_selected:
                selected.append(f"{group_data['icon']} {self.app.t(group_data['name_key'])}: {len(group_selected)} packages")
        
        return "\n".join(selected) if selected else "No additional packages"


def create_package_selection_page(app, parent_box):
    """Create and register the package selection page."""
    page = PackageSelectionPage(app, parent_box)
    app.notebook.append_page(page, Gtk.Label(label=app.t("pkg_select_title")))
    return page
