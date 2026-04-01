#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8000}"
DIR="${2:-out}"

echo "Serving ${DIR}/ on http://0.0.0.0:${PORT}"
cd "${DIR}" && python3 -m http.server "${PORT}"
