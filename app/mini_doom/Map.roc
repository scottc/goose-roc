import Wad

Map := {}.
{
    Line : {
        ax : F32,
        ay : F32,
        bx : F32,
        by : F32,
        flags : U64,
        special : U64,
        tag : U64,
        front : U64,
        back : U64,          # 65535 = no back
    }

    State : {
        wad       : List(U8),
        ld_start  : U64,     # byte offset of LINEDEFS
        ld_size   : U64,
        ld_count  : U64,     # number of linedefs
        vx_start  : U64,     # byte offset of VERTEXES
        vx_size   : U64,
    }

    empty : State
    empty = {
        wad: [],
        ld_start: 0,
        ld_size: 0,
        ld_count: 0,
        vx_start: 0,
        vx_size: 0,
    }

    ## Parse one vertex directly from the WAD
    vertex_at : State, U64 -> Try({ x : F32, y : F32 }, [WadErr(Str)])
    vertex_at = |map, idx| {
        off = map.vx_start + idx * 4
        if off + 4 > map.vx_start + map.vx_size {
            Err(WadErr("vertex oob"))
        } else {
            match Wad.i16le_f32(map.wad, off) {
                Err(e) => Err(e)
                Ok(x) => {
                    match Wad.i16le_f32(map.wad, off + 2) {
                        Err(e) => Err(e)
                        Ok(y) => Ok({ x, y })
                    }
                }
            }
        }
    }

    ## Parse one linedef (including its two vertices) on demand
    get_line : State, U64 -> Try(Line, [WadErr(Str)])
    get_line = |map, i| {
        if i >= map.ld_count {
            Err(WadErr("linedef oob"))
        } else {
            off = map.ld_start + i * 14
            match Wad.u16le(map.wad, off) {
                Err(e) => Err(e)
                Ok(ai) => {
                    match Wad.u16le(map.wad, off + 2) {
                        Err(e) => Err(e)
                        Ok(bi) => {
                            match Wad.u16le(map.wad, off + 4) {
                                Err(e) => Err(e)
                                Ok(flags) => {
                                    match Wad.u16le(map.wad, off + 6) {
                                        Err(e) => Err(e)
                                        Ok(special) => {
                                            match Wad.u16le(map.wad, off + 8) {
                                                Err(e) => Err(e)
                                                Ok(tag) => {
                                                    match Wad.u16le(map.wad, off + 10) {
                                                        Err(e) => Err(e)
                                                        Ok(front) => {
                                                            match Wad.u16le(map.wad, off + 12) {
                                                                Err(e) => Err(e)
                                                                Ok(back) => {
                                                                    match vertex_at(map, ai) {
                                                                        Err(e) => Err(e)
                                                                        Ok(va) => {
                                                                            match vertex_at(map, bi) {
                                                                                Err(e) => Err(e)
                                                                                Ok(vb) => {
                                                                                    Ok({
                                                                                        ax: va.x,
                                                                                        ay: va.y,
                                                                                        bx: vb.x,
                                                                                        by: vb.y,
                                                                                        flags,
                                                                                        special,
                                                                                        tag,
                                                                                        front,
                                                                                        back,
                                                                                    })
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ## Load only the two lump locations we need – zero large lists
    load : Wad.Loaded -> Try(State, [WadErr(Str)])
    load = |loaded| {
        match Wad.records_info(loaded, "LINEDEFS", 14) {
            Err(e) => Err(e)
            Ok(ld) => {
                match Wad.records_info(loaded, "VERTEXES", 4) {
                    Err(e) => Err(e)
                    Ok(vx) => {
                        Ok({
                            wad: loaded.wad,
                            ld_start: ld.start,
                            ld_size: ld.size,
                            ld_count: ld.size / 14,
                            vx_start: vx.start,
                            vx_size: vx.size,
                        })
                    }
                }
            }
        }
    }
}
