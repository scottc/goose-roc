app [config] { pf: platform "https://github.com/lukewilliamboswell/roc-blueprint/releases/download/0.11.0/EuSPs8vc71qJNFg29YzegvVRL1bR9pKqUYDHFiSCPTQ1.tar.zst" }

import pf.Recipes

config = [
    Name("goose-roc"),

    Packages("nix", From(NixPackages("github:NixOS/nixpkgs/nixos-unstable"))),
    Packages("goose", From(NixPackages("path:./flakes/goose"))),

    Environment("dev", [
        Programs([
            Fetch("roc", Recipes.roc_nightly("nightly-2026-10-28-bad769b")),
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
