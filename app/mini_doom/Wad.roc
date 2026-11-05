## Pure WAD directory parse (Goose 31_mini_doom load_wad).
Wad := {}.
{
    Lump : { name : Str, start : U64, size : U64 }

    Loaded : { wad : List(U8), lumps : List(Lump) }

    u16le : List(U8), U64 -> Try(U64, [WadErr(Str)])
    u16le = |data, at| {
        match List.get(data, at) {
            Err(_) => Err(WadErr("truncated u16"))
            Ok(a) => {
                match List.get(data, at + 1) {
                    Err(_) => Err(WadErr("truncated u16"))
                    Ok(b) => Ok(a.to_u64() + b.to_u64() * 256)
                }
            }
        }
    }

    u32le : List(U8), U64 -> Try(U64, [WadErr(Str)])
    u32le = |data, at| {
        match List.get(data, at) {
            Err(_) => Err(WadErr("truncated u32"))
            Ok(b0) => {
                match List.get(data, at + 1) {
                    Err(_) => Err(WadErr("truncated u32"))
                    Ok(b1) => {
                        match List.get(data, at + 2) {
                            Err(_) => Err(WadErr("truncated u32"))
                            Ok(b2) => {
                                match List.get(data, at + 3) {
                                    Err(_) => Err(WadErr("truncated u32"))
                                    Ok(b3) =>
                                        Ok(
                                            b0.to_u64()
                                            + b1.to_u64() * 256
                                            + b2.to_u64() * 65536
                                            + b3.to_u64() * 16777216,
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    name8_go : List(U8), U64, U64, List(U8) -> Try(Str, [WadErr(Str)])
    name8_go = |data, at, i, chars| {
        if i >= 8 {
            match Str.from_utf8(chars) {
                Ok(s) => Ok(s)
                Err(_) => Err(WadErr("name not utf8"))
            }
        } else {
            match List.get(data, at + i) {
                Err(_) => Err(WadErr("truncated name"))
                Ok(b) => {
                    if b == 0 {
                        match Str.from_utf8(chars) {
                            Ok(s) => Ok(s)
                            Err(_) => Err(WadErr("name not utf8"))
                        }
                    } else {
                        name8_go(data, at, i + 1, List.append(chars, b))
                    }
                }
            }
        }
    }

    name8 : List(U8), U64 -> Try(Str, [WadErr(Str)])
    name8 = |data, at| {
        name8_go(data, at, 0, [])
    }

    ## I=73 W=87 A=65 D=68
    sig_iwad : U8, U8, U8, U8 -> Bool
    sig_iwad = |s0, s1, s2, s3| {
        if s0 == 73 {
            if s1 == 87 {
                if s2 == 65 {
                    s3 == 68
                } else {
                    False
                }
            } else {
                False
            }
        } else {
            False
        }
    }

    ## P=80 W=87 A=65 D=68
    sig_pwad : U8, U8, U8, U8 -> Bool
    sig_pwad = |s0, s1, s2, s3| {
        if s0 == 80 {
            if s1 == 87 {
                if s2 == 65 {
                    s3 == 68
                } else {
                    False
                }
            } else {
                False
            }
        } else {
            False
        }
    }

    copy_range : List(U8), U64, U64, U64, List(U8) -> Try(List(U8), [WadErr(Str)])
    copy_range = |data, start, size, j, out| {
        if j >= size {
            Ok(out)
        } else {
            match List.get(data, start + j) {
                Err(_) => Err(WadErr("lump range"))
                Ok(b) => copy_range(data, start, size, j + 1, List.append(out, b))
            }
        }
    }

    read_entries :
        List(U8),
        U64,
        U64,
        U64,
        List(Lump)
        -> Try(List(Lump), [WadErr(Str)])
    read_entries = |data, directory, count, i, lumps| {
        if i >= count {
            Ok(lumps)
        } else {
            off = directory + i * 16
            match u32le(data, off) {
                Err(e) => Err(e)
                Ok(start) => {
                    match u32le(data, off + 4) {
                        Err(e) => Err(e)
                        Ok(size) => {
                            match name8(data, off + 8) {
                                Err(e) => Err(e)
                                Ok(name) => {
                                    end = start + size
                                    if end > List.len(data) {
                                        Err(WadErr("lump past end of WAD"))
                                    } else {
                                        read_entries(
                                            data,
                                            directory,
                                            count,
                                            i + 1,
                                            List.append(lumps, { name, start, size }),
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

    load_directory : List(U8) -> Try(Loaded, [WadErr(Str)])
    load_directory = |data| {
        match u32le(data, 4) {
            Err(e) => Err(e)
            Ok(count) => {
                match u32le(data, 8) {
                    Err(e) => Err(e)
                    Ok(directory) => {
                        if count > 100000 {
                            Err(WadErr("bad WAD directory count"))
                        } else {
                            match read_entries(data, directory, count, 0, []) {
                                Err(e) => Err(e)
                                Ok(lumps) => Ok({ wad: data, lumps })
                            }
                        }
                    }
                }
            }
        }
    }

    load_from_bytes : List(U8) -> Try(Loaded, [WadErr(Str)])
    load_from_bytes = |data| {
        if List.len(data) < 12 {
            Err(WadErr("truncated WAD header"))
        } else {
            match List.get(data, 0) {
                Err(_) => Err(WadErr("sig"))
                Ok(s0) => {
                    match List.get(data, 1) {
                        Err(_) => Err(WadErr("sig"))
                        Ok(s1) => {
                            match List.get(data, 2) {
                                Err(_) => Err(WadErr("sig"))
                                Ok(s2) => {
                                    match List.get(data, 3) {
                                        Err(_) => Err(WadErr("sig"))
                                        Ok(s3) => {
                                            if sig_iwad(s0, s1, s2, s3) {
                                                load_directory(data)
                                            } else if sig_pwad(s0, s1, s2, s3) {
                                                load_directory(data)
                                            } else {
                                                Err(WadErr("expected IWAD or PWAD"))
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

    # i16le : List(U8), U64 -> Try(I64, [WadErr(Str)])
    # i16le = |data, at| {
    #     match u16le(data, at) {
    #         Err(e) => Err(e)
    #         Ok(v) => {
    #             if v >= 32768 {
    #                 Ok(0 - (65536 - v).to_i64())
    #             } else {
    #                 Ok(v.to_i64())
    #             }
    #         }
    #     }
    # }

    ## Signed 16-bit LE → F32 (map coords / angles). Avoids U64→I64.
    i16le_f32 : List(U8), U64 -> Try(F32, [WadErr(Str)])
    i16le_f32 = |data, at| {
        match List.get(data, at) {
            Err(_) => Err(WadErr("truncated i16"))
            Ok(lo) => {
                match List.get(data, at + 1) {
                    Err(_) => Err(WadErr("truncated i16"))
                    Ok(hi) => {
                        # unsigned 0..65535
                        raw = lo.to_u64() + hi.to_u64() * 256
                        if raw >= 32768 {
                            # negative: raw - 65536
                            neg = (65536 - raw).to_f32()
                            Ok(0 - neg)
                        } else {
                            Ok(raw.to_f32())
                        }
                    }
                }
            }
        }
    }

    find_lump : List(Lump), Str -> Try(U64, [WadErr(Str)])
    find_lump = |lumps, name| {
        find_lump_go(lumps, name, 0, Err(WadErr("missing lump")))
    }

    find_lump_go : List(Lump), Str, U64, Try(U64, [WadErr(Str)]) -> Try(U64, [WadErr(Str)])
    find_lump_go = |lumps, name, i, found| {
        if i >= List.len(lumps) {
            found
        } else {
            match List.get(lumps, i) {
                Err(_) => Err(WadErr("bad index"))
                Ok(lump) => {
                    next =
                        if lump.name == name {
                            Ok(i)
                        } else {
                            found
                        }
                    find_lump_go(lumps, name, i + 1, next)
                }
            }
        }
    }

    lump_bytes : List(U8), List(Lump), Str -> Try(List(U8), [WadErr(Str)])
    lump_bytes = |wad, lumps, name| {
        match find_lump(lumps, name) {
            Err(e) => Err(e)
            Ok(index) => {
                match List.get(lumps, index) {
                    Err(_) => Err(WadErr("bad lump index"))
                    Ok(lump) => copy_range(wad, lump.start, lump.size, 0, [])
                }
            }
        }
    }

    ## Require non-empty multiple of record size.
    records : List(U8), List(Lump), Str, U64 -> Try(List(U8), [WadErr(Str)])
    records = |wad, lumps, name, size| {
        match lump_bytes(wad, lumps, name) {
            Err(e) => Err(e)
            Ok(data) => {
                len = List.len(data)
                if len == 0 {
                    Err(WadErr("empty lump"))
                } else if len % size != 0 {
                    Err(WadErr("bad record size"))
                } else {
                    Ok(data)
                }
            }
        }
    }
}
