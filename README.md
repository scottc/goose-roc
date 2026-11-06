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
- [ ] **Network** [[Issue#113](https://github.com/aardappel/goose/issues/113)] [[Issue#165](https://github.com/aardappel/goose/issues/165)]

## Targets

- [ ] **Linux** (x64glibc)
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
./scripts/build-host-goose-pure-glibc.sh
```

Build & Run Roc App:
```sh
roc build app/main.roc && ./main
```
```
0 errors and 0 warnings found in 213ms while successfully building:

    main
Could not start dynamically linked executable: ./main
NixOS cannot run dynamically linked executables intended for generic
linux environments out of the box. For more information, see:
https://nix.dev/permalink/stub-ld
```

Build & Run Mini Doom Port:
```sh
./scripts/run-mini-doom.sh
```
```
roc build                                        2.4s
0 errors and 0 warnings found in 2.4s while successfully building:

    main
==> strip PT_INTERP
PT_INTERP -> PT_NULL (phdr 1)
./main: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, for GNU/Linux 3.10.0, BuildID[sha1]=a3d84bf64bbe2340a55f98035861e4777707798a, with debug_info, not stripped
build-mini-doom ok: /home/anon/Projects/goose-roc/app/mini_doom/main
==> running ./main
mini doom: reading assets/freedoom1-e1m1.wad
mini doom: actors=291 at (-416, 256)
Segmentation fault         (core dumped) ./scripts/run-mini-doom.sh
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
