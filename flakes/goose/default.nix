# Blueprint: import path { inherit system overlays; }
{ system ? builtins.currentSystem
, overlays ? [ ]
}:

let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/3ec636362e1816bc2f0888fa0fa2c69f1bc9e504.tar.gz";
    sha256 = "sha256-rZLrzrC6i+jnTAlvPZHogKDulY7WWDEv9hJeHieO7Zw=";
  };

  pkgs = import nixpkgs {
    inherit system;
    overlays = overlays ++ [
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
        };
      })
    ];
  };
in
pkgs
