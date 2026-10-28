{
  description = "Goose v2026.3 prebuilt (TinyCC JIT via FHS on NixOS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/3ec636362e1816bc2f0888fa0fa2c69f1bc9e504";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              goose-unwrapped = final.callPackage ./package.nix { };

              goose = final.buildFHSEnv {
                pname = "goose";
                version = "2026.3";
                targetPkgs = p: [
                  p.goose-unwrapped
                  p.glibc
                  p.glibc.dev
                  p.gcc.cc.lib
                  p.gcc
                  p.binutils
                ];
                runScript = "goose";
                meta = final.goose-unwrapped.meta // {
                  description = "Goose + TinyCC JIT (FHS for NixOS libc/headers)";
                };
              };
            })
          ];
        };
      in
      {
        legacyPackages = pkgs;

        packages = {
          default = pkgs.goose;
          goose = pkgs.goose;
          goose-unwrapped = pkgs.goose-unwrapped;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.goose}/bin/goose";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.goose
            pkgs.cmake
            pkgs.ninja
            pkgs.gcc
            pkgs.gnumake
            pkgs.pkg-config
            pkgs.git
            pkgs.python3
            pkgs.bashInteractive
          ];
          shellHook = ''
            echo "Goose FHS shell — try: goose /tmp/t.goose"
          '';
        };
      });
}
