## WAD loader that never materialises a full List(Lump).
## Directory is scanned on demand – eliminates the recursive growable
## that was blowing the Goose data stack.
Wad := {}.
{
    ## Only the raw bytes + directory location. No big list of lumps.
    Loaded : {
        wad : List(U8),
        dir_off : U64,
        count : U64,
    }

    Lump : { name : Str, start : U64, size : U64 }

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

    ## Scan the directory on demand.
    find_lump_go : List(U8), U64, U64, U64, Str -> Try(Lump, [WadErr(Str)])
    find_lump_go = |wad, dir_off, count, i, name| {
        if i >= count {
            Err(WadErr("missing lump"))
        } else {
            off = dir_off + i * 16
            match u32le(wad, off) {
                Err(e) => Err(e)
                Ok(start) => {
                    match u32le(wad, off + 4) {
                        Err(e) => Err(e)
                        Ok(size) => {
                            match name8(wad, off + 8) {
                                Err(e) => Err(e)
                                Ok(n) => {
                                    if n == name {
                                        Ok({ name: n, start, size })
                                    } else {
                                        find_lump_go(wad, dir_off, count, i + 1, name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    find_lump : Loaded, Str -> Try(Lump, [WadErr(Str)])
    find_lump = |loaded, name| {
        find_lump_go(loaded.wad, loaded.dir_off, loaded.count, 0, name)
    }

    get_u8 : List(U8), U64 -> Try(U8, [WadErr(Str)])
    get_u8 = |wad, at| {
        match List.get(wad, at) {
            Err(_) => Err(WadErr("oob"))
            Ok(b) => Ok(b)
        }
    }

    i16le_f32 : List(U8), U64 -> Try(F32, [WadErr(Str)])
    i16le_f32 = |data, at| {
        match List.get(data, at) {
            Err(_) => Err(WadErr("truncated i16"))
            Ok(lo) => {
                match List.get(data, at + 1) {
                    Err(_) => Err(WadErr("truncated i16"))
                    Ok(hi) => {
                        raw = lo.to_u64() + hi.to_u64() * 256
                        if raw >= 32768 {
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

    u16_at : List(U8), U64 -> Try(U64, [WadErr(Str)])
    u16_at = |data, at| {
        u16le(data, at)
    }

    u32_at : List(U8), U64 -> Try(U64, [WadErr(Str)])
    u32_at = |data, at| {
        u32le(data, at)
    }

    ## Materialise only small lumps
    copy_chunk_size : U64
    copy_chunk_size = 4096

    max_materialize : U64
    max_materialize = 2 * 1024 * 1024

    copy_chunk : List(U8), U64, U64, U64, List(U8) -> Try(List(U8), [WadErr(Str)])
    copy_chunk = |wad, at, n, j, out| {
        if j >= n {
            Ok(out)
        } else {
            match List.get(wad, at + j) {
                Err(_) => Err(WadErr("lump range"))
                Ok(b) => copy_chunk(wad, at, n, j + 1, List.append(out, b))
            }
        }
    }

    materialize_go : List(U8), U64, U64, U64, List(U8) -> Try(List(U8), [WadErr(Str)])
    materialize_go = |wad, start, size, off, acc| {
        if off >= size {
            Ok(acc)
        } else {
            remain = size - off
            take =
                if remain > copy_chunk_size {
                    copy_chunk_size
                } else {
                    remain
                }
            match copy_chunk(wad, start + off, take, 0, []) {
                Err(e) => Err(e)
                Ok(block) =>
                    materialize_go(wad, start, size, off + take, List.concat(acc, block))
            }
        }
    }

    materialize_range : List(U8), U64, U64 -> Try(List(U8), [WadErr(Str)])
    materialize_range = |wad, start, size| {
        if size > max_materialize {
            Err(WadErr("lump too large to materialize; use indexed reads"))
        } else if start + size > List.len(wad) {
            Err(WadErr("lump past end of WAD"))
        } else {
            materialize_go(wad, start, size, 0, [])
        }
    }

    ## Public API
    lump_bytes : Loaded, Str -> Try(List(U8), [WadErr(Str)])
    lump_bytes = |loaded, name| {
        match find_lump(loaded, name) {
            Err(e) => Err(e)
            Ok(lump) => materialize_range(loaded.wad, lump.start, lump.size)
        }
    }

    lump_bytes_of : Loaded, Lump -> Try(List(U8), [WadErr(Str)])
    lump_bytes_of = |loaded, lump| {
        materialize_range(loaded.wad, lump.start, lump.size)
    }

    records : Loaded, Str, U64 -> Try(List(U8), [WadErr(Str)])
    records = |loaded, name, size| {
        match lump_bytes(loaded, name) {
            Err(e) => Err(e)
            Ok(data) => {
                len = List.len(data)
                if len == 0 {
                    Err(WadErr("empty lump"))
                } else if size == 0 {
                    Err(WadErr("bad record size"))
                } else if len % size != 0 {
                    Err(WadErr("bad record size"))
                } else {
                    Ok(data)
                }
            }
        }
    }

    records_info : Loaded, Str, U64 -> Try(Lump, [WadErr(Str)])
    records_info = |loaded, name, rec_size| {
        match find_lump(loaded, name) {
            Err(e) => Err(e)
            Ok(lump) => {
                if lump.size == 0 {
                    Err(WadErr("empty lump"))
                } else if rec_size == 0 {
                    Err(WadErr("bad record size"))
                } else if lump.size % rec_size != 0 {
                    Err(WadErr("bad record size"))
                } else {
                    Ok(lump)
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

    load_directory : List(U8) -> Try(Loaded, [WadErr(Str)])
    load_directory = |data| {
        match u32le(data, 4) {
            Err(e) => Err(e)
            Ok(count) => {
                match u32le(data, 8) {
                    Err(e) => Err(e)
                    Ok(directory) => {
                        if count > 65536 {
                            Err(WadErr("bad WAD directory count"))
                        } else if directory + count * 16 > List.len(data) {
                            Err(WadErr("directory past end of WAD"))
                        } else {
                            Ok({
                                wad: data,
                                dir_off: directory,
                                count: count,
                            })
                        }
                    }
                }
            }
        }
    }
}
