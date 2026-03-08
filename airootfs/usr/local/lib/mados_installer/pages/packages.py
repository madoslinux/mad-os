"""
madOS Installer - Package Selection Page with Tabs

Only includes packages from official Arch Linux repositories.
AUR packages and external installs are documented separately.
"""

from gi.repository import Gtk

from .base import create_page_header, create_nav_buttons
from ..config import NORD_SNOW_STORM, NORD_FROST

# Package groups - OFFICIAL ARCH REPOS ONLY
PACKAGE_GROUPS = {
    "dev_tools": {
        "name_key": "pkg_dev_tools",
        "desc_key": "pkg_dev_tools",
        "short_name": "Dev",
        "packages": [
            {"id": "base-devel", "name": "Base Development Tools", "default": True},
            {"id": "git", "name": "Git", "default": True},
            {"id": "neovim", "name": "Neovim", "default": False},
            {"id": "nano", "name": "Nano editor", "default": False},
            {"id": "docker", "name": "Docker", "default": False},
            {"id": "podman", "name": "Podman", "default": False},
            {"id": "ansible", "name": "Ansible", "default": False},
            {"id": "cmake", "name": "CMake", "default": False},
            {"id": "make", "name": "GNU Make", "default": False},
        ],
    },
    "ai_ml": {
        "name_key": "pkg_ai_ml",
        "desc_key": "pkg_ai_ml",
        "short_name": "AI/ML",
        "packages": [
            {"id": "python", "name": "Python 3", "default": True},
            {"id": "python-pip", "name": "Python pip", "default": True},
            {"id": "ollama", "name": "Ollama (AI models)", "default": True},
            {"id": "opencode", "name": "OpenCode AI Assistant", "default": True},
            {"id": "python-jupyterlab", "name": "JupyterLab", "default": False},
            {"id": "python-scikit-learn", "name": "Scikit-learn", "default": False},
            {"id": "python-matplotlib", "name": "Matplotlib", "default": False},
            {"id": "python-numpy", "name": "NumPy", "default": False},
            {"id": "python-pandas", "name": "Pandas", "default": False},
        ],
    },
    "multimedia": {
        "name_key": "pkg_multimedia",
        "desc_key": "pkg_multimedia",
        "short_name": "Media",
        "packages": [
            {"id": "gimp", "name": "GIMP (Image Editor)", "default": False},
            {"id": "inkscape", "name": "Inkscape (Vector)", "default": False},
            {"id": "krita", "name": "Krita (Digital Painting)", "default": False},
            {"id": "blender", "name": "Blender (3D)", "default": False},
            {"id": "audacity", "name": "Audacity (Audio)", "default": False},
            {"id": "lmms", "name": "LMMS (Music)", "default": False},
            {"id": "vlc", "name": "VLC Media Player", "default": True},
            {"id": "ffmpeg", "name": "FFmpeg", "default": True},
        ],
    },
    "office": {
        "name_key": "pkg_office",
        "desc_key": "pkg_office",
        "short_name": "Office",
        "packages": [
            {"id": "libreoffice-fresh", "name": "LibreOffice", "default": True},
            {"id": "evince", "name": "Evince (PDF Viewer)", "default": True},
            {"id": "thunderbird", "name": "Thunderbird (Email)", "default": False},
            {"id": "geary", "name": "Geary (Email)", "default": False},
            {"id": "calibre", "name": "Calibre (E-books)", "default": False},
        ],
    },
    "internet": {
        "name_key": "pkg_internet",
        "desc_key": "pkg_internet",
        "short_name": "Web",
        "packages": [
            {"id": "firefox", "name": "Firefox", "default": True},
            {"id": "chromium", "name": "Chromium", "default": False},
            {"id": "qbittorrent", "name": "qBittorrent", "default": False},
            {"id": "transmission-gtk", "name": "Transmission", "default": False},
            {"id": "telegram-desktop", "name": "Telegram Desktop", "default": False},
        ],
    },
}


class PackageSelectionPage(Gtk.Box):
    """Package selection page with tabbed interface."""

    def __init__(self, app, parent_box):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.app = app
        self.parent_box = parent_box
        
        self.selected_packages = set()
        self.tab_checkboxes = {}
        
        self._build_ui()
    
    def _build_ui(self):
        """Build the package selection UI with tabs."""
        header = create_page_header(
            self.app, 
            self.app.t("pkg_select_title"), 
            step_num=5, 
            total_steps=8
        )
        self.pack_start(header, False, False, 0)
        
        desc_label = Gtk.Label()
        desc_label.set_markup(
            f'<span size="10000" foreground="{NORD_SNOW_STORM["nord5"]}">'
            f'{self.app.t("pkg_select_desc")}'
            "</span>"
        )
        desc_label.set_line_wrap(True)
        desc_label.set_halign(Gtk.Align.CENTER)
        desc_label.set_margin_start(20)
        desc_label.set_margin_end(20)
        desc_label.set_margin_top(10)
        desc_label.set_margin_bottom(10)
        self.pack_start(desc_label, False, False, 0)
        
        notebook = Gtk.Notebook()
        notebook.set_tab_pos(Gtk.PositionType.TOP)
        notebook.set_margin_start(20)
        notebook.set_margin_end(20)
        notebook.set_margin_bottom(10)
        self.pack_start(notebook, True, True, 0)
        
        for group_id, group_data in PACKAGE_GROUPS.items():
            tab_label_text = group_data["short_name"]
            tab_page = self._create_tab_content(group_id, group_data)
            tab_label = Gtk.Label(label=tab_label_text)
            tab_label.set_size_request(80, 25)
            notebook.append_page(tab_page, tab_label)
        
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
        self.pack_start(nav_box, False, False, 0)
        
        self._apply_defaults()
    
    def _create_tab_content(self, group_id, group_data):
        """Create content for a package group tab."""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.set_margin_top(10)
        box.set_margin_bottom(10)
        box.set_margin_start(15)
        box.set_margin_end(15)
        scrolled.add(box)
        
        desc_label = Gtk.Label()
        desc_label.set_markup(
            f'<span size="9000">{self.app.t(group_data["desc_key"])}</span>'
        )
        desc_label.set_line_wrap(True)
        desc_label.set_halign(Gtk.Align.START)
        desc_label.set_margin_bottom(10)
        box.pack_start(desc_label, False, False, 0)
        
        self.tab_checkboxes[group_id] = {}
        for pkg in group_data["packages"]:
            checkbox = Gtk.CheckButton(label=pkg["name"])
            checkbox.set_active(pkg["default"])
            checkbox.set_margin_start(10)
            checkbox.set_margin_top(2)
            checkbox.set_margin_bottom(2)
            box.pack_start(checkbox, False, False, 0)
            self.tab_checkboxes[group_id][pkg["id"]] = checkbox
        
        return scrolled
    
    def _apply_defaults(self):
        self._update_selection()
    
    def _update_selection(self):
        self.selected_packages.clear()
        for group_id, checkboxes in self.tab_checkboxes.items():
            for pkg_id, checkbox in checkboxes.items():
                if checkbox.get_active():
                    self.selected_packages.add(pkg_id)
    
    def _on_back(self, button):
        self._update_selection()
        self.app.notebook.prev_page()
    
    def _on_next(self, button):
        self._update_selection()
        self.app.package_selection = sorted(list(self.selected_packages))
        self.app.show_page("summary")
    
    def get_selected_summary(self):
        self._update_selection()
        
        if not self.selected_packages:
            return self.app.t("pkg_no_selection")
        
        selected = []
        for group_id, group_data in PACKAGE_GROUPS.items():
            group_selected = [
                pkg["name"] for pkg in group_data["packages"]
                if pkg["id"] in self.selected_packages
            ]
            if group_selected:
                selected.append(f"{group_data['short_name']}: {len(group_selected)}")
        
        return "\n".join(selected) if selected else "No additional packages"


def create_package_selection_page(app, parent_box):
    """Create and register the package selection page."""
    page = PackageSelectionPage(app, parent_box)
    app.notebook.append_page(page, Gtk.Label(label=app.t("pkg_select_title")))
    return page
