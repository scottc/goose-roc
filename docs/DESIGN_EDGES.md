# Design edges — pure Goose Roc host + GooseGlue

## Working
- Glue types + export wrappers + host_impl composition (concat or multi-file)
- roc_main(RocList), goose_init(argc, argv)
- SSO + long RocStr (gs_ffi_bytes), bump roc_alloc/realloc, configure_arena
- Hosted stdout/stderr Try (32-byte padded layouts)

## By design / structural (do not “fix” in glue)
1. **No Zig-style package import of glue into host** on Goose v2026.3  
   Composition = concat or multi-file single program.

2. **Grow-only bump allocation ⇒ roc_dealloc is a no-op**  
   Goose data stacks don’t free; Roc RC still runs; memory lives until process exit.

3. **C polyfills on this pin**  
   gs_ffi_bytes, gs_addr_of_u8, gs_memmove_u64 — not in v2026.3 stdlib ffi.

4. **Nonsense alignment from Roc**  
   Host clamps to 8/16/32/64; not representable as a pure type rule in glue.

5. **No comptime layout asserts**  
   Glue emits size64 comments; Goose cannot mirror Zig @sizeOf checks.

6. **RC identity vs bump**  
   Safe only while bump allocation outlives roc_main and dealloc never reuses addresses incorrectly  
   (never-reuse bump is OK; a future free-list would not be).

## Glue is not responsible for
- Printing / SSO decode
- Bump policy
- entry.c / crt / musl link

## Targets

| Target | Status |
|--------|--------|
| **x86_64-linux musl** (`x64musl`) | Supported (this repo’s host + vendor crt) |
| **WASM** | **Not supported** for this platform host |

### WASM
- Goose has a **design note** on WebAssembly (address-space / stack partitioning), not a drop-in `wasm32` Roc platform target here.
- Our host is **musl static + crt1 + zig cc**, bump arena via native pointers, and **C polyfills** (`gs_ffi_*`) — none of that is wired for WASM.
- Blessed packages (**gfx / audio / ui / physics**) assume native SDL/GPU stacks; not available under WASM in this template.
- **Future:** a separate `targets-out/wasm32` + different entry/alloc story; out of scope until Goose’s WASM story and Roc’s wasm host align.
