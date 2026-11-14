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
            "nix#cmake",
            "nix#gnumake",
            "nix#gcc",
            "nix#pkg-config",
            "nix#patchelf",
            "nix#file",
            "nix#gdb",
            "nix#binutils",
            "nix#bash",
            "nix#coreutils",
            "nix#findutils",
            "nix#gnused",
            "nix#git",
            "nix#libx11",
            "nix#libxext",
            "nix#libxcursor",
            "nix#libxi",
            "nix#libxrandr",
            "nix#libxfixes",
            "nix#libxrender",
            "nix#libxscrnsaver",
            "nix#libxxf86vm",
            "nix#libxtst",
            "nix#libxkbcommon",
            "nix#libxcb",
            "nix#wayland",
            "nix#wayland-protocols",
            "nix#libffi",
            "nix#dbus",
            "nix#udev",
            "nix#libGL",
            "nix#libglvnd",
            "nix#alsa-lib",
            "nix#vulkan-headers",
            "nix#vulkan-loader",
        ]),
    ]),

    Shell("default", [Use("dev")]),

    Task("setup-goose-home", [Use("dev"), Run(["bash", "scripts/setup-goose-home.sh"])]),
    Task("goose-version", [Use("dev"), Run(["bash", "scripts/with-goose-home.sh", "goose", "version"])]),
    Task("tcc-smoke", [
        Use("dev"),
        Run([
            "bash", "-c",
            "export GOOSE_HOME=$HOME/.cache/goose-home; bash scripts/setup-goose-home.sh; printf 'fn main() { print(\"tcc ok\"); }\\n' > /tmp/t.goose; goose /tmp/t.goose",
        ]),
    ]),
    Task("build-host-glibc", [Use("dev"), Run(["bash", "scripts/build-host-goose-pure-glibc.sh"])]),
    Task("build-mini-doom", [Use("dev"), Run(["bash", "scripts/build-mini-doom.sh"])]),
    Task("run-mini-doom", [Use("dev"), Run(["bash", "scripts/run-mini-doom.sh"])]),
    Task("goose-mini-doom", [
        Use("dev"),
        Run(["bash", "scripts/with-goose-home.sh", "goose", "app/mini_doom/mini_doom.goose"]),
    ]),
]
