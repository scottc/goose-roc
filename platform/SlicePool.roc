## SlicePool – host-managed pool of contiguous byte slices.
##
## Idiomatic use:
##   - Create one pool at startup for all large immutable (or rarely-mutated) assets.
##   - Load files or allocate buffers into the pool.
##   - Hand out cheap Slice values (base + length) to the rest of the program.
##   - Recursive / hot code only ever sees the Slice, never the pool or a List(U8).
##
## Goose benefits preserved:
##   - Backing storage is outside ordinary data stacks.
##   - No growable crosses recursion.
##   - Freeing the whole pool is O(1).

module [
    Pool,
    Slice,
    create!,
    destroy!,
    alloc!,
    load_file!,
    slice_len,
    slice_get,
    slice_sub,
    slice_as_list,          # only for small results / debugging
]

## Opaque pool handle (host owns the real memory)
Pool : { id : U64 }

## Zero-cost view into pool memory. Safe to pass anywhere, including recursion.
Slice : {
    pool_id : U64,
    offset  : U64,
    len     : U64,
}

## Create a pool with a capacity hint (bytes). Host may round up.
create! : U64 => Try(Pool, [PoolErr(Str)])
create! = |capacity_hint| {
    # host effect
    Host.slice_pool_create!(capacity_hint)
}

## Destroy the pool and all slices derived from it.
## After this call every Slice from the pool is invalid.
destroy! : Pool => Try({}, [PoolErr(Str)])
destroy! = |pool| {
    Host.slice_pool_destroy!(pool.id)
}

## Allocate a fresh zeroed (or uninitialised) slice of exactly `len` bytes.
alloc! : Pool, U64 => Try(Slice, [PoolErr(Str)])
alloc! = |pool, len| {
    Host.slice_pool_alloc!(pool.id, len)
}

## Read an entire file into the pool. Returns a Slice covering the file contents.
load_file! : Pool, Str => Try(Slice, [OsErr(Str), PoolErr(Str)])
load_file! = |pool, path| {
    Host.slice_pool_load_file!(pool.id, path)
}

## ------------------------------------------------------------------
## Pure helpers (no effects)
## ------------------------------------------------------------------

slice_len : Slice -> U64
slice_len = |s| s.len

## Bounds-checked byte read
slice_get : Slice, U64 -> Try(U8, [OutOfBounds])
slice_get = |s, i| {
    if i >= s.len {
        Err(OutOfBounds)
    } else {
        Host.slice_pool_get_byte(s.pool_id, s.offset + i)
    }
}

## Sub-slice (zero-cost)
slice_sub : Slice, U64, U64 -> Try(Slice, [OutOfBounds])
slice_sub = |s, start, len| {
    if start + len > s.len {
        Err(OutOfBounds)
    } else {
        Ok({
            pool_id: s.pool_id,
            offset: s.offset + start,
            len,
        })
    }
}

## Escape hatch: copy a (small!) slice into an ordinary List(U8).
## Only use for results that are known to be tiny.
slice_as_list : Slice -> Try(List(U8), [PoolErr(Str)])
slice_as_list = |s| {
    Host.slice_pool_to_list(s.pool_id, s.offset, s.len)
}
