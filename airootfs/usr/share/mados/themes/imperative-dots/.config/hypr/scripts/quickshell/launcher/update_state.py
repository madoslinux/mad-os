#!/usr/bin/env python3

import json
import sys
from pathlib import Path


def load_state(path: Path) -> dict:
    try:
        parsed = json.loads(path.read_text())
        if isinstance(parsed, dict):
            favorites = parsed.get("favorites", {})
            hidden = parsed.get("hidden", {})
            return {
                "favorites": favorites if isinstance(favorites, dict) else {},
                "hidden": hidden if isinstance(hidden, dict) else {},
            }
    except (OSError, json.JSONDecodeError):
        pass

    return {"favorites": {}, "hidden": {}}


def save_state(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False))


def normalize_key(value: str) -> str:
    return str(value or "").strip().lower()


def set_flag(bucket: dict, key: str, enabled: bool) -> None:
    if enabled:
        bucket[key] = True
    elif key in bucket:
        del bucket[key]


def parse_enabled(raw: str) -> bool:
    value = str(raw or "").strip().lower()
    return value in {"1", "true", "yes", "on"}


def main() -> None:
    if len(sys.argv) != 5:
        return

    state_path = Path(sys.argv[1]).expanduser()
    action = normalize_key(sys.argv[2])
    app_id = normalize_key(sys.argv[3])
    enabled = parse_enabled(sys.argv[4])
    if action not in {"favorite", "hidden"} or app_id == "":
        return

    state = load_state(state_path)
    if action == "favorite":
        set_flag(state["favorites"], app_id, enabled)
    else:
        set_flag(state["hidden"], app_id, enabled)

    save_state(state_path, state)


if __name__ == "__main__":
    main()
