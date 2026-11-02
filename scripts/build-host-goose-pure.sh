#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOST="$ROOT/hosts/goose-pure"
BRIDGE="$HOST/stdlib_bridge"
OUT="$ROOT/platform/targets-out/x64musl"
VENDOR="$ROOT/vendor/targets/x64musl"
BUILD="$ROOT/build/goose-pure"
mkdir -p "$OUT" "$BUILD"

ZIG_CC=(zig cc -target x86_64-linux-musl -O2 -fno-stack-protector -D_FORTIFY_SOURCE=0)

echo "==> roc glue"
roc glue "$ROOT/glue/GooseGlue.roc" "$BUILD/" "$ROOT/platform/main.roc"

TYPES="$BUILD/roc_platform_abi_types.goose"
EXPORTS="$BUILD/roc_platform_abi_exports.goose"
IMPL="$HOST/host_impl.goose"

for f in "$TYPES" "$EXPORTS" "$IMPL"; do
  [[ -f "$f" ]] || { echo "error: missing $f" >&2; exit 1; }
done

# Optional bridges (impl_roc_* for os/math/gfx/…). Missing file = skip with a note.
BRIDGES=(
  "$BRIDGE/math_bridge.goose"
  "$BRIDGE/os_bridge.goose"
  "$BRIDGE/gfx_bridge.goose"
  "$BRIDGE/audio_bridge.goose"
  "$BRIDGE/physics_bridge.goose"
  "$BRIDGE/ui_bridge.goose"
)

BRIDGE_FILES=()
for f in "${BRIDGES[@]}"; do
  if [[ -f "$f" ]]; then
    BRIDGE_FILES+=("$f")
  else
    echo "note: no $f (skip)"
  fi
done

# Order: types → core impl → stdlib bridges → export wrappers
echo "==> concat types + impl + bridges + exports"
{
  cat "$TYPES"
  echo
  cat "$IMPL"
  for f in "${BRIDGE_FILES[@]}"; do
    echo
    echo "// ---- bridge: $(basename "$f") ----"
    cat "$f"
  done
  echo
  cat "$EXPORTS"
} > "$BUILD/host_all.goose"

echo "==> goose --standalone"
goose --standalone --header "$BUILD/host.h" -o "$BUILD/host.c" "$BUILD/host_all.goose"

echo "==> zig cc (musl)"
"${ZIG_CC[@]}" -c "$BUILD/host.c" -o "$BUILD/host.o"
"${ZIG_CC[@]}" -c "$HOST/gs_ffi_polyfill.c" -o "$BUILD/gs_ffi_polyfill.o"
"${ZIG_CC[@]}" -c "$HOST/entry.c" -o "$BUILD/entry.o"

echo "==> ar $OUT/libhost.a"
rm -f "$OUT/libhost.a"
ar rcs "$OUT/libhost.a" "$BUILD/host.o" "$BUILD/gs_ffi_polyfill.o" "$BUILD/entry.o"

for f in crt1.o libc.a libzigc.a libcompiler_rt.a libunwind.a; do
  if [[ -f "$VENDOR/$f" ]]; then
    cp -f "$VENDOR/$f" "$OUT/$f"
    echo "copied $f"
  fi
done

echo "wrote $OUT/libhost.a"
nm "$OUT/libhost.a" | grep -E ' (main|goose_init|roc_alloc|roc_stdout_line|roc_os_clock_secs|roc_math_sin)$' || true
