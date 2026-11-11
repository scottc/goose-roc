#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOST="$ROOT/hosts/goose-pure"
OUT="$ROOT/platform/targets-out/x64glibc"
BUILD="$ROOT/build/goose-pure-glibc"
CACHE="${GOOSE_HOME:-$HOME/.cache/goose-home}"
mkdir -p "$OUT" "$BUILD"

ZIG_CC=(zig cc -target x86_64-linux-gnu -O2 -fno-stack-protector -D_FORTIFY_SOURCE=0)

echo "==> roc glue"
roc glue "$ROOT/glue/GooseGlue.roc" "$BUILD/" "$ROOT/platform/main.roc"

TYPES="$BUILD/roc_platform_abi_types.goose"
EXPORTS="$BUILD/roc_platform_abi_exports.goose"
IMPL="$HOST/host_impl.goose"

BRIDGES=()
for b in os_bridge math_bridge gfx_bridge audio_bridge phys_bridge ui_bridge; do
  f="$HOST/stdlib_bridge/${b}.goose"
  [[ -f "$f" ]] && BRIDGES+=("$f")
done

for f in "$TYPES" "$EXPORTS" "$IMPL"; do
  [[ -f "$f" ]] || { echo "error: missing $f" >&2; exit 1; }
done

echo "==> concat"
cat "$TYPES" "$IMPL" "${BRIDGES[@]}" "$EXPORTS" > "$BUILD/host_all.goose"

echo "==> goose --standalone"
goose --standalone --stack-reserve 16G --header "$BUILD/host.h" -o "$BUILD/host.c" "$BUILD/host_all.goose"

echo "==> zig cc (x86_64-linux-gnu)"
"${ZIG_CC[@]}" -c "$BUILD/host.c" -o "$BUILD/host.o"
[[ -f "$HOST/gs_ffi_polyfill.c" ]] && "${ZIG_CC[@]}" -c "$HOST/gs_ffi_polyfill.c" -o "$BUILD/gs_ffi_polyfill.o"
"${ZIG_CC[@]}" -c "$HOST/entry.c" -o "$BUILD/entry.o"

OBJS=("$BUILD/host.o" "$BUILD/entry.o")
[[ -f "$BUILD/gs_ffi_polyfill.o" ]] && OBJS+=("$BUILD/gs_ffi_polyfill.o")
ar rcs "$OUT/libhost.a" "${OBJS[@]}"
echo "==> ar $OUT/libhost.a"

# --- gfx static libs from GOOSE_HOME package build (v2026.4) ---
stage_one() {
  local name="$1"
  local found
  found=$(find "$CACHE" -type f -name "$name" 2>/dev/null | head -1 || true)
  if [[ -z "$found" ]]; then
    echo "error: missing $name under $CACHE" >&2
    echo "  Build gfx once:  cd app/mini_doom && goose build mini_doom.goose" >&2
    echo "  (needs cmake + X11/xcb headers in PATH)" >&2
    exit 1
  fi
  cp -f "$found" "$OUT/$name"
  echo "  $name <- $found"
}

# echo "==> goose gfx (.a from GOOSE_HOME)"
# # Prefer response file if goose can emit it after package build
# if RSP=$(goose --gfx-link cc 2>/dev/null) && [[ -f "$RSP" ]]; then
#   echo "  link-cc.rsp: $RSP"
#   # copy every .a named in the rsp that exists
#   while read -r tok; do
#     case "$tok" in
#       *.a)
#         if [[ -f "$tok" ]]; then
#           cp -f "$tok" "$OUT/$(basename "$tok")"
#           echo "  $(basename "$tok")"
#         fi
#         ;;
#     esac
#   done < <(tr ' \t' '\n' < "$RSP" | grep '\.a$' || true)
# else
#   stage_one libgoose_gfx.a
#   stage_one libgoose_audio.a
#   stage_one libgoose_ui.a
#   stage_one libSDL3.a
# fi

echo "==> goose gfx (.a)"
bash "$ROOT/scripts/stage-goose-gfx-libs.sh"

# --- CRT + dynamic glibc (same as before) ---
echo "==> CRT (zig libc)"
mapfile -t LIBC_LINES < <(zig libc 2>/dev/null || true)
CRT_DIR=""
for line in "${LIBC_LINES[@]}"; do
  if [[ "$line" == crt_dir=* ]]; then
    CRT_DIR="${line#crt_dir=}"
  fi
done
[[ -n "$CRT_DIR" ]] || { echo "error: zig libc gave no crt_dir" >&2; exit 1; }
echo "  crt_dir=$CRT_DIR"
for f in crt1.o crti.o crtn.o; do
  [[ -f "$CRT_DIR/$f" ]] && cp -f "$CRT_DIR/$f" "$OUT/$f" && echo "  $f"
done

# libgcc from gcc
GCC_LIB=$(dirname "$(cc -print-libgcc-file-name)")
for f in libgcc.a libgcc_eh.a; do
  [[ -f "$GCC_LIB/$f" ]] && cp -f "$GCC_LIB/$f" "$OUT/$f" && echo "  $f"
done

echo "==> dynamic glibc (linker script + nonshared)"
GLIBC_LIB=$(dirname "$(cc -print-file-name=libc.so.6)")
# Prefer real .so from same tree as ld-linux
for soname in libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 librt.so.1 libutil.so.1; do
  if [[ -e "$GLIBC_LIB/$soname" ]]; then
    ln -sfn "$GLIBC_LIB/$soname" "$OUT/$soname"
    echo "  $soname -> $GLIBC_LIB/$soname"
  fi
done

# libc_nonshared + GROUP script (fixes atexit)
NONSHARED=$(cc -print-file-name=libc_nonshared.a)
if [[ -f "$NONSHARED" ]]; then
  cp -f "$NONSHARED" "$OUT/libc_nonshared.a"
  echo "  libc_nonshared.a"
fi
LDSO=$(cc -print-file-name=ld-linux-x86-64.so.2)
rm -f "$OUT/libc.so"
{
  echo "/* GNU ld script — do not replace with ELF symlink */"
  echo "GROUP ( libc.so.6 libc_nonshared.a AS_NEEDED ( $LDSO ) )"
} > "$OUT/libc.so"
echo "  wrote libc.so GROUP script"
file "$OUT/libc.so"   # must be ASCII text / linker script

# libgcc_s / libstdc++ for SDL bits that need them
for soname in libgcc_s.so.1 libstdc++.so.6; do
  p=$(cc -print-file-name="$soname")
  if [[ -e "$p" ]]; then
    ln -sfn "$p" "$OUT/$soname"
    # also plain names Roc may list
    base="${soname%%.so*}.so"
    ln -sfn "$p" "$OUT/$base" 2>/dev/null || true
    echo "  $soname -> $p"
  fi
done

echo "==> staged in $OUT"
ls -la "$OUT" | head -40
nm "$OUT/libhost.a" | grep -E ' (main|roc_alloc|roc_gfx_init)$' || true
test -f "$OUT/libgoose_gfx.a" && echo "has libgoose_gfx.a"
test -f "$OUT/libSDL3.a" && echo "has libSDL3.a"
