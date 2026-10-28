# goose-roc

A [goose lang](https://github.com/aardappel/goose) [roc platform](https://roc-lang.org/) template.

> [!IMPORTANT]
> In development, a WIP.
>
> Only tested against linux x64musl target.

## About

Let's you use goose lang as a host implementation for a roc platform.

## Flavors

This project has two host implementation flavours.

- `hosts/goose-pure` Pure idiomatic goose, no heap allocations, there may be design constraints on what the platform & roc apps are allowed to do.
- `hosts/c-bridge` Goose with C malloc heap allocations, if you want to use idiomatic Roc today, you can use the existing `CGlue.roc`.

## Build & Run

Install Goose, Roc & C compiler:

```sh
nix run github:lukewilliamboswell/roc-blueprint/0.8.0 -- shell
roc version
goose version
zig version
# Roc compiler version nightly-2026-10-21-5349569
# goose runtime 4d3da949e563
# 0.17.0
```

Build Goose Host:
```sh
./scripts/build-host-goose-pure.sh
# OR
./scripts/build-host-c-bridge.sh
```

Build Roc App:
```sh
roc build app/main.roc && ./main
#0 errors and 0 warnings found in 276ms while successfully building:
#
#    main
#goose-pure: bump-only host, no libc heap
#hello from roc
#goose runtime error: goose-pure: bump pointer as u64 not wired (/home/anon/Projects/goose-roc/hosts/goose-pure/host.goose:20)
```
