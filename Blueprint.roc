app [config] {
    pf: platform "https://github.com/lukewilliamboswell/roc-blueprint/releases/download/0.8.0/FbJymjYdCxx9vqMcau7r4tQfeAbnVGqqJoYrLGqPCqKu.tar.zst",
}

import pf.Recipes

config = [
    Name("goose-roc"),

    Packages("nix", From(NixPackages("github:NixOS/nixpkgs/nixos-unstable"))),
    Packages("goose", From(NixPackages("path:./flakes/goose"))),

    Environment("dev", [
        Programs([
            Fetch("roc", Recipes.roc_nightly("nightly-2026-10-21-5349569")),
        ]),
        Tools([
            "goose#goose",
            "nix#zig", # for zig cc x64musl

            # "nix#cmake",
            # "nix#ninja",
            # "nix#gcc",
            # "nix#gnumake",
            # "nix#pkg-config",
            # "nix#git",
            # "nix#python3",
        ]),
    ]),

    Shell("default", [Use("dev")]),

    Task("roc-version", [Use("dev"), Run(["roc", "version"])]),
    Task("goose-version", [Use("dev"), Run(["goose", "version"])]),
    Task("status", [Use("dev"), Run(["git", "status", "--short"])]),
]
