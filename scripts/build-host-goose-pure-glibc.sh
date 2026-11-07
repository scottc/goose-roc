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
}

echo "==> goose gfx (.a)"
RSP=$(goose --gfx-link cc)
cp -f "$RSP" "$CACHE/link-cc.rsp"
while read -r tok; do
  case "$tok" in
    *.a)
      [[ -f "$tok" ]] || continue
      stage "$tok" "$(basename "$tok")"
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

# libgcc static pieces still useful for some unresolved soft-float/EH from archives
if [[ -n "${CC_DIR:-}" ]]; then
  stage "$CC_DIR/libgcc.a" libgcc.a || true
  stage "$CC_DIR/libgcc_eh.a" libgcc_eh.a || true
fi

echo "==> dynamic glibc (linker script + nonshared)"
GLIBC_LIB="$CRT_DIR"
LDSO="$GLIBC_LIB/ld-linux-x86-64.so.2"

# libc_nonshared.a
NONSHARED="$GLIBC_LIB/libc_nonshared.a"
if [[ ! -f "$NONSHARED" ]]; then
  NONSHARED=$(cc -print-file-name=libc_nonshared.a 2>/dev/null || true)
fi
[[ -f "$NONSHARED" ]] || { echo "error: no libc_nonshared.a"; exit 1; }
cp -f "$NONSHARED" "$OUT/libc_nonshared.a"
echo "  libc_nonshared.a"

# sonames (symlinks into store are fine)
ln -sfn "$GLIBC_LIB/libc.so.6"       "$OUT/libc.so.6"
ln -sfn "$GLIBC_LIB/libm.so.6"       "$OUT/libm.so.6"
ln -sfn "$GLIBC_LIB/libdl.so.2"      "$OUT/libdl.so.2"
ln -sfn "$GLIBC_LIB/libpthread.so.0" "$OUT/libpthread.so.0"
ln -sfn "$GLIBC_LIB/librt.so.1"      "$OUT/librt.so.1"
ln -sfn "$GLIBC_LIB/libutil.so.1"    "$OUT/libutil.so.1" 2>/dev/null || true

ln -sfn libm.so.6       "$OUT/libm.so"
ln -sfn libdl.so.2      "$OUT/libdl.so"
ln -sfn libpthread.so.0 "$OUT/libpthread.so"
ln -sfn librt.so.1      "$OUT/librt.so"
ln -sfn libutil.so.1    "$OUT/libutil.so" 2>/dev/null || true

# CRITICAL: remove any symlink before writing a real file
rm -f "$OUT/libc.so" "$CACHE/libc.so"
# write a regular file (not a symlink)
cat > "$OUT/libc.so" <<EOF
/* roc x64glibc dynamic */
GROUP ( $GLIBC_LIB/libc.so.6 $OUT/libc_nonshared.a AS_NEEDED ( $LDSO ) )
EOF
cp -f "$OUT/libc.so" "$CACHE/libc.so"

file "$OUT/libc.so"   # must say "ASCII text" or "script", NOT "ELF" / "symbolic link"
head -3 "$OUT/libc.so"

STDCXX=$(cc -print-file-name=libstdc++.so.6 2>/dev/null || true)
GCC_S=$(cc -print-file-name=libgcc_s.so.1 2>/dev/null || true)
[[ -e "$STDCXX" ]] && ln -sfn "$STDCXX" "$OUT/libstdc++.so" && ln -sfn "$STDCXX" "$OUT/libstdc++.so.6"
[[ -e "$GCC_S" ]] && ln -sfn "$GCC_S" "$OUT/libgcc_s.so" && ln -sfn "$GCC_S" "$OUT/libgcc_s.so.1"

rm -f "$OUT"/libc.a "$OUT"/libm.a "$OUT"/libpthread.a "$OUT"/libdl.a \
      "$OUT"/librt.a "$OUT"/libutil.a "$OUT"/libresolv.a 2>/dev/null || true

echo "==> checks"
test -f "$OUT/libhost.a"
test -e "$OUT/libc.so" || test -e "$OUT/libc.so.6"
test -f "$OUT/libgoose_gfx.a"
ls -la "$OUT" | head -40
nm "$OUT/libgoose_gfx.a" | grep ' T gs_gfx_open' | head -1
echo "host-glibc (dynamic) ok"
echo "note: platform inputs must list libc.so libm.so … not libc.a"
