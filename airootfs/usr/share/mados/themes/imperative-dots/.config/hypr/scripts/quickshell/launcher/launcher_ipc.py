#!/usr/bin/env python3

import json
import os
import socket
from pathlib import Path
from typing import Any

DAEMON_SOCKET_PATH = Path.home() / ".cache/quickshell/launcher/daemon.sock"
SOCKET_TIMEOUT = 2.0


def _send_command(command: dict[str, str]) -> dict[str, Any]:
    if DAEMON_SOCKET_PATH.exists():
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.settimeout(SOCKET_TIMEOUT)
            sock.connect(str(DAEMON_SOCKET_PATH))
            sock.sendall((json.dumps(command) + "\n").encode("utf-8"))
            data = b""
            while True:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                data += chunk
                if b"\n" in data:
                    break
            sock.close()
            if data:
                return json.loads(data.decode("utf-8").strip())
        except Exception:
            pass
    return {"status": "error", "msg": "Daemon not available"}


def get_apps() -> list[dict]:
    result = _send_command({"cmd": "GET_APPS"})
    if result.get("status") == "ok":
        return result.get("apps", [])
    return []


def reload_cache() -> bool:
    result = _send_command({"cmd": "RELOAD"})
    return result.get("status") == "ok"


def ping_daemon() -> bool:
    result = _send_command({"cmd": "PING"})
    return result.get("status") == "ok"


def is_daemon_running() -> bool:
    return ping_daemon()


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: launcher_ipc.py <get_apps|reload|ping>")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "get_apps":
        apps = get_apps()
        print(json.dumps(apps, ensure_ascii=False))
    elif cmd == "reload":
        success = reload_cache()
        print("OK" if success else "FAILED")
    elif cmd == "ping":
        print("OK" if ping_daemon() else "FAILED")
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
