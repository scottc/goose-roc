import Wad

Flats := {}.
{
    load_flat : Wad.Loaded, Str -> Try(List(U8), [WadErr(Str)])
    load_flat = |loaded, name| {
        match Wad.lump_bytes(loaded.wad, loaded.lumps, name) {
            Err(e) => Err(e)
            Ok(bytes) => {
                need = 64 * 64
                if List.len(bytes) < need {
                    Err(WadErr("flat too short"))
                } else {
                    Ok(bytes)
                }
            }
        }
    }

    index_at : List(U8), U64, U64 -> Try(U8, [WadErr(Str)])
    index_at = |flat, x, y| {
        if x >= 64 {
            Err(WadErr("flat x"))
        } else if y >= 64 {
            Err(WadErr("flat y"))
        } else {
            match List.get(flat, y * 64 + x) {
                Err(_) => Err(WadErr("flat pixel"))
                Ok(i) => Ok(i)
            }
        }
    }

    corner_sum : List(U8) -> Try(U64, [WadErr(Str)])
    corner_sum = |flat| {
        match index_at(flat, 0, 0) {
            Err(e) => Err(e)
            Ok(a) => {
                match index_at(flat, 63, 0) {
                    Err(e) => Err(e)
                    Ok(b) => {
                        match index_at(flat, 0, 63) {
                            Err(e) => Err(e)
                            Ok(c) => {
                                match index_at(flat, 63, 63) {
                                    Err(e) => Err(e)
                                    Ok(d) => {
                                        Ok(
                                            a.to_u64()
                                            + b.to_u64()
                                            + c.to_u64()
                                            + d.to_u64(),
                                        )
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
