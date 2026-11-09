{
  description = "Goose v2026.4 prebuilt (+ nixpkgs overlay)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              goose = final.callPackage ./package.nix { };
            })
          ];
        };
      in
      {
        # Blueprint: legacyPackages.<system>.bashInteractive
        legacyPackages = pkgs;

        packages = {
          default = pkgs.goose;
          goose = pkgs.goose;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.goose}/bin/goose";
        };

        # Full stdenv shell for building goose_gfx (CMake + X11/xcb)
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            goose
            cmake gnumake pkg-config gcc
            libx11 libxext libxcursor libxi libxrandr libxfixes libxrender
            libxscrnsaver libxxf86vm libxtst
            libxkbcommon libxcb
            wayland wayland-protocols
            libffi dbus udev
            libGL libglvnd
            alsa-lib
            vulkan-headers vulkan-loader
            zig
          ];
          shellHook = ''
            export GOOSE_HOME="''${GOOSE_HOME:-$HOME/.cache/goose-home}"
            if [ ! -f "$GOOSE_HOME/tcclib/include/tccdefs.h" ]; then
              echo "hint: run scripts/setup-goose-home.sh (missing tccdefs.h under GOOSE_HOME)"
            fi
            echo "GOOSE_HOME=$GOOSE_HOME"
            goose version 2>/dev/null || true
          '';
        };

        devShells.gfx = pkgs.mkShell {
          packages = with pkgs; [
            goose cmake gnumake pkg-config gcc
            libx11 libxext libxcursor libxi libxrandr libxfixes libxrender
            libxscrnsaver libxxf86vm libxtst libxkbcommon libxcb
            wayland wayland-protocols libffi dbus udev
            libGL libglvnd alsa-lib vulkan-headers vulkan-loader
          ];
          shellHook = ''
            export GOOSE_HOME="''${GOOSE_HOME:-$HOME/.cache/goose-home}"
          '';
        };
      });
}
