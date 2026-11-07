#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/platform/targets-out/x64glibc"
cd "$ROOT/app/mini_doom"

test -f "$OUT/libhost.a"
test -f "$OUT/libc_nonshared.a"
file "$OUT/libc.so" | grep -qiE 'text|script' || {
  echo "error: libc.so must be a linker script text file, got: $(file "$OUT/libc.so")" >&2
  exit 1
}

echo "==> roc build --target=x64glibc"
roc build --target=x64glibc main.roc

file ./main
# Leave INTERP as /lib64/ld-linux-x86-64.so.2 — do NOT patchelf to long nix path
# Leave RUNPATH alone — use LD_LIBRARY_PATH at run time

echo "build-mini-doom ok (use nix-ld or steam-run to execute)"
