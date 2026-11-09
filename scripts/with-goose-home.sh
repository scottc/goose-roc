#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export GOOSE_HOME="${GOOSE_HOME:-$HOME/.cache/goose-home}"
if [[ ! -f "$GOOSE_HOME/tcclib/include/tccdefs.h" ]]; then
  bash "$ROOT/scripts/setup-goose-home.sh"
fi
export GOOSE_HOME="${GOOSE_HOME:-$HOME/.cache/goose-home}"
exec "$@"
