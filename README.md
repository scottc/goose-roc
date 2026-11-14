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

Install Goose, Roc & C compiler; and then build and run the mini-doom example:
```sh
nix run github:lukewilliamboswell/roc-blueprint/0.11.0 -- run build-host-glibc
nix run github:lukewilliamboswell/roc-blueprint/0.11.0 -- run build-mini-doom
nix run github:lukewilliamboswell/roc-blueprint/0.11.0 -- run run-mini-doom
```
> [!NOTE]
> NixOS:
>
> Currently depends on dynamically linked glibc (SDL3).
>
> On NixOS one must use `nix-ld`, `steam-run-free` or `steam-run`, to run the app (which is how the build & run script is configured).

## GooseGlue.roc

```sh
roc glue glue/GooseGlue.roc host/ platform/main.roc
```
```
Glue spec returned 2 file(s):
  Wrote: host/roc_platform_abi_types.goose
  Wrote: host/roc_platform_abi_exports.goose
```
