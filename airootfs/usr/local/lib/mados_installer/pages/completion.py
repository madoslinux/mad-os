"""
madOS Installer - Completion page
"""

import json
import os
import subprocess
from pathlib import Path

from gi.repository import Gtk

from ..config import DEMO_MODE, NORD_AURORA, NORD_POLAR_NIGHT


def _save_package_selection(app):
    """Save package selection to config file for post-install"""
    try:
        if hasattr(app, 'package_selection') and app.package_selection:
            config_dir = Path("/mnt/home/mados/.config/mados")
            if not DEMO_MODE:
                config_dir.mkdir(parents=True, exist_ok=True)
            
            config_file = config_dir / "package-selection.json"
            data = {
                "packages": app.package_selection,
                "timestamp": "post-install"
            }
            
            if DEMO_MODE:
                print(f"[DEMO] Would save package selection to {config_file}")
                print(f"[DEMO] Packages: {app.package_selection}")
            else:
                with open(config_file, 'w') as f:
                    json.dump(data, f, indent=2)
                print(f"Saved package selection to {config_file}")
    except Exception as e:
        print(f"Error saving package selection: {e}")


def create_completion_page(app):
    """Completion page with success message and reboot/exit buttons"""
    page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    page.get_style_context().add_class("page-container")

    # Save package selection for post-install
    _save_package_selection(app)

    content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    content.set_halign(Gtk.Align.FILL)
    content.set_valign(Gtk.Align.CENTER)
    content.set_hexpand(True)
    content.set_margin_start(30)
    content.set_margin_end(30)
    content.set_margin_top(10)
    content.set_margin_bottom(14)

    # Big success checkmark
    icon = Gtk.Label()
    icon.set_markup(
        f'<span size="40000" weight="bold" foreground="{NORD_AURORA["nord14"]}">&#x2713;</span>'
    )
    icon.set_halign(Gtk.Align.CENTER)
    icon.set_margin_bottom(8)
    content.pack_start(icon, False, False, 0)

    # Title
    title = Gtk.Label()
    title.set_markup(f'<span size="16000" weight="bold">{app.t("success_title")}</span>')
    title.set_halign(Gtk.Align.CENTER)
    title.set_margin_bottom(10)
    content.pack_start(title, False, False, 0)

    # Info card
    info_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    info_card.get_style_context().add_class("completion-card")
    info_card.set_hexpand(True)

    if DEMO_MODE:
        info = Gtk.Label()
        info.set_markup(
            '<span size="9000">This was a <b>DEMONSTRATION</b> of the madOS installer.\n\n'
            "In real mode (DEMO_MODE = False):\n"
            "  • System would be installed to disk\n"
            "  • All configurations would be applied\n"
            "  • System would be ready to boot\n\n"
            "<b>Edit config.py and set DEMO_MODE = False\n"
            "for real installation.</b></span>"
        )
    else:
        info = Gtk.Label()
        info.set_markup(f'<span size="9000">{app.t("success_msg")}</span>')

    info.set_justify(Gtk.Justification.LEFT)
    info.set_line_wrap(True)
    info_card.pack_start(info, False, False, 0)
    content.pack_start(info_card, False, False, 0)

    # Buttons
    btn_box = Gtk.Box(spacing=12)
    btn_box.set_halign(Gtk.Align.CENTER)
    btn_box.set_margin_top(14)

    if not DEMO_MODE:
        reboot_btn = Gtk.Button(label=app.t("reboot_now"))
        reboot_btn.get_style_context().add_class("success-button")
        reboot_btn.connect("clicked", lambda x: subprocess.run(["reboot"]))
        btn_box.pack_start(reboot_btn, False, False, 0)

    exit_btn = Gtk.Button(label=app.t("exit_live"))
    exit_btn.get_style_context().add_class("nav-back-button")
    exit_btn.connect("clicked", lambda x: Gtk.main_quit())
    btn_box.pack_start(exit_btn, False, False, 0)

    content.pack_start(btn_box, False, False, 0)
    page.pack_start(content, True, False, 0)
    app.notebook.append_page(page, Gtk.Label(label="Complete"))
