import Host

SlicePool := {}.
{
    Slice : {
        pool_id : U64,
        offset  : U64,
        len     : U64,
    }

    Pool : {
        id : U64,
    }

    create! : U64 => Try(Pool, [PoolErr(Str)])
    create! = |capacity_hint| {
        id = Host.slice_pool_create!(capacity_hint)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
        Ok({ id })
    }

    destroy! : Pool => Try({}, [PoolErr(Str)])
    destroy! = |pool| {
        Host.slice_pool_destroy!(pool.id)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
        Ok({})
    }

    alloc! : Pool, U64 => Try(Slice, [PoolErr(Str)])
    alloc! = |pool, len| {
        Host.slice_pool_alloc!(pool.id, len)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
    }

    from_list! : Pool, List(U8) => Try(Slice, [PoolErr(Str)])
    from_list! = |pool, bytes| {
        Host.slice_pool_from_list!(pool.id, bytes)
            .map_err(|PoolErr(msg)| PoolErr(msg))?
    }

    len : Slice -> U64
    len = |s| s.len

    get_byte! : Slice, U64 => Try(U8, [PoolErr(Str), OutOfBounds])
    get_byte! = |s, i| {
        if i >= s.len {
            Err(OutOfBounds)
        } else {
            Host.slice_pool_get_byte!(s.pool_id, s.offset + i)
                .map_err(|PoolErr(msg)| PoolErr(msg))?
        }
    }
}
