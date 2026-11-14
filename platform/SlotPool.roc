## SlotPool – host-managed pool of individually allocatable slots.
##
## Typical use:
##   - Actors, map things, particles, UI widgets, AST nodes, …
##   - You allocate a slot, get a stable Index/Handle back.
##   - Recursive code only ever manipulates the cheap Index.
##
## Two flavours are provided:
##   - Fixed-size slots (fastest, simplest)
##   - Variable-size slots (slightly more flexible)

module [
    Pool,
    Index,
    create_fixed!,
    create_var!,
    destroy!,
    alloc_fixed!,
    alloc_var!,
    free!,
    get_fixed,
    set_fixed,
    get_var_slice,
    len,
    capacity,
]

## Opaque pool
Pool : { id : U64 }

## Stable handle to a live slot. Never reuse an Index after free! unless the
## pool explicitly supports generational indices (host may add a generation).
Index : {
    pool_id : U64,
    slot    : U64,
}

## Create a pool of fixed-size slots.
## slot_size  = bytes per slot
## capacity   = maximum number of live slots
create_fixed! : U64, U64 => Try(Pool, [PoolErr(Str)])
create_fixed! = |slot_size, capacity| {
    Host.slot_pool_create_fixed!(slot_size, capacity)
}

## Create a pool that can hold variable-size objects (internally a bump or
## free-list of blocks). capacity_hint is a byte hint.
create_var! : U64 => Try(Pool, [PoolErr(Str)])
create_var! = |capacity_hint_bytes| {
    Host.slot_pool_create_var!(capacity_hint_bytes)
}

destroy! : Pool => Try({}, [PoolErr(Str)])
destroy! = |pool| {
    Host.slot_pool_destroy!(pool.id)
}

## Allocate one fixed-size slot. Returns a stable Index.
alloc_fixed! : Pool => Try(Index, [PoolErr(Str)])
alloc_fixed! = |pool| {
    Host.slot_pool_alloc_fixed!(pool.id)
}

## Allocate a variable-size slot of exactly `bytes` bytes.
alloc_var! : Pool, U64 => Try(Index, [PoolErr(Str)])
alloc_var! = |pool, bytes| {
    Host.slot_pool_alloc_var!(pool.id, bytes)
}

## Return a slot to the pool. After this the Index is invalid.
free! : Pool, Index => Try({}, [PoolErr(Str)])
free! = |pool, idx| {
    if idx.pool_id != pool.id {
        Err(PoolErr("index from different pool"))
    } else {
        Host.slot_pool_free!(pool.id, idx.slot)
    }
}

## ------------------------------------------------------------------
## Accessors (fixed-size)
## ------------------------------------------------------------------

## Read the raw bytes of a fixed slot into a temporary List (small!).
get_fixed : Pool, Index, U64 -> Try(List(U8), [PoolErr(Str), OutOfBounds])
get_fixed = |pool, idx, expected_size| {
    Host.slot_pool_get_fixed(pool.id, idx.slot, expected_size)
}

## Write raw bytes into a fixed slot.
set_fixed : Pool, Index, List(U8) => Try({}, [PoolErr(Str), OutOfBounds])
set_fixed = |pool, idx, bytes| {
    Host.slot_pool_set_fixed(pool.id, idx.slot, bytes)
}

## ------------------------------------------------------------------
## Accessors (variable-size) – returns a Slice into the pool
## ------------------------------------------------------------------

get_var_slice : Pool, Index -> Try(SlicePool.Slice, [PoolErr(Str)])
get_var_slice = |pool, idx| {
    Host.slot_pool_get_var_slice(pool.id, idx.slot)
}

## Diagnostics
len : Pool -> U64
len = |pool| Host.slot_pool_len(pool.id)

capacity : Pool -> U64
capacity = |pool| Host.slot_pool_capacity(pool.id)
