# Goose + Roc design constraints (mini-doom / similar apps)

## Core Goose rules that bite us

- No general heap. All dynamic data lives on a small number of data stacks.
- At most **one resizable** (List, growable array, …) may be live per stack.
- A recursive function **must not** keep a growable live across the recursive call.
  Scratch must end before the call; data that outlives the call is passed as a pool or view.
- Freeing is scope-based ( (one store). Intermediate lists from pure `List.append` recursion are therefore extremely expensive / fatal.

## Idiomatic patterns we should prefer

1. **Views over materialised lists**
   - Store `{start, size}` (or a slice) into a master buffer.
   - Provide `get_xxx(i)` that parses one record on demand.
   - Used successfully for WAD directory and (partially) for linedefs.

2. **Single top-level owner for large buffers**
   - The WAD `List(U8)` should be the *only* large resizable, owned at the top of `main!`.
   - Never pass it into a recursive function that also grows another list.
   - Ideal: put it in a slice-pool / host mmap region that recursive code only borrows.

3. **Build large collections with push-style loops or pools, not pure recursive append**
   - Goose `for` + `.push` is the happy path.
   - When writing Roc that compiles to Goose, avoid deep `List.append` recursion for anything that can grow beyond a few dozen elements.

4. **Error / Result handling**
   - Keep `Try` / `match` shallow inside recursive functions; deep nesting of matches increases frame size and makes the “one resizable” analysis harder.

## Common pitfalls observed in this project

- Recursive `load_XXX_go` that does `List.append` → data-stack explosion (even at 16 GB).
- Holding the whole WAD `List(U8)` in a record that is closed over by recursive ray-cast / collision / loading code.
- Materialising intermediate `List(U8)` for every lump “just in case”.
- Mixing many small recursive builders that each keep their own accumulator while a large buffer is still live.

## Practical rules for this codebase

- Map geometry → pure views (`ld_start`, `vx_start`, …) + `get_line` / `vertex_at`.
- Things / actors → keep the list tiny or build it with a non-recursive / pooled approach.
- Renderer & collision → indexed loops over `map.ld_count`, never over a materialised `List(Line)`.
- Host platform should eventually offer either:
  - `Os.read_file_pool!` / mmap that returns a stable slice not on ordinary data stacks, or
  - an explicit slice-pool API for the WAD and similar assets.
