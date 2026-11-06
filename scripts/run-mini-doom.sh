#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
bash "$ROOT/scripts/build-mini-doom.sh"
cd "$ROOT/app/mini_doom"
echo "==> running ./main"
exec ./main "$@"
