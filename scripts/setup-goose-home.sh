#!/usr/bin/env bash
set -euo pipefail

export GOOSE_HOME="${GOOSE_HOME:-$HOME/.cache/goose-home}"
mkdir -p "$GOOSE_HOME"

STORE="${GOOSE_STORE:-}"
if [[ -z "$STORE" || ! -d "$STORE/tcclib" ]]; then
  if ! command -v goose >/dev/null; then
    echo "error: goose not on PATH" >&2
    exit 1
  fi
  BIN=$(command -v goose)
  if [[ -x "$(dirname "$BIN")/.goose-wrapped" ]]; then
    REAL=$(readlink -f "$(dirname "$BIN")/.goose-wrapped")
    STORE=$(dirname "$(dirname "$REAL")")
  else
    STORE=$(dirname "$(dirname "$(readlink -f "$BIN")")")
  fi
fi

if [[ ! -d "$STORE/tcclib" ]]; then
  echo "error: no tcclib under STORE=$STORE" >&2
  exit 1
fi

echo "GOOSE_STORE=$STORE"
echo "GOOSE_HOME=$GOOSE_HOME"
ls -la "$STORE/tcclib" | head
ls -la "$STORE/tcclib/include/tccdefs.h"

sync_dir() {
  local name=$1
  local src="$STORE/$name"
  local dst="$GOOSE_HOME/$name"
  [[ -e "$src" ]] || return 0

  if [[ -e "$dst" ]]; then
    chmod -R u+w "$dst" 2>/dev/null || true
    rm -rf "$dst"
  fi

  # -L: dereference symlinks so TCC gets real files
  if command -v rsync >/dev/null; then
    mkdir -p "$dst"
    rsync -aL "$src"/ "$dst"/
  else
    cp -aL "$src" "$dst" 2>/dev/null || {
      # fallback: mkdir + copy contents
      mkdir -p "$dst"
      cp -aL "$src"/. "$dst"/
    }
  fi
  chmod -R u+w "$dst" 2>/dev/null || true
  echo "  synced $name"
}

sync_dir stdlib
sync_dir tcclib
sync_dir runtime

mkdir -p "$GOOSE_HOME/pkg" "$GOOSE_HOME/build"
chmod -R u+w "$GOOSE_HOME/pkg" "$GOOSE_HOME/build" 2>/dev/null || true

# Hard requirement
TCCDEF="$GOOSE_HOME/tcclib/include/tccdefs.h"
if [[ ! -f "$TCCDEF" ]]; then
  echo "error: still missing $TCCDEF" >&2
  echo "--- GOOSE_HOME/tcclib ---" >&2
  find "$GOOSE_HOME/tcclib" -maxdepth 3 -type f 2>/dev/null | head -40 >&2 || true
  echo "--- forcing include copy ---" >&2
  mkdir -p "$GOOSE_HOME/tcclib/include"
  cp -L "$STORE/tcclib/include/tccdefs.h" "$GOOSE_HOME/tcclib/include/tccdefs.h"
  # copy rest of include if present
  if [[ -d "$STORE/tcclib/include" ]]; then
    cp -aL "$STORE/tcclib/include"/. "$GOOSE_HOME/tcclib/include"/
  fi
  chmod -R u+w "$GOOSE_HOME/tcclib"
fi

test -f "$TCCDEF" || {
  echo "error: cannot install tccdefs.h" >&2
  exit 1
}
echo "tccdefs.h ok: $TCCDEF"
ls -la "$TCCDEF"
goose version
