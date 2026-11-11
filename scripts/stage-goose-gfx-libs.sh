#!/usr/bin/env bash
# Stage libgoose_*.a + libSDL3.a into platform/targets-out/x64glibc
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="${OUT:-$ROOT/platform/targets-out/x64glibc}"
CACHE="${GOOSE_HOME:-$HOME/.cache/goose-home}"
mkdir -p "$OUT"

need=(libgoose_gfx.a libgoose_audio.a libgoose_ui.a libSDL3.a)

stage_one() {
  local name="$1"
  local found=""

  # 1) Already staged
  if [[ -f "$OUT/$name" ]]; then
    echo "  keep $OUT/$name"
    return 0
  fi

  # 2) goose --gfx-link cc response file
  if command -v goose >/dev/null 2>&1; then
    local rsp
    if rsp=$(goose --gfx-link cc 2>/dev/null) && [[ -n "$rsp" && -f "$rsp" ]]; then
      found=$(tr ' \t' '\n' < "$rsp" | grep -E "/${name}$|^${name}$" | head -1 || true)
      if [[ -n "$found" && -f "$found" ]]; then
        cp -f "$found" "$OUT/$name"
        echo "  $name <- $found  (from --gfx-link)"
        return 0
      fi
    fi
  fi

  # 3) Search GOOSE_HOME build tree (newest match)
  found=$(find "$CACHE" -type f -name "$name" 2>/dev/null | head -1 || true)
  if [[ -n "$found" ]]; then
    cp -f "$found" "$OUT/$name"
    echo "  $name <- $found  (from GOOSE_HOME)"
    return 0
  fi

  # 4) Official/store layout next to goose binary
  local gbin
  gbin=$(command -v goose 2>/dev/null || true)
  if [[ -n "$gbin" ]]; then
    local base
    base=$(dirname "$(readlink -f "$gbin" 2>/dev/null || echo "$gbin")")
    for cand in \
      "$base/pkg/gfx/lib/$name" \
      "$base/../pkg/gfx/lib/$name" \
      "$base/pkg/gfx/$name"
    do
      if [[ -f "$cand" ]]; then
        cp -f "$cand" "$OUT/$name"
        echo "  $name <- $cand  (beside goose)"
        return 0
      fi
    done
  fi

  echo "error: cannot find $name" >&2
  echo "  Build the gfx package once, e.g.:" >&2
  echo "    export GOOSE_HOME=$CACHE" >&2
  echo "    cd $ROOT/app/mini_doom && goose build mini_doom.goose" >&2
  echo "  Needs cmake + X11/xcb headers on PATH." >&2
  return 1
}

echo "==> stage goose gfx → $OUT"
fail=0
for n in "${need[@]}"; do
  stage_one "$n" || fail=1
done
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
ls -la "$OUT"/libgoose_*.a "$OUT"/libSDL3.a
