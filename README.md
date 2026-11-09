# Goose-Roc

A goose lang roc platform template.

> [!IMPORTANT]
> Experimental! In development, a WIP. Only tested on nixos against linux x64glibc target.

## About

Let's you use goose lang as a host implementation for a roc platform.

- Goose [[homepage](https://aardappel.github.io/goose/index.html)] [[github](https://github.com/aardappel/goose/)]
- Roc [[homepage](https://roc-lang.org/)] [[github](https://github.com/roc-lang/)]

## APIs

- [ ] **Bump** - roc app configurable, goose host bump buffer policy (faster malloc substitution.)
- [ ] **Std** (random)
- [ ] **Audio** via SDL3
- [ ] **Gfx** (Shaders, Device, window, frames, Input, Buffers, Textures, samplers, Pipelines, drawing, compute, matrices) via SDL3
- [ ] **Math**
- [ ] **Os** via Linux, Windows & MacOS kernal syscalls.
- [ ] **Physics** (Errors, Values, Worlds, Bodies, Shapes, Geometry, Joints, Events, Queries, character_mover, recording & replay) via Box3D
- [ ] **UI** (Errors, Contexts, Input, Text rendering, Game HUDs, Fonts, Windows, Layout, Groups, Trees, List views, widgets, text editing, popups, combo boxes, menus, tooltops, charts, style, colors, images, rectangles, drawing, render) via SDL3
- [ ] **Network** [[Issue#113](https://github.com/aardappel/goose/issues/113)] [[Issue#165](https://github.com/aardappel/goose/issues/165)] [[kaitk/goose-http](https://github.com/kaitk/goose-http)/[shim/net.c](https://github.com/kaitk/goose-http/blob/main/shim/net.c)]

## Targets

- [ ] **Linux** (x64glibc)
- [ ] **Windows**
- [ ] **MacOS**
- [ ] **Wasm** [[Issue#134](https://github.com/aardappel/goose/issues/134)] [[compusophy/goose-wasm](https://github.com/compusophy/goose-wasm)]

## Build & Run

Install Goose, Roc & C compiler:
```sh
nix run github:lukewilliamboswell/roc-blueprint/0.11.0 -- shell
```

Generate Glue & Build Goose Host:
> [!IMPORTANT]
> The v2026.3 goose release dynamically links SDL3 & glibc. So on NixOS you must use `nix-ld` or `steam-run`, to run the app, should you need to call any of those dependencies.
> It's possible to build against `x64musl` for a statically linked executable, but then we also need to provide statically linked goose dependencies, and thus provide statically linked releases.
```sh
./scripts/build-host-goose-pure-glibc.sh
```

Build & Run Roc App:
```sh
roc build app/main.roc
```
```
0 errors and 0 warnings found in 213ms while successfully building:

    main
```

Build & Run Mini Doom Port:
```sh
./scripts/build-mini-doom.sh
```

> [!IMPORTANT]
> Depends on dynamically linked glibc (SDL3), so on NixOS you must use `nix-ld` or `steam-run`, to run the app.

Steam run:
```sh
cd app/mini_doom
NIXPKGS_ALLOW_UNFREE=1 nix shell nixpkgs#steam-run --impure -c \
  steam-run env SDL_VIDEODRIVER=x11 \
  VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json \
  ./main
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
