# goose-roc

A [goose lang](https://github.com/aardappel/goose) [roc platform](https://roc-lang.org/) template.

> [!IMPORTANT]
> In development, a WIP.
>
> Only tested against linux x64musl target.

## About

Let's you use goose lang as a host implementation for a roc platform.

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
./scripts/build-host.sh
```

Build Roc App:
```sh
run run app/main.roc
# hello from goose
# hello from roc
```

Bundle Roc Platform for redistribution:
```sh
roc bundle platform/main.roc
```

## Designs

- [ ] Idiomatic goose (no heap allocations)
- [ ] Roc with goose design constraints (no heap allocations)
- [x] Idiomatic roc
- [x] Goose with C malloc heap allocations
