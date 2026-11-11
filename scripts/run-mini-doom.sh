#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT/app/mini_doom"

test -f ./main || {
  echo "missing ./main — build first" >&2
  exit 1
}

export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-x11}"
export DISPLAY="${DISPLAY:-:0}"
export LD_LIBRARY_PATH="/run/opengl-driver/lib:${LD_LIBRARY_PATH:-}"

run_bin() {
  if command -v steam-run-free >/dev/null 2>&1; then
    exec steam-run-free ./main "$@"
  fi
  if command -v steam-run >/dev/null 2>&1; then
    exec steam-run ./main "$@"
  fi
  # last resort: pull steam-run into a transient shell
  exec nix shell --impure nixpkgs#steam-run -c steam-run ./main "$@"
}

run_bin "$@"

# #!/usr/bin/env bash
# set -euo pipefail
# ROOT=$(cd "$(dirname "$0")/.." && pwd)
# bash "$ROOT/scripts/build-mini-doom.sh"
# cd "$ROOT/app/mini_doom"
#
# export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-x11}"
# export DISPLAY="${DISPLAY:-:0}"
# export LD_LIBRARY_PATH="/run/opengl-driver/lib:$(nix eval --impure --raw --expr '
#   let pkgs = import <nixpkgs> {};
#   in pkgs.lib.makeLibraryPath [
#     pkgs.libx11 pkgs.libxext pkgs.libxcursor pkgs.libxi
#     pkgs.libxrandr pkgs.libxfixes pkgs.libxscrnsaver pkgs.libxxf86vm
#     pkgs.libxkbcommon pkgs.libGL pkgs.libglvnd pkgs.libffi
#     pkgs.dbus pkgs.systemd pkgs.vulkan-loader pkgs.mesa
#     pkgs.glibc pkgs.gcc.cc.lib
#   ]
# '):${LD_LIBRARY_PATH:-}"
# export VK_ICD_FILENAMES="${VK_ICD_FILENAMES:-/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json}"
#
# echo "==> INTERP=$(patchelf --print-interpreter ./main 2>/dev/null || true)"
# echo "==> run (needs programs.nix-ld.enable or steam-run)"
# exec ./main "$@"
