#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8000}"
DIR="${2:-out}"

if [[ ! -d "${DIR}" ]]; then
    echo "Directory not found: ${DIR}" >&2
    exit 1
fi

echo "Serving ${DIR}/ on http://0.0.0.0:${PORT}"
python3 -m http.server "${PORT}" --directory "${DIR}"
