#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/platform/targets-out/x64musl"
mkdir -p "$OUT" "$ROOT/vendor/goose-gfx"

command -v goose >/dev/null || { echo "goose not on PATH"; exit 1; }

RSP=$(goose --gfx-link cc)
echo "goose --gfx-link cc → $RSP"
cp -f "$RSP" "$ROOT/vendor/goose-gfx/link-cc.rsp"
# also keep a copy next to host inputs for inspection
cp -f "$RSP" "$OUT/goose-gfx-link-cc.rsp"

echo "---- response file ----"
cat "$RSP"
echo "-----------------------"

# Copy any absolute .a / .o paths referenced in the rsp into OUT
while read -r tok; do
  case "$tok" in
    *.a|*.o)
      if [[ -f "$tok" ]]; then
        base=$(basename "$tok")
        cp -f "$tok" "$OUT/$base"
        echo "copied $base"
      fi
      ;;
  esac
done < <(tr ' \n' '\n' < "$RSP" | sed '/^$/d')

echo "vendor-goose-gfx: done (see $OUT)"
