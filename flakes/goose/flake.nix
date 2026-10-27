{
  description = "Goose v2026.3 prebuilt (+ nixpkgs with goose)";

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
              goose = final.callPackage ./package.nix { };
            })
          ];
        };
      in
      {
        # Blueprint looks for legacyPackages.<system>.bashInteractive
        legacyPackages = pkgs;

        packages = {
          default = pkgs.goose;
          goose = pkgs.goose;
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
        };
      });
}
