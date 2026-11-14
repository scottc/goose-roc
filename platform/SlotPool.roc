import Host

SlotPool := {}.
{
    Pool : {
        id : U64,
    }

    Index : {
        pool_id : U64,
        slot    : U64,
    }

    create_fixed! : U64, U64 => Try(Pool, [PoolErr(Str)])
    create_fixed! = |slot_size, capacity| {
        id = Host.slot_pool_create_fixed!(slot_size, capacity)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
        Ok({ id })
    }

    create_var! : U64 => Try(Pool, [PoolErr(Str)])
    create_var! = |capacity_hint_bytes| {
        id = Host.slot_pool_create_var!(capacity_hint_bytes)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
        Ok({ id })
    }

    destroy! : Pool => Try({}, [PoolErr(Str)])
    destroy! = |pool| {
        Host.slot_pool_destroy!(pool.id)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
        Ok({})
    }

    alloc_fixed! : Pool => Try(Index, [PoolErr(Str)])
    alloc_fixed! = |pool| {
        slot = Host.slot_pool_alloc_fixed!(pool.id)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
        Ok({ pool_id: pool.id, slot })
    }

    alloc_var! : Pool, U64 => Try(Index, [PoolErr(Str)])
    alloc_var! = |pool, bytes| {
        slot = Host.slot_pool_alloc_var!(pool.id, bytes)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
        Ok({ pool_id: pool.id, slot })
    }

    free! : Pool, Index => Try({}, [PoolErr(Str)])
    free! = |pool, idx| {
        if idx.pool_id != pool.id {
            Err(PoolErr("index from different pool"))
        } else {
            Host.slot_pool_free!(pool.id, idx.slot)
                .map_err(|PoolErr(msg)| PoolErr(msg))?
            Ok({})
        }
    }

    get_fixed! : Pool, Index, U64 => Try(List(U8), [PoolErr(Str), OutOfBounds])
    get_fixed! = |pool, idx, expected_size| {
        if idx.pool_id != pool.id {
            Err(PoolErr("index from different pool"))
        } else {
            Host.slot_pool_get_fixed!(pool.id, idx.slot, expected_size)
                .map_err(|PoolErr(msg)| PoolErr(msg))?
        }
    }

    set_fixed! : Pool, Index, List(U8) => Try({}, [PoolErr(Str), OutOfBounds])
    set_fixed! = |pool, idx, bytes| {
        if idx.pool_id != pool.id {
            Err(PoolErr("index from different pool"))
        } else {
            Host.slot_pool_set_fixed!(pool.id, idx.slot, bytes)
                .map_err(|PoolErr(msg)| PoolErr(msg))?
            Ok({})
        }
    }
}
