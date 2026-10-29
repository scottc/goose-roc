#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOST="$ROOT/hosts/goose-pure"
OUT="$ROOT/platform/targets-out/x64musl"
VENDOR="$ROOT/vendor/targets/x64musl"
BUILD="$ROOT/build/goose-pure"
mkdir -p "$OUT" "$BUILD"

MODE="${1:-build}"

if [[ "$MODE" == "jit" ]]; then
  command -v goose >/dev/null || { echo "error: goose not on PATH" >&2; exit 1; }
  echo "==> JIT smoke (not an Roc host)"
  goose "$HOST/host.goose"
  exit 0
fi

if ! command -v goose >/dev/null || ! command -v zig >/dev/null; then
  echo "error: need goose and zig on PATH" >&2
  exit 1
fi

ZIG_CC=(zig cc -target x86_64-linux-musl -O2 -fno-stack-protector -D_FORTIFY_SOURCE=0)

echo "==> goose --standalone → $BUILD/host.c"
goose --standalone --header "$BUILD/host.h" -o "$BUILD/host.c" "$HOST/host.goose"

echo "==> zig cc (musl)"
"${ZIG_CC[@]}" -c "$BUILD/host.c" -o "$BUILD/host.o"
"${ZIG_CC[@]}" -c "$HOST/entry.c" -o "$BUILD/entry.o"

OBJS=("$BUILD/host.o" "$BUILD/entry.o")

# v2026.3: gs_ffi_* not in standalone runtime — link polyfill
if [[ -f "$HOST/gs_ffi_polyfill.c" ]]; then
  echo "==> zig cc gs_ffi_polyfill.c"
  "${ZIG_CC[@]}" -c "$HOST/gs_ffi_polyfill.c" -o "$BUILD/gs_ffi_polyfill.o"
  OBJS+=("$BUILD/gs_ffi_polyfill.o")
fi

echo "==> ar $OUT/libhost.a"
rm -f "$OUT/libhost.a"
ar rcs "$OUT/libhost.a" "${OBJS[@]}"

for f in crt1.o libc.a libzigc.a libcompiler_rt.a libunwind.a; do
  if [[ -f "$VENDOR/$f" ]]; then
    cp -f "$VENDOR/$f" "$OUT/$f"
    echo "copied $f"
  fi
done

echo "wrote $OUT/libhost.a (goose-pure)"
nm "$OUT/libhost.a" | grep -E ' (main|goose_init|roc_alloc|roc_stderr_line|roc_stdout_line|gs_ffi_bytes)$' || true
