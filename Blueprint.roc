app [config] {
    pf: platform "https://github.com/lukewilliamboswell/roc-blueprint/releases/download/0.11.0/EuSPs8vc71qJNFg29YzegvVRL1bR9pKqUYDHFiSCPTQ1.tar.zst",
}

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
            "nix#zig",
            "nix#patchelf",
            "nix#file",
            "nix#gdb",
            "nix#binutils",
            "nix#gcc",
            "nix#bash",
            "nix#coreutils",
            "nix#findutils",
            "nix#gnused",
            "nix#git",
            "nix#python3",
        ]),
    ]),

    Shell("default", [Use("dev")]),

    Task("roc-version", [Use("dev"), Run(["roc", "version"])]),
    Task("goose-version", [Use("dev"), Run(["goose", "version"])]),
    Task("status", [Use("dev"), Run(["git", "status", "--short"])]),

    Task("host-glibc", [
        Use("dev"),
        Run(["bash", "scripts/build-host-goose-pure-glibc.sh"]),
    ]),

    Task("build-mini-doom", [
        Use("dev"),
        Run(["bash", "scripts/build-mini-doom.sh"]),
    ]),

    Task("run-mini-doom", [
        Use("dev"),
        Run(["bash", "scripts/run-mini-doom.sh"]),
    ]),

    Task("nixos-fix-exe", [
        Use("dev"),
        Run(["bash", "scripts/nixos-fix-exe.sh"]),
    ]),

    Task("inspect-mini-doom", [
        Use("dev"),
        Run(["bash", "scripts/inspect-mini-doom.sh"]),
    ]),

    Task("gdb-mini-doom", [
        Use("dev"),
        Run(["bash", "scripts/gdb-mini-doom.sh"]),
    ]),
]
