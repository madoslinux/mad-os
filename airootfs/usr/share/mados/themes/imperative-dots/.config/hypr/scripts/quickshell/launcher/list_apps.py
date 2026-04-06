#!/usr/bin/env python3

import hashlib
import json
import os
import re
from collections import deque
from configparser import ConfigParser
from pathlib import Path


def default_steam_dir() -> Path:
    return Path.home() / ".local/share/Steam"


STEAM_DIR = Path(os.environ.get("STEAM_DIR", str(default_steam_dir()))).expanduser()
DESKTOP_DIRS = [
    Path("/usr/share/applications"),
    Path.home() / ".local/share/applications",
    Path("/var/lib/flatpak/exports/share/applications"),
    Path.home() / ".local/share/flatpak/exports/share/applications",
]

ICON_DIRS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons/hicolor"),
    Path("/usr/share/icons/Adwaita"),
    Path("/usr/share/pixmaps"),
    Path("/usr/share/icons"),
]

ICON_SIZES = ["512x512", "256x256", "128x128", "96x96", "64x64", "48x48", "scalable"]
ICON_EXTENSIONS = [".png", ".svg", ".xpm"]

ICON_THEME_BASE_DIRS = [
    Path.home() / ".icons",
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons"),
]

ENTRY_KEYS = {
    "Type",
    "Name",
    "Exec",
    "Icon",
    "Categories",
    "NoDisplay",
    "Hidden",
    "Terminal",
}

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

GAME_KEYWORDS = (
    "game",
    "steam",
    "lutris",
    "heroic",
    "retroarch",
    "proton",
)

FIELD_CODE_PATTERN = re.compile(r"\s+%[fFuUdDnNickvm]")

ICON_THEME_CACHE: dict[str, str] = {}
ICON_THEME_CHAIN_CACHE: list[str] | None = None


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
                    resolved = str(path)
                    ICON_THEME_CACHE[icon_name] = resolved
                    return resolved

    ICON_THEME_CACHE[icon_name] = ""
    return ""


def normalize_steam_path(raw: str) -> Path:
    replaced = raw.replace("\\\\", "/")
    return Path(replaced).expanduser()


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


def prefer_theme_icon(icon_name: str, icon_path: str) -> str:
    if not icon_name:
        return ""

    if icon_path:
        return icon_path

    return icon_name


def parse_categories(raw_categories: str) -> list[str]:
    raw_items = [item.strip() for item in raw_categories.split(";") if item.strip()]
    out = []
    for item in raw_items:
        if item in NOISE_CATEGORIES:
            continue
        if item.startswith("X-"):
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
        if label in tags:
            continue
        if label == base_display:
            continue
        tags.append(label)
        if len(tags) >= 3:
            break

    tags_text = " · ".join(tags)
    return is_game, base_display, tags, tags_text


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

    icon_name = data.get("Icon", "").strip()
    resolved_icon = find_icon(icon_name)
    source = "desktop"
    raw_categories = data.get("Categories", "")
    is_game, display_category, display_tags, display_tags_text = normalize_labels(
        name,
        raw_categories,
        source,
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
        if thumb == "":
            thumb = select_steam_media_file(cache_dir, thumb_names)

        if hero == "":
            hero = select_steam_media_file(cache_dir, hero_names)

        if thumb and hero:
            break

    return thumb, hero


def stable_id(value: str) -> str:
    digest = hashlib.blake2b(value.encode("utf-8"), digest_size=8)
    return digest.hexdigest()[:12]


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


def main() -> None:
    try:
        print(json.dumps(list_apps(), ensure_ascii=False))
    except Exception:
        print("[]")


if __name__ == "__main__":
    main()
