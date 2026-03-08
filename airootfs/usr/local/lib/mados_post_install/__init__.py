"""
madOS Post-Installer
Runs on first boot to install user-selected packages
"""

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from .app import PostInstallApp


def main():
    """Main entry point"""
    app = PostInstallApp()
    app.connect("destroy", Gtk.main_quit)
    Gtk.main()
