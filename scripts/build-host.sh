#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/platform/targets-out/x64musl"
VENDOR="$ROOT/vendor/targets/x64musl"
BUILD="$ROOT/build/host"
mkdir -p "$OUT" "$BUILD"

ZIG_CC=(zig cc -target x86_64-linux-musl -O2 -fno-stack-protector -D_FORTIFY_SOURCE=0)

# 1) Goose → C
goose --standalone --header "$BUILD/host.h" -o "$BUILD/host.c" "$ROOT/host/host.goose"

# 2) Compile everything for musl
"${ZIG_CC[@]}" -c "$BUILD/host.c"            -o "$BUILD/host.o"
"${ZIG_CC[@]}" -c "$ROOT/host/roc_abi.c"     -o "$BUILD/roc_abi.o"
"${ZIG_CC[@]}" -c "$ROOT/host/goose_msg.c"   -o "$BUILD/goose_msg.o" 2>/dev/null || true
"${ZIG_CC[@]}" -c "$ROOT/host/main.c"        -o "$BUILD/main.o"

# 3) Archive (order doesn't matter much for ar)
OBJS=("$BUILD/host.o" "$BUILD/roc_abi.o" "$BUILD/main.o")
[[ -f "$BUILD/goose_msg.o" ]] && OBJS+=("$BUILD/goose_msg.o")
ar rcs "$OUT/libhost.a" "${OBJS[@]}"

# 4) Vendor linker inputs
for f in crt1.o libc.a libzigc.a libcompiler_rt.a libunwind.a; do
  [[ -f "$VENDOR/$f" ]] && cp -f "$VENDOR/$f" "$OUT/$f" && echo "copied $f"
done

echo "wrote $OUT/libhost.a"
nm "$OUT/libhost.a" | grep -E ' (main|goose_init|goose_hello|roc_alloc|roc_stdout_line|roc_main)$' || true
