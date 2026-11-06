#!/usr/bin/env bash
set -euo pipefail
EXE="${1:?usage: strip-interp.sh <exe>}"
test -f "$EXE"
if patchelf --remove-interpreter "$EXE" 2>/dev/null; then
  echo "removed INTERP"
elif patchelf --set-interpreter /dev/null "$EXE" 2>/dev/null; then
  echo "set INTERP to /dev/null (may still fail)"
else
  echo "patchelf cannot clear INTERP on this version" >&2
  exit 1
fi
file "$EXE"
readelf -l "$EXE" | grep INTERP || echo "no INTERP ok"
