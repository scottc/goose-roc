#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT/app/mini_doom"

roc build --target=x64glibc main.roc
python3 "$ROOT/scripts/strip-pt-interp.py" ./main

file ./main
readelf -l ./main | grep INTERP || echo "no INTERP ok"

gdb -batch \
  -ex "set pagination off" \
  -ex run \
  -ex bt \
  -ex "info registers" \
  --args ./main
