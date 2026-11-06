#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
EXE="${1:-$ROOT/app/mini_doom/main}"
test -f "$EXE"
python3 "$ROOT/scripts/strip-pt-interp.py" "$EXE"
file "$EXE"
readelf -l "$EXE" | grep INTERP || echo "no INTERP ok"
