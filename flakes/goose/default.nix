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
        goose = final.callPackage ./package.nix { };
      })
    ];
  };
in
pkgs
