#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOST="$ROOT/hosts/goose-pure"
OUT="$ROOT/platform/targets-out/x64glibc"
CACHE="$ROOT/.cache/goose-roc-host/x64glibc"
BUILD="$ROOT/build/goose-pure-glibc"
mkdir -p "$OUT" "$CACHE" "$BUILD"

ZIG_CC=(zig cc -target x86_64-linux-gnu -O2 -fno-stack-protector -D_FORTIFY_SOURCE=0)

need() { command -v "$1" >/dev/null || { echo "error: need $1" >&2; exit 1; }; }
need goose; need zig; need roc; need ar; need nm; need nix-build

echo "==> roc glue"
roc glue "$ROOT/glue/GooseGlue.roc" "$BUILD/" "$ROOT/platform/main.roc"

TYPES="$BUILD/roc_platform_abi_types.goose"
EXPORTS="$BUILD/roc_platform_abi_exports.goose"
IMPL="$HOST/host_impl.goose"
for f in "$TYPES" "$EXPORTS" "$IMPL"; do
  [[ -f "$f" ]] || { echo "error: missing $f" >&2; exit 1; }
done

BRIDGES=()
for b in \
  "$HOST/stdlib_bridge/os_bridge.goose" \
  "$HOST/stdlib_bridge/math_bridge.goose" \
  "$HOST/stdlib_bridge/gfx_bridge.goose" \
  "$HOST/stdlib_bridge/audio_bridge.goose" \
  "$HOST/stdlib_bridge/physics_bridge.goose" \
  "$HOST/stdlib_bridge/ui_bridge.goose"
do
  [[ -f "$b" ]] && BRIDGES+=("$b")
done

echo "==> concat"
{
  cat "$TYPES"
  cat "$IMPL"
  for b in "${BRIDGES[@]}"; do cat "$b"; done
  cat "$EXPORTS"
} > "$BUILD/host_all.goose"

echo "==> goose --standalone"
goose --standalone --header "$BUILD/host.h" -o "$BUILD/host.c" "$BUILD/host_all.goose"

echo "==> zig cc (x86_64-linux-gnu)"
"${ZIG_CC[@]}" -c "$BUILD/host.c" -o "$BUILD/host.o"
"${ZIG_CC[@]}" -c "$HOST/gs_ffi_polyfill.c" -o "$BUILD/gs_ffi_polyfill.o"
OBJS=( "$BUILD/host.o" "$BUILD/gs_ffi_polyfill.o" )
if [[ -f "$HOST/gs_gfx_upload.c" ]]; then
  "${ZIG_CC[@]}" -c "$HOST/gs_gfx_upload.c" -o "$BUILD/gs_gfx_upload.o"
  OBJS+=( "$BUILD/gs_gfx_upload.o" )
fi
"${ZIG_CC[@]}" -c "$HOST/entry.c" -o "$BUILD/entry.o"
OBJS+=( "$BUILD/entry.o" )

echo "==> ar $OUT/libhost.a"
rm -f "$OUT/libhost.a"
ar rcs "$OUT/libhost.a" "${OBJS[@]}"

stage() {
  local src="$1" name="$2"
  [[ -f "$src" ]] || return 1
  cp -f "$src" "$CACHE/$name"
  cp -f "$src" "$OUT/$name"
  echo "  $name"
  return 0
}

echo "==> goose gfx"
RSP=$(goose --gfx-link cc)
cp -f "$RSP" "$CACHE/link-cc.rsp"
while read -r tok; do
  case "$tok" in
    *.a)
      if [[ -f "$tok" ]]; then
        bn=$(basename "$tok")
        stage "$tok" "$bn" || true
      fi
      ;;
  esac
done < <(tr ' \t\n' '\n' < "$RSP" | sed '/^$/d')

echo "==> CRT (zig libc)"
CRT_DIR=$(zig libc 2>/dev/null | sed -n 's/^crt_dir=//p' | head -1)
CC_DIR=$(zig libc 2>/dev/null | sed -n 's/^cc_dir=//p' | head -1)
echo "  crt_dir=$CRT_DIR"
stage "$CRT_DIR/crt1.o" crt1.o || { echo "error: crt1.o"; exit 1; }
stage "$CRT_DIR/crti.o" crti.o || true
stage "$CRT_DIR/crtn.o" crtn.o || true

echo "==> glibc.static"
STATIC_ROOT=""
if [[ -f "$CACHE/glibc-static-root.txt" ]]; then
  STATIC_ROOT=$(cat "$CACHE/glibc-static-root.txt")
  [[ -d "$STATIC_ROOT" ]] || STATIC_ROOT=""
fi
if [[ -z "$STATIC_ROOT" ]]; then
  STATIC_ROOT=$(nix-build --no-out-link -E 'with import <nixpkgs> {}; glibc.static' 2>/dev/null || true)
  [[ -z "$STATIC_ROOT" ]] && STATIC_ROOT=$(nix-build --no-out-link '<nixpkgs>' -A glibc.static 2>/dev/null || true)
  [[ -n "$STATIC_ROOT" ]] || { echo "error: glibc.static"; exit 1; }
  echo "$STATIC_ROOT" > "$CACHE/glibc-static-root.txt"
fi
echo "  $STATIC_ROOT"
STATIC_LIB="$STATIC_ROOT/lib"
[[ -d "$STATIC_LIB" ]] || STATIC_LIB="$STATIC_ROOT"

stage_static() {
  local name="$1"
  if [[ -f "$STATIC_LIB/$name" ]]; then
    stage "$STATIC_LIB/$name" "$name"
    return 0
  fi
  [[ -f "$STATIC_ROOT/lib64/$name" ]] && stage "$STATIC_ROOT/lib64/$name" "$name" && return 0
  echo "WARN: no $name"
  return 1
}

stage_static libc.a || { echo "error: libc.a required"; exit 1; }
stage_static libm.a || { echo "error: libm.a required"; exit 1; }
stage_static libpthread.a || true
stage_static libdl.a || true
stage_static librt.a || true
stage_static libutil.a || true
stage_static libresolv.a || true

echo "==> libgcc"
if [[ -n "${CC_DIR:-}" ]]; then
  stage "$CC_DIR/libgcc.a" libgcc.a || true
  stage "$CC_DIR/libgcc_eh.a" libgcc_eh.a || true
fi

# Never leave dynamic stubs in OUT for this static path
rm -f "$OUT"/libc.so* "$OUT"/libm.so* "$OUT"/libzigc.a "$OUT"/libcompiler_rt.a 2>/dev/null || true

echo "==> checks"
test -f "$OUT/libc.a" && test -f "$OUT/libm.a" && test -f "$OUT/libgoose_gfx.a"
test -f "$OUT/libhost.a"
ls -la "$OUT"
nm "$OUT/libgoose_gfx.a" | grep ' T gs_gfx_open' | head -1
nm "$OUT/libhost.a" | grep -E ' T (main|roc_gfx_init|roc_alloc)$' || true
echo "host-glibc ok"
