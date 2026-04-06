#!/usr/bin/env python3

import json
import sys
import time
from pathlib import Path


def load_data(path: Path) -> dict:
    try:
        raw = path.read_text()
        parsed = json.loads(raw)
        if isinstance(parsed, dict):
            return parsed
    except (OSError, json.JSONDecodeError):
        pass

    return {}


def save_data(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False))


def update_scores(path: Path, query: str, app_key: str) -> None:
    normalized_query = query.strip().lower()
    normalized_app = app_key.strip().lower()
    if len(normalized_query) < 2 or normalized_app == "":
        return

    data = load_data(path)
    now = int(time.time())

    for size in range(2, len(normalized_query) + 1):
        prefix = normalized_query[:size]
        bucket = data.get(prefix)
        if not isinstance(bucket, dict):
            bucket = {}

        current = bucket.get(normalized_app)
        if isinstance(current, dict):
            count = int(current.get("count", 0)) + 1
        else:
            count = int(current or 0) + 1

        bucket[normalized_app] = {
            "count": count,
            "last": now,
        }
        data[prefix] = bucket

    save_data(path, data)


def main() -> None:
    if len(sys.argv) != 4:
        return

    path = Path(sys.argv[1]).expanduser()
    query = sys.argv[2]
    app_key = sys.argv[3]
    update_scores(path, query, app_key)


if __name__ == "__main__":
    main()
