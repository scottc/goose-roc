#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
EXE="$ROOT/app/mini_doom/main"
test -f "$EXE"
file "$EXE"
echo "--- program headers (INTERP) ---"
readelf -l "$EXE" | grep -A2 INTERP || echo "no INTERP"
echo "--- dynamic section ---"
readelf -d "$EXE" 2>/dev/null | head -20 || echo "(none)"
