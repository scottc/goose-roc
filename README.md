# Goose-Roc

A goose lang roc platform template.

> [!IMPORTANT]
> Experimental! In development, a WIP. Only tested against linux x64musl target.

## About

Let's you use goose lang as a host implementation for a roc platform.

- Goose [[homepage](https://aardappel.github.io/goose/index.html)] [[github](https://github.com/aardappel/goose/)]
- Roc [[homepage](https://roc-lang.org/)] [[github](https://github.com/roc-lang/)]

## APIs

- [ ] **Bump** - roc app configurable, goose host bump buffer policy (faster malloc substitution.)
- [ ] **Audio** via SDL3
- [ ] **Gfx** via SDL3
- [ ] **Math**
- [ ] **Os** via Linux, Windows & MacOS kernal syscalls.
- [ ] **Physics** via Box3D
- [ ] **UI** via SDL3
- [ ] **Network** [[Issue#113](https://github.com/aardappel/goose/issues/113)] [[Issue#165](https://github.com/aardappel/goose/issues/165)]

## Targets

- [ ] **Linux**
- [ ] **Windows**
- [ ] **MacOS**
- [ ] **Wasm** [[Issue#134](https://github.com/aardappel/goose/issues/134)]

## Build & Run

Install Goose, Roc & C compiler:
```sh
nix run github:lukewilliamboswell/roc-blueprint/0.11.0 -- shell
```

Generate Glue & Build Goose Host:
```sh
./scripts/build-host-goose-pure.sh
```

Build Roc App:
```sh
roc build app/main.roc && ./main
```
```
0 errors and 0 warnings found in 244ms while successfully building:

    main
hello from roc
```

## GooseGlue.roc

```sh
roc glue glue/GooseGlue.roc host/ platform/main.roc
```
```
Glue spec returned 2 file(s):
  Wrote: host/roc_platform_abi_types.goose
  Wrote: host/roc_platform_abi_exports.goose
```
