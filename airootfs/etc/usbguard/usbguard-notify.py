#!/usr/bin/env python3
# shellcheck disable=SC1090
# noqa: SC1036,SC1088
import sys
import subprocess
import threading

def show_dialog(device_info):
    try:
        result = subprocess.run([
            "zenity", "--question",
            "--title=USB Detectado",
            "--text=" + device_info,
            "--ok-label=Aprobar",
            "--cancel-label=Bloquear",
            "--width=400"
        ], capture_output=True)
        
        if result.returncode == 0:
            # User clicked Approve
            subprocess.run(["sudo", "-n", "usbguard", "allow-device", device_id], timeout=5)
            notify("USB Aprobado", device_info)
        else:
            # User clicked Block
            subprocess.run(["sudo", "-n", "usbguard", "block-device", device_id], timeout=5)
            notify("USB Bloqueado", device_info)
    except Exception as e:
        notify("USB Detectado", device_info + "\n(Error: {})".format(e))

def notify(title, text):
    subprocess.run([
        "notify-send", "-u", "normal", title, text
    ])

if __name__ == "__main__":
    device_id = sys.argv[1] if len(sys.argv) > 1 else ""
    action = sys.argv[2] if len(sys.argv) > 2 else ""
    
    if action in ["insert", "present"]:
        info = subprocess.run(
            ["usbguard", "list-devices", "-d"],
            capture_output=True, text=True
        )
        device_info = info.stdout.strip()
        
        if device_id:
            threading.Thread(target=show_dialog, args=("Dispositivo USB conectado:\n\n{}".format(device_info),), daemon=True).start()