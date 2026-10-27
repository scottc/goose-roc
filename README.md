# goose-roc

A [goose lang](https://github.com/aardappel/goose) [roc platform](https://roc-lang.org/) template.

> [!IMPORTANT]
> In development, a WIP.
>
> Only tested against linux x64musl target.

## About

Let's you use goose lang as a host implementation for a roc platform.

## Build & Run

Install goose & roc:

```sh
nix run github:lukewilliamboswell/roc-blueprint/0.8.0 -- shell
roc version
goose version
```

Build goose host:
```sh
./scripts/build-host.sh
```

Build roc app:
```sh
run run app/main.roc
```
```
hello from goose
hello from roc
```

Bundle roc platform:
```sh
roc bundle platform/main.roc
```
