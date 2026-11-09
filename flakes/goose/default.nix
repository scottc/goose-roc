{
  system ? builtins.currentSystem,
  overlays ? [ ],
}:

let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    sha256 = "1671kxf56nz3bihkrim96jh3rz0hpxym90sqyz3i1zh7abvf122s";
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
