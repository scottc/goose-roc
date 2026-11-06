#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT/app/mini_doom"

# Fail early if platform inputs were stripped of libc
for f in libc.a libm.a libhost.a libgoose_gfx.a crt1.o; do
  test -f "$ROOT/platform/targets-out/x64glibc/$f" || {
    echo "error: missing targets-out/x64glibc/$f — run scripts/build-host-goose-pure-glibc.sh" >&2
    exit 1
  }
done

echo "==> roc build --target=x64glibc"
roc build --target=x64glibc main.roc

echo "==> strip PT_INTERP"
python3 "$ROOT/scripts/strip-pt-interp.py" ./main

file ./main
if readelf -l ./main | grep -q INTERP; then
  echo "error: INTERP still present" >&2
  exit 1
fi
echo "build-mini-doom ok: $(pwd)/main"
