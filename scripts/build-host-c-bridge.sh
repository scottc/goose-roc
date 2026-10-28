#!/usr/bin/env bash
# C-bridge host: Goose + C ABI shims → libhost.a (zig cc, x86_64-linux-musl)
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOST="$ROOT/hosts/c-bridge"
OUT="$ROOT/platform/targets-out/x64musl"
VENDOR="$ROOT/vendor/targets/x64musl"
BUILD="$ROOT/build/c-bridge"
mkdir -p "$OUT" "$BUILD"

if ! command -v goose >/dev/null || ! command -v zig >/dev/null; then
  echo "error: need goose and zig on PATH (blueprint shell)" >&2
  exit 1
fi

ZIG_CC=(zig cc -target x86_64-linux-musl -O2 -fno-stack-protector -D_FORTIFY_SOURCE=0)

echo "==> goose --standalone → $BUILD/host.c"
goose --standalone --header "$BUILD/host.h" -o "$BUILD/host.c" "$HOST/host.goose"

echo "==> zig cc (musl)"
"${ZIG_CC[@]}" -c "$BUILD/host.c"   -o "$BUILD/host.o"
"${ZIG_CC[@]}" -c "$HOST/roc_abi.c" -o "$BUILD/roc_abi.o"
"${ZIG_CC[@]}" -c "$HOST/main.c"    -o "$BUILD/main.o"

OBJS=("$BUILD/host.o" "$BUILD/roc_abi.o" "$BUILD/main.o")
if [[ -f "$HOST/goose_msg.c" ]]; then
  "${ZIG_CC[@]}" -c "$HOST/goose_msg.c" -o "$BUILD/goose_msg.o"
  OBJS+=("$BUILD/goose_msg.o")
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

echo "wrote $OUT/libhost.a"
nm "$OUT/libhost.a" | grep -E ' (main|goose_init|goose_hello|roc_alloc|roc_stdout_line)$' || true
