"""
madOS Post-Installer - Main application window
"""

import os
import random
import subprocess
import threading
import time
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

from .config import DEMO_MODE, NORD, PACKAGE_GROUPS
from .theme import apply_theme

CONFIG_FILE = "/home/mados/.config/mados/package-selection.json"


class PostInstallApp(Gtk.Window):
    """Post-installation package installer window"""

    def __init__(self):
        title = "madOS - Package Installation" + (" (DEMO MODE)" if DEMO_MODE else "")
        super().__init__(title=title)
        
        self.set_default_size(800, 420)
        self.set_size_request(800, 420)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(False)
        
        apply_theme()
        
        self.packages_to_install = []
        self.installed_count = 0
        self.current_package = ""
        self.installation_log = []
        self.waiting_for_network = False
        
        # Load or setup packages FIRST
        self._load_package_selection()
        
        # In demo mode, use sample packages if no config found
        if not self.packages_to_install and DEMO_MODE:
            self.packages_to_install = [
                "git", "neovim", "python-pip", "docker",
                "python-jupyterlab", "python-scikit-learn",
                "gimp", "blender", "vlc", "ffmpeg",
                "libreoffice-fresh", "evince",
                "firefox", "qbittorrent"
            ]
            print(f"[DEMO] Using sample package list: {len(self.packages_to_install)} official packages")
        
        # Build UI with packages already set
        self._build_ui()
        self.show_all()
        
        # Check network before starting
        if self.packages_to_install:
            print(f"[INFO] Checking network connectivity...")
            GLib.idle_add(self._check_network_and_start)
    
    def _load_package_selection(self):
        """Load package selection from config file"""
        try:
            if os.path.exists(CONFIG_FILE):
                import json
                with open(CONFIG_FILE, 'r') as f:
                    data = json.load(f)
                    self.packages_to_install = data.get('packages', [])
                    self.log(f"Loaded {len(self.packages_to_install)} packages to install")
            else:
                self.log("No package selection file found")
        except Exception as e:
            self.log(f"Error loading config: {e}")
            self.packages_to_install = []
    
    def _build_ui(self):
        """Build the UI - Ultra compact for 1024x600 screens (420px height)"""
        # Main container - minimal margins
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_box.set_margin_start(15)
        main_box.set_margin_end(15)
        main_box.set_margin_top(10)
        main_box.set_margin_bottom(10)
        self.add(main_box)
        
        # Header - minimal
        header = Gtk.Label()
        header.set_markup('<span size="12000" weight="bold">Installing Packages</span>')
        header.set_halign(Gtk.Align.CENTER)
        header.set_margin_bottom(3)
        main_box.pack_start(header, False, False, 0)
        
        subtitle = Gtk.Label()
        subtitle.set_markup(f'<span size="8500" foreground="{NORD["nord4"]}">From madOS installer</span>')
        subtitle.set_halign(Gtk.Align.CENTER)
        subtitle.set_margin_bottom(8)
        main_box.pack_start(subtitle, False, False, 0)
        
        # Packages section - very compact
        packages_frame = Gtk.Frame()
        packages_frame.get_style_context().add_class("content-card")
        packages_frame.set_margin_bottom(6)
        main_box.pack_start(packages_frame, False, False, 0)
        
        packages_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        packages_box.set_margin_top(6)
        packages_box.set_margin_bottom(6)
        packages_box.set_margin_start(8)
        packages_box.set_margin_end(8)
        packages_frame.add(packages_box)
        
        packages_label = Gtk.Label()
        packages_label.set_markup(f'<span size="9000" weight="bold">Packages ({len(self.packages_to_install)})</span>')
        packages_label.set_halign(Gtk.Align.START)
        packages_box.pack_start(packages_label, False, False, 2)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(100)
        scroll.set_max_content_height(100)
        packages_box.pack_start(scroll, False, False, 0)
        
        self.packages_list = Gtk.ListBox()
        self.packages_list.get_style_context().add_class("package-list")
        self.packages_list.set_selection_mode(Gtk.SelectionMode.NONE)
        scroll.add(self.packages_list)
        
        # Store adjustment for scrolling
        self.packages_scroll_adj = scroll.get_vadjustment()
        
        self._populate_packages_list()
        
        # Progress section - minimal
        progress_frame = Gtk.Frame()
        progress_frame.get_style_context().add_class("content-card")
        progress_frame.set_margin_bottom(6)
        main_box.pack_start(progress_frame, False, False, 0)
        
        progress_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        progress_box.set_margin_top(6)
        progress_box.set_margin_bottom(6)
        progress_box.set_margin_start(8)
        progress_box.set_margin_end(8)
        progress_frame.add(progress_box)
        
        self.status_label = Gtk.Label()
        self.status_label.set_markup(f'<span size="9000">Installing {len(self.packages_to_install)} packages</span>')
        self.status_label.set_halign(Gtk.Align.CENTER)
        progress_box.pack_start(self.status_label, False, False, 0)
        
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_show_text(True)
        progress_box.pack_start(self.progress_bar, False, False, 0)
        
        # Log section - minimal
        log_frame = Gtk.Frame()
        log_frame.get_style_context().add_class("content-card")
        log_frame.set_margin_bottom(6)
        main_box.pack_start(log_frame, False, False, 0)
        
        log_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        log_box.set_margin_top(4)
        log_box.set_margin_bottom(4)
        log_box.set_margin_start(8)
        log_box.set_margin_end(8)
        log_frame.add(log_box)
        
        log_label = Gtk.Label()
        log_label.set_markup(f'<span size="8500" weight="bold">Log</span>')
        log_label.set_halign(Gtk.Align.START)
        log_box.pack_start(log_label, False, False, 0)
        
        log_scroll = Gtk.ScrolledWindow()
        log_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        log_scroll.set_min_content_height(60)
        log_scroll.set_max_content_height(60)
        log_box.pack_start(log_scroll, True, True, 0)
        
        self.log_view = Gtk.TextView()
        self.log_view.set_editable(False)
        self.log_view.set_monospace(True)
        self.log_view.set_size_request(-1, 60)
        self.log_buffer = self.log_view.get_buffer()
        log_scroll.add(self.log_view)
        
        # Action button
        self.action_box = Gtk.Box(spacing=8)
        self.action_box.set_halign(Gtk.Align.CENTER)
        self.action_box.set_margin_top(3)
        main_box.pack_start(self.action_box, False, False, 0)
        
        self.close_button = Gtk.Button(label="  Close  ")
        self.close_button.get_style_context().add_class("success-button")
        self.close_button.set_sensitive(False)
        self.close_button.connect("clicked", lambda x: Gtk.main_quit())
        self.action_box.pack_start(self.close_button, False, False, 0)
    
    def _populate_packages_list(self):
        """Populate the packages list"""
        # Clear existing items
        for child in self.packages_list.get_children():
            self.packages_list.remove(child)
        
        if not self.packages_to_install:
            label = Gtk.Label()
            label.set_markup('<span size="11000" style="italic">No packages selected for installation</span>')
            label.set_margin_top(10)
            label.set_margin_bottom(10)
            self.packages_list.add(label)
            return
        
        for pkg in self.packages_to_install:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            row.set_margin_start(3)
            row.set_margin_end(3)
            row.set_margin_top(1)
            row.set_margin_bottom(1)
            
            pkg_name = Gtk.Label()
            pkg_name.set_markup(f'<span size="8500">{pkg}</span>')
            pkg_name.set_halign(Gtk.Align.START)
            pkg_name.set_ellipsize(3)
            row.pack_start(pkg_name, True, True, 0)
            
            status = Gtk.Label()
            status.set_markup(f'<span size="8500" foreground="{NORD["nord5"]}">Pending</span>')
            status.set_name(f"status-{pkg}")
            status.set_margin_end(3)
            row.pack_start(status, False, False, 0)
            
            self.packages_list.add(row)
    
    def _check_network_and_start(self):
        """Check network connectivity before starting installation"""
        if DEMO_MODE:
            GLib.idle_add(self._start_installation)
            return False
        
        self.waiting_for_network = True
        self._update_status("Waiting for internet connection...", 0, len(self.packages_to_install))
        self.log("Waiting for network connectivity...")
        
        # Start network check thread
        threading.Thread(target=self._wait_for_network, daemon=True).start()
        return False
    
    def _wait_for_network(self):
        """Wait for internet connection with timeout"""
        import socket
        
        max_attempts = 60  # Wait up to 5 minutes
        attempt = 0
        
        while attempt < max_attempts:
            try:
                # Try to connect to a reliable server
                socket.create_connection(("8.8.8.8", 53), timeout=5)
                self.log("Network connection detected!")
                GLib.idle_add(self._start_installation)
                return
            except Exception:
                attempt += 1
                if attempt % 10 == 0:  # Every 10 seconds
                    self.log(f"Waiting for network... (attempt {attempt}/{max_attempts})")
                time.sleep(1)
        
        # Timeout - show error
        self.log("ERROR: No network connection after 5 minutes")
        GLib.idle_add(self._installation_error, "No internet connection. Please check your network and try again.")
    
    def _start_installation(self):
        """Start installation in background thread"""
        self.waiting_for_network = False
        threading.Thread(target=self._install_packages, daemon=True).start()
        return False
    
    def _install_packages(self):
        """Install packages in background"""
        if not self.packages_to_install:
            GLib.idle_add(self._installation_complete)
            return
        
        try:
            self.log("Starting package installation...")
            
            for i, package in enumerate(self.packages_to_install):
                self.current_package = package
                GLib.idle_add(self._update_status, f"Installing {package}...", i, len(self.packages_to_install))
                
                if DEMO_MODE:
                    # Demo mode: simulate installation with delays
                    self.log(f"[DEMO] Would install: {package}")
                    import random
                    time.sleep(0.5 + random.random() * 0.5)
                    self.log(f"[DEMO] ✓ {package} installed successfully (simulated)")
                    GLib.idle_add(self._mark_package_installed, package)
                elif package == "ollama":
                    # Install Ollama via curl
                    self.log(f"Installing {package} via curl...")
                    result = subprocess.run(
                        "curl -fsSL https://ollama.com/install.sh | sh",
                        shell=True,
                        capture_output=True,
                        text=True
                    )
                    
                    if result.returncode == 0:
                        self.log(f"✓ {package} installed successfully")
                        GLib.idle_add(self._mark_package_installed, package)
                    else:
                        self.log(f"✗ Failed to install {package}: {result.stderr}")
                        GLib.idle_add(self._mark_package_failed, package)
                elif package == "opencode":
                    # Install OpenCode via curl
                    self.log(f"Installing {package} via curl...")
                    result = subprocess.run(
                        "curl -fsSL https://opencode.ai/install | bash",
                        shell=True,
                        capture_output=True,
                        text=True
                    )
                    
                    if result.returncode == 0:
                        self.log(f"✓ {package} installed successfully")
                        GLib.idle_add(self._mark_package_installed, package)
                    else:
                        self.log(f"✗ Failed to install {package}: {result.stderr}")
                        GLib.idle_add(self._mark_package_failed, package)
                else:
                    # Real mode: install via pacman
                    self.log(f"Installing: {package}")
                    result = subprocess.run(
                        ["pacman", "-S", "--noconfirm", package],
                        capture_output=True,
                        text=True
                    )
                    
                    if result.returncode == 0:
                        self.log(f"✓ {package} installed successfully")
                        GLib.idle_add(self._mark_package_installed, package)
                    else:
                        self.log(f"✗ Failed to install {package}: {result.stderr}")
                        GLib.idle_add(self._mark_package_failed, package)
                
                self.installed_count = i + 1
                GLib.idle_add(self._update_status, f"Installing...", self.installed_count, len(self.packages_to_install))
            
            GLib.idle_add(self._installation_complete)
            
        except Exception as e:
            self.log(f"Error during installation: {e}")
            GLib.idle_add(self._installation_error, str(e))
    
    def _update_status(self, status_text, current, total):
        """Update status label and progress bar"""
        self.status_label.set_markup(f'<span size="11000">{status_text}</span>')
        progress = current / total
        self.progress_bar.set_fraction(progress)
        self.progress_bar.set_text(f"{current}/{total} ({progress*100:.0f}%)")
    
    def _mark_package_installed(self, package):
        """Mark package as installed in the list and scroll to it"""
        row = self._find_package_row(package)
        if row:
            for child in row.get_children():
                if isinstance(child, Gtk.Box):
                    for widget in child.get_children():
                        if isinstance(widget, Gtk.Label) and widget.get_name() == f"status-{package}":
                            widget.set_markup(f'<span size="8500" foreground="{NORD["nord10"]}">✓ Installed</span>')
            
            # Scroll packages list to show updated row (in UI thread)
            GLib.idle_add(self._scroll_packages_to_row, row)
    
    def _scroll_packages_to_row(self, row):
        """Scroll the packages list to show the given row"""
        try:
            if row and self.packages_scroll_adj:
                # Get the index of the row
                index = 0
                current_row = self.packages_list.get_row_at_index(0)
                while current_row and current_row != row:
                    index += 1
                    current_row = self.packages_list.get_row_at_index(index)
                
                if current_row:
                    # Scroll smoothly to show this row in the middle
                    row_height = 28  # Approximate row height in pixels
                    target = max(0, (index * row_height) - 50)
                    max_scroll = self.packages_scroll_adj.get_upper() - self.packages_scroll_adj.get_page_size()
                    self.packages_scroll_adj.set_value(min(target, max_scroll))
        except Exception as e:
            print(f"Scroll error: {e}")
    
    def _mark_package_failed(self, package):
        """Mark package as failed in the list"""
        row = self._find_package_row(package)
        if row:
            for child in row.get_children():
                if isinstance(child, Gtk.Box):
                    for widget in child.get_children():
                        if isinstance(widget, Gtk.Label) and widget.get_name() == f"status-{package}":
                            widget.set_markup(f'<span size="10000" foreground="{NORD["nord11"]}">✗ Failed</span>')
    
    def _find_package_row(self, package):
        """Find the row for a package"""
        row = self.packages_list.get_row_at_index(0)
        index = 0
        while row:
            for child in row.get_children():
                if isinstance(child, Gtk.Box):
                    for widget in child.get_children():
                        if isinstance(widget, Gtk.Label) and widget.get_name() == f"status-{package}":
                            return row
            index += 1
            row = self.packages_list.get_row_at_index(index)
        return None
    
    def _installation_complete(self):
        """Called when installation is complete"""
        if DEMO_MODE:
            self.status_label.set_markup(f'<span size="12000" weight="bold" foreground="{NORD["nord10"]}">✓ Demo Installation Complete!</span>')
            self.log("[DEMO] Simulation completed successfully!")
            self.log("[DEMO] In real mode, packages would be installed via pacman")
        else:
            self.status_label.set_markup(f'<span size="12000" weight="bold" foreground="{NORD["nord10"]}">Installation Complete!</span>')
            self.log("Installation completed successfully!")
        
        self.progress_bar.set_fraction(1.0)
        self.progress_bar.set_text("100%")
        self.log("Running cleanup...")
        self._run_cleanup()
        self.close_button.set_sensitive(True)
    
    def _run_cleanup(self):
        """Run cleanup script to disable post-install service"""
        if DEMO_MODE:
            self.log("[DEMO] Would run cleanup script")
            self.log("[DEMO] Service would be disabled for future boots")
            return
        
        try:
            subprocess.run(
                ["/usr/local/bin/mados-post-install-cleanup"],
                capture_output=True,
                text=True,
                timeout=10
            )
            self.log("Post-install service disabled for future boots")
        except Exception as e:
            self.log(f"Cleanup warning: {e}")
    
    def _installation_error(self, error_msg):
        """Called when there's an error"""
        self.status_label.set_markup(f'<span size="12000" weight="bold" foreground="{NORD["nord11"]}">Installation Error</span>')
        self.log(f"ERROR: {error_msg}")
        self.close_button.set_sensitive(True)
    
    def log(self, message):
        """Add message to log"""
        self.installation_log.append(message)
        GLib.idle_add(self._update_log, message)
    
    def _update_log(self, message):
        """Update log view and auto-scroll"""
        end_iter = self.log_buffer.get_end_iter()
        self.log_buffer.insert(end_iter, f"{message}\n")
        # Auto-scroll to bottom
        self.log_view.scroll_to_mark(self.log_buffer.get_insert(), 0, True, 0.5, 0.5)
