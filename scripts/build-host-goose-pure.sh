#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOST="$ROOT/hosts/goose-pure"
OUT="$ROOT/platform/targets-out/x64musl"
VENDOR="$ROOT/vendor/targets/x64musl"
BUILD="$ROOT/build/goose-pure"
mkdir -p "$OUT" "$BUILD"

ZIG_CC=(zig cc -target x86_64-linux-musl -O2 -fno-stack-protector -D_FORTIFY_SOURCE=0)

echo "==> goose --standalone → $BUILD/host.c"
goose --standalone --header "$BUILD/host.h" -o "$BUILD/host.c" "$HOST/host.goose"

echo "==> zig cc (musl)"
"${ZIG_CC[@]}" -c "$BUILD/host.c" -o "$BUILD/host.o"
"${ZIG_CC[@]}" -c "$HOST/gs_ffi_polyfill.c" -o "$BUILD/gs_ffi_polyfill.o"
"${ZIG_CC[@]}" -c "$HOST/entry.c" -o "$BUILD/entry.o"

echo "==> ar $OUT/libhost.a"
rm -f "$OUT/libhost.a"
ar rcs "$OUT/libhost.a" "$BUILD/host.o" "$BUILD/gs_ffi_polyfill.o" "$BUILD/entry.o"

for f in crt1.o libc.a libzigc.a libcompiler_rt.a libunwind.a; do
  [[ -f "$VENDOR/$f" ]] && cp -f "$VENDOR/$f" "$OUT/$f" && echo "copied $f"
done

echo "wrote $OUT/libhost.a"
nm "$OUT/libhost.a" | grep -E ' (main|main_for_host|roc_main|roc_alloc|roc_stdout_line)$' || true
