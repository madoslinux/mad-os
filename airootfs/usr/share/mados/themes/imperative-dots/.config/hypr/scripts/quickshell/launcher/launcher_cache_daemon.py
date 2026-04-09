#!/usr/bin/env python3

import hashlib
import json
import os
import re
import signal
import socket
import sys
import threading
import time
from collections import deque
from configparser import ConfigParser
from pathlib import Path
from typing import Any

try:
    import inotify.adapters

    INOTIFY_AVAILABLE = True
except ImportError:
    INOTIFY_AVAILABLE = False


STEAM_DIR = Path.home() / ".local/share/Steam"
CACHE_DIR = Path.home() / ".cache/quickshell/launcher"
CACHE_FILE = CACHE_DIR / "apps.json"
DAEMON_SOCKET = CACHE_DIR / "daemon.sock"
PID_FILE = CACHE_DIR / "daemon.pid"

DESKTOP_DIRS = [
    Path("/usr/share/applications"),
    Path.home() / ".local/share/applications",
    Path("/var/lib/flatpak/exports/share/applications"),
    Path.home() / ".local/share/flatpak/exports/share/applications",
]

STEAM_APP_MANIFEST_PATHS = [
    STEAM_DIR / "steamapps",
]

ICON_DIRS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons/hicolor"),
    Path("/usr/share/icons/Adwaita"),
    Path("/usr/share/pixmaps"),
    Path("/usr/share/icons"),
]

ICON_SIZES = ["512x512", "256x256", "128x128", "96x96", "64x64", "scalable"]
ICON_EXTENSIONS = [".png", ".svg", ".xpm"]

ICON_THEME_BASE_DIRS = [
    Path.home() / ".icons",
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons"),
]

ENTRY_KEYS = {"Type", "Name", "Exec", "Icon", "Categories", "NoDisplay", "Hidden", "Terminal"}

SKIP_STEAM_NAMES = (
    "proton",
    "redistribut",
    "steamworks",
    "steam linux runtime",
    "wallpaper engine",
    "steamvr",
)

NOISE_CATEGORIES = {
    "Qt",
    "KDE",
    "GNOME",
    "GTK",
    "X-XFCE",
    "X-XFCE-SettingsDialog",
    "X-KDE-Utilities-File",
    "Core",
    "ConsoleOnly",
}

PRIMARY_CATEGORY_ORDER = [
    "Game",
    "Network",
    "AudioVideo",
    "Graphics",
    "Office",
    "Development",
    "Settings",
    "System",
    "Utility",
]

PRETTY_CATEGORY = {
    "AudioVideo": "Media",
    "Audio": "Audio",
    "Video": "Video",
    "Network": "Network",
    "WebBrowser": "Web",
    "Graphics": "Graphics",
    "Photography": "Photo",
    "Office": "Office",
    "Development": "Dev",
    "Building": "Build",
    "Settings": "Settings",
    "System": "System",
    "Monitor": "Monitor",
    "TerminalEmulator": "Terminal",
    "Utility": "Utility",
    "FileManager": "Files",
    "Documentation": "Docs",
    "Player": "Player",
    "Viewer": "Viewer",
    "Archiving": "Archive",
    "Compression": "Archive",
    "HardwareSettings": "Hardware",
    "Engineering": "Engineering",
    "3DGraphics": "3D",
    "Game": "Game",
    "Steam": "Steam",
}

GAME_KEYWORDS = ("game", "steam", "lutris", "heroic", "retroarch", "proton")

FIELD_CODE_PATTERN = re.compile(r"\s+%[fFuUdDnNickvm]")

ICON_THEME_CACHE: dict[str, str] = {}
ICON_THEME_CHAIN_CACHE: list[str] | None = None

_running = True
_reload_event = threading.Event()


def parse_bool(value: str) -> bool:
    return str(value).strip().lower() == "true"


def clean_exec(exec_line: str) -> str:
    return FIELD_CODE_PATTERN.sub("", exec_line).strip()


def preferred_icon_theme_name() -> str:
    env_theme = os.environ.get("GTK_ICON_THEME", "").strip()
    if env_theme:
        return env_theme
    settings_file = Path.home() / ".config/gtk-3.0/settings.ini"
    if settings_file.is_file():
        parser = ConfigParser(interpolation=None)
        try:
            parser.read(settings_file, encoding="utf-8")
            value = parser.get("Settings", "gtk-icon-theme-name", fallback="").strip()
            if value:
                return value
        except Exception:
            pass
    return "hicolor"


def icon_theme_dir(theme_name: str) -> Path | None:
    for base in ICON_THEME_BASE_DIRS:
        candidate = base / theme_name
        if candidate.is_dir():
            return candidate
    return None


def theme_inherits(theme_name: str) -> list[str]:
    theme_dir = icon_theme_dir(theme_name)
    if not theme_dir:
        return []
    index_file = theme_dir / "index.theme"
    if not index_file.is_file():
        return []
    parser = ConfigParser(interpolation=None)
    try:
        parser.read(index_file, encoding="utf-8")
    except Exception:
        return []
    raw = parser.get("Icon Theme", "Inherits", fallback="")
    return [item.strip() for item in raw.split(",") if item.strip()]


def icon_theme_chain() -> list[str]:
    global ICON_THEME_CHAIN_CACHE
    if ICON_THEME_CHAIN_CACHE is not None:
        return ICON_THEME_CHAIN_CACHE
    chain: list[str] = []
    visited: set[str] = set()
    queue: deque[str] = deque([preferred_icon_theme_name(), "hicolor", "Adwaita"])
    while queue:
        current = queue.popleft().strip()
        if not current or current in visited:
            continue
        visited.add(current)
        chain.append(current)
        for parent in theme_inherits(current):
            if parent not in visited:
                queue.append(parent)
    ICON_THEME_CHAIN_CACHE = chain
    return chain


def theme_icon_lookup(icon_name: str) -> str:
    if not icon_name:
        return ""
    cached = ICON_THEME_CACHE.get(icon_name)
    if cached is not None:
        return cached
    names = [icon_name]
    if Path(icon_name).suffix == "":
        names.extend([icon_name + ext for ext in ICON_EXTENSIONS])
    for theme_name in icon_theme_chain():
        theme_dir = icon_theme_dir(theme_name)
        if not theme_dir:
            continue
        for name in names:
            for path in theme_dir.rglob(name):
                if path.is_file():
                    ICON_THEME_CACHE[icon_name] = str(path)
                    return str(path)
    ICON_THEME_CACHE[icon_name] = ""
    return ""


def normalize_steam_path(raw: str) -> Path:
    return Path(raw.replace("\\\\", "/")).expanduser()


def find_icon(icon_name: str) -> str:
    if not icon_name:
        return ""
    if icon_name.startswith("/"):
        direct = Path(icon_name)
        if direct.is_file():
            return str(direct)
    themed = theme_icon_lookup(icon_name)
    if themed:
        return themed
    for icon_dir in ICON_DIRS:
        if not icon_dir.exists():
            continue
        for size in ICON_SIZES:
            for category in ("apps", "applications"):
                for ext in ICON_EXTENSIONS:
                    candidate = icon_dir / size / category / f"{icon_name}{ext}"
                    if candidate.is_file():
                        return str(candidate)
        for ext in ICON_EXTENSIONS + [""]:
            candidate = icon_dir / f"{icon_name}{ext}"
            if candidate.is_file():
                return str(candidate)
    return ""


def parse_categories(raw_categories: str) -> list[str]:
    raw_items = [item.strip() for item in raw_categories.split(";") if item.strip()]
    out = []
    for item in raw_items:
        if item in NOISE_CATEGORIES or item.startswith("X-"):
            continue
        out.append(item)
    return out


def is_game_entry(name: str, categories: list[str], source: str) -> bool:
    if source == "steam":
        return True
    category_set = {item.lower() for item in categories}
    if "game" in category_set:
        return True
    haystack = (name + " " + " ".join(categories)).lower()
    return any(keyword in haystack for keyword in GAME_KEYWORDS)


def pretty_category(value: str) -> str:
    return PRETTY_CATEGORY.get(value, value)


def normalize_labels(
    name: str, raw_categories: str, source: str
) -> tuple[bool, str, list[str], str]:
    parsed_categories = parse_categories(raw_categories)
    is_game = is_game_entry(name, parsed_categories, source)
    if is_game:
        base_display = "Game"
    else:
        base_display = "App"
        for key in PRIMARY_CATEGORY_ORDER:
            if key in parsed_categories:
                base_display = pretty_category(key)
                break
    tags = []
    if source == "steam":
        tags.append("Steam")
    for cat in parsed_categories:
        label = pretty_category(cat)
        if label in tags or label == base_display:
            continue
        tags.append(label)
        if len(tags) >= 3:
            break
    tags_text = " · ".join(tags)
    return is_game, base_display, tags, tags_text


def stable_id(value: str) -> str:
    digest = hashlib.blake2b(value.encode("utf-8"), digest_size=8)
    return digest.hexdigest()[:12]


def parse_desktop_file(path: Path) -> dict | None:
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return None
    data: dict[str, str] = {}
    in_desktop_entry = False
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line == "[Desktop Entry]":
            in_desktop_entry = True
            continue
        if line.startswith("[") and line.endswith("]"):
            in_desktop_entry = False
            continue
        if not in_desktop_entry or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if "[" in key or key not in ENTRY_KEYS:
            continue
        data[key] = value.strip()
    if data.get("Type", "Application") != "Application":
        return None
    if parse_bool(data.get("NoDisplay", "false")) or parse_bool(data.get("Hidden", "false")):
        return None
    name = data.get("Name", "").strip()
    exec_cmd = clean_exec(data.get("Exec", "").strip())
    if not name or not exec_cmd:
        return None
    exec_head = exec_cmd.split(maxsplit=1)[0]
    icon_name = data.get("Icon", "").strip()
    resolved_icon = find_icon(icon_name)
    source = "desktop"
    raw_categories = data.get("Categories", "")
    is_game, display_category, display_tags, display_tags_text = normalize_labels(
        name, raw_categories, source
    )
    return {
        "name": name,
        "exec": exec_cmd,
        "icon": icon_name if icon_name else resolved_icon,
        "iconPath": resolved_icon,
        "thumbPath": "",
        "heroPath": "",
        "categories": raw_categories,
        "terminal": parse_bool(data.get("Terminal", "false")),
        "source": source,
        "desktopFile": path.name.lower(),
        "execHead": exec_head.lower(),
        "tags": "",
        "isGame": is_game,
        "displayCategory": display_category,
        "displayTags": display_tags,
        "displayTagsText": display_tags_text,
    }


def steam_library_cache_dirs() -> list[Path]:
    dirs: set[Path] = set()
    default_cache = STEAM_DIR / "appcache" / "librarycache"
    if default_cache.is_dir():
        dirs.add(default_cache)
    vdf_file = STEAM_DIR / "steamapps" / "libraryfolders.vdf"
    if not vdf_file.exists():
        return sorted(dirs)
    try:
        text = vdf_file.read_text(errors="replace")
    except OSError:
        return sorted(dirs)
    for match in re.finditer(r'"path"\s+"([^"]+)"', text):
        base = normalize_steam_path(match.group(1))
        candidate = base / "appcache" / "librarycache"
        if candidate.is_dir():
            dirs.add(candidate)
    return sorted(dirs)


def select_steam_media_file(directory: Path, names: tuple[str, ...]) -> str:
    if not directory.is_dir():
        return ""
    for name in names:
        candidate = directory / name
        if candidate.is_file():
            return str(candidate)
    return ""


def find_steam_media(appid: str, library_cache_dirs: list[Path]) -> tuple[str, str]:
    thumb_names = (
        f"{appid}_library_600x900.jpg",
        f"{appid}_header.jpg",
        f"{appid}_capsule_231x87.jpg",
        f"{appid}_library_hero.jpg",
    )
    hero_names = (
        f"{appid}_library_hero.jpg",
        f"{appid}_hero_capsule.jpg",
        f"{appid}_library_hero_blur.jpg",
        f"{appid}_library_600x900.jpg",
        f"{appid}_header.jpg",
    )
    thumb = ""
    hero = ""
    for cache_dir in library_cache_dirs:
        if not thumb:
            thumb = select_steam_media_file(cache_dir, thumb_names)
        if not hero:
            hero = select_steam_media_file(cache_dir, hero_names)
        if thumb and hero:
            break
    return thumb, hero


def parse_steam_games() -> list[dict]:
    games = []
    library_paths: set[Path] = set()
    cache_dirs = steam_library_cache_dirs()
    vdf_file = STEAM_DIR / "steamapps" / "libraryfolders.vdf"
    if vdf_file.exists():
        try:
            text = vdf_file.read_text(errors="replace")
            for match in re.finditer(r'"path"\s+"([^"]+)"', text):
                lib_path = normalize_steam_path(match.group(1)) / "steamapps"
                if lib_path.is_dir():
                    library_paths.add(lib_path)
        except OSError:
            pass
    default = STEAM_DIR / "steamapps"
    if default.is_dir():
        library_paths.add(default)
    steam_icon_path = find_icon("steam")
    steam_icon = "steam"
    seen_ids: set[str] = set()
    for lib_path in library_paths:
        for manifest in lib_path.glob("appmanifest_*.acf"):
            try:
                text = manifest.read_text(errors="replace")
            except OSError:
                continue
            appid_match = re.search(r'"appid"\s+"(\d+)"', text)
            name_match = re.search(r'"name"\s+"([^"]+)"', text)
            if not appid_match or not name_match:
                continue
            appid = appid_match.group(1)
            name = name_match.group(1).strip()
            if not name:
                continue
            lower_name = name.lower()
            if any(skip in lower_name for skip in SKIP_STEAM_NAMES):
                continue
            if appid in seen_ids:
                continue
            seen_ids.add(appid)
            thumb_path, hero_path = find_steam_media(appid, cache_dirs)
            raw_categories = "Game;Steam;"
            is_game, display_category, display_tags, display_tags_text = normalize_labels(
                name,
                raw_categories,
                "steam",
            )
            games.append(
                {
                    "id": f"steam-{appid}",
                    "name": name,
                    "exec": f"steam steam://rungameid/{appid}",
                    "icon": steam_icon,
                    "iconPath": steam_icon_path,
                    "thumbPath": thumb_path,
                    "heroPath": hero_path,
                    "categories": raw_categories,
                    "terminal": False,
                    "source": "steam",
                    "desktopFile": "",
                    "execHead": "steam",
                    "tags": "steam game",
                    "isGame": is_game,
                    "displayCategory": display_category,
                    "displayTags": display_tags,
                    "displayTagsText": display_tags_text,
                }
            )
    return sorted(games, key=lambda item: item["name"].lower())


def list_apps() -> list[dict]:
    apps_by_name: dict[str, dict] = {}
    for desktop_dir in DESKTOP_DIRS:
        if not desktop_dir.is_dir():
            continue
        for desktop_file in sorted(desktop_dir.glob("*.desktop")):
            app = parse_desktop_file(desktop_file)
            if not app:
                continue
            key = app["name"].lower()
            if key in apps_by_name:
                continue
            app["id"] = f"desktop-{stable_id(key)}"
            apps_by_name[key] = app
    for game in parse_steam_games():
        key = game["name"].lower()
        if key in apps_by_name:
            continue
        apps_by_name[key] = game
    return sorted(apps_by_name.values(), key=lambda item: item["name"].lower())


def get_watch_paths() -> list[Path]:
    paths = list(DESKTOP_DIRS)
    paths.append(STEAM_DIR / "steamapps")
    vdf_file = STEAM_DIR / "steamapps" / "libraryfolders.vdf"
    if vdf_file.exists():
        try:
            text = vdf_file.read_text(errors="replace")
            for match in re.finditer(r'"path"\s+"([^"]+)"', text):
                base = normalize_steam_path(match.group(1))
                steamapps = base / "steamapps"
                if steamapps.is_dir() and steamapps not in paths:
                    paths.append(steamapps)
        except OSError:
            pass
    return paths


def regenerate_cache() -> None:
    global ICON_THEME_CACHE, ICON_THEME_CHAIN_CACHE
    ICON_THEME_CACHE.clear()
    ICON_THEME_CHAIN_CACHE = None
    apps = list_apps()
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(apps, f, ensure_ascii=False)
    _reload_event.clear()


def handle_client(conn: socket.socket) -> None:
    try:
        data = b""
        conn.settimeout(5.0)
        while True:
            chunk = conn.recv(4096)
            if not chunk:
                break
            data += chunk
            if b"\n" in data:
                break
        if data:
            try:
                request = json.loads(data.decode("utf-8").strip())
                cmd = request.get("cmd", "")
                if cmd == "PING":
                    response = {"status": "ok"}
                elif cmd == "GET_APPS":
                    if CACHE_FILE.exists():
                        try:
                            with open(CACHE_FILE, encoding="utf-8") as f:
                                apps = json.load(f)
                            if not isinstance(apps, list):
                                apps = []
                            if len(apps) == 0:
                                apps = list_apps()
                                threading.Thread(target=regenerate_cache, daemon=True).start()
                            response = {"status": "ok", "apps": apps}
                        except Exception as e:
                            response = {"status": "error", "msg": str(e)}
                    else:
                        apps = list_apps()
                        if len(apps) > 0:
                            threading.Thread(target=regenerate_cache, daemon=True).start()
                        response = {"status": "ok", "apps": apps}
                elif cmd == "RELOAD":
                    threading.Thread(target=regenerate_cache, daemon=True).start()
                    response = {"status": "ok"}
                elif cmd == "GET_WATCH_PATHS":
                    response = {"status": "ok", "paths": [str(p) for p in get_watch_paths()]}
                else:
                    response = {"status": "error", "msg": f"Unknown command: {cmd}"}
            except Exception as e:
                response = {"status": "error", "msg": str(e)}
        else:
            response = {"status": "error", "msg": "Empty request"}
    except Exception as e:
        response = {"status": "error", "msg": str(e)}
    try:
        conn.sendall((json.dumps(response) + "\n").encode("utf-8"))
    except Exception:
        pass
    finally:
        try:
            conn.close()
        except Exception:
            pass


def inotify_watcher() -> None:
    global _running
    if not INOTIFY_AVAILABLE:
        return
    i = inotify.adapters.Inotify()
    watch_paths = get_watch_paths()
    for path in watch_paths:
        if path.exists():
            try:
                i.add_watch(str(path))
            except Exception:
                pass
    steam_lib_paths = set()
    for path in watch_paths:
        steam_lib_paths.add(str(path))
    steam_lib_paths.add(str(STEAM_DIR / "steamapps" / "libraryfolders.vdf"))
    try:
        while _running:
            try:
                events = i.event(timeout=1000)
                if events:
                    _reload_event.set()
                    for event in events:
                        path = event[1].get("path", "")
                        if not path:
                            continue
                        if "libraryfolders.vdf" in path or "appmanifest_" in path:
                            new_paths = get_watch_paths()
                            for np in new_paths:
                                if str(np) not in steam_lib_paths:
                                    try:
                                        i.add_watch(str(np))
                                        steam_lib_paths.add(str(np))
                                    except Exception:
                                        pass
            except Exception:
                continue
    except Exception:
        pass
    finally:
        try:
            i.close()
        except Exception:
            pass


def polling_watcher() -> None:
    global _running
    last_mtimes: dict[str, float] = {}

    def get_mtimes():
        for desktop_dir in DESKTOP_DIRS:
            if desktop_dir.is_dir():
                for f in desktop_dir.glob("*.desktop"):
                    yield str(f), f.stat().st_mtime
        vdf = STEAM_DIR / "steamapps" / "libraryfolders.vdf"
        if vdf.exists():
            yield str(vdf), vdf.stat().st_mtime
        for lib_path in STEAM_DIR.glob("steamapps/libraryfolders.vdf"):
            yield str(lib_path), lib_path.stat().st_mtime
        for mf in STEAM_DIR.glob("steamapps/appmanifest_*.acf"):
            yield str(mf), mf.stat().st_mtime

    while _running:
        time.sleep(30)
        if not _running:
            break
        changed = False
        current_mtimes = {}
        for path, mtime in get_mtimes():
            current_mtimes[path] = mtime
            if path not in last_mtimes or last_mtimes[path] != mtime:
                changed = True
        if changed:
            _reload_event.set()
        last_mtimes = current_mtimes


def reload_watcher() -> None:
    global _running
    while _running:
        _reload_event.wait(timeout=60)
        if not _running:
            break
        if _reload_event.is_set():
            try:
                regenerate_cache()
            except Exception:
                pass


def signal_handler(signum, frame) -> None:
    global _running
    _running = False


def cleanup() -> None:
    if DAEMON_SOCKET.exists():
        try:
            DAEMON_SOCKET.unlink()
        except Exception:
            pass
    if PID_FILE.exists():
        try:
            PID_FILE.unlink()
        except Exception:
            pass


def main() -> None:
    global _running
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cleanup()
    if CACHE_FILE.exists():
        try:
            age = time.time() - CACHE_FILE.stat().st_mtime
            if age > 86400:
                threading.Thread(target=regenerate_cache, daemon=True).start()
        except Exception:
            pass
    else:
        threading.Thread(target=regenerate_cache, daemon=True).start()
    threading.Thread(target=reload_watcher, daemon=True).start()
    if INOTIFY_AVAILABLE:
        threading.Thread(target=inotify_watcher, daemon=True).start()
    else:
        threading.Thread(target=polling_watcher, daemon=True).start()
    try:
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(str(DAEMON_SOCKET))
        server.listen(5)
        server.settimeout(1.0)
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
        while _running:
            try:
                conn, _ = server.accept()
                threading.Thread(target=handle_client, args=(conn,), daemon=True).start()
            except TimeoutError:
                continue
            except Exception:
                if _running:
                    continue
                break
    except Exception:
        pass
    finally:
        cleanup()


if __name__ == "__main__":
    main()
