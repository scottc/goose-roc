import Wad

Palette := {}.
{
    Rgb : { r : U8, g : U8, b : U8 }

    load_playpal : Wad.Loaded -> Try(List(U8), [WadErr(Str)])
    load_playpal = |loaded| {
        match Wad.lump_bytes(loaded.wad, loaded.lumps, "PLAYPAL") {
            Err(e) => Err(e)
            Ok(bytes) => {
                if List.len(bytes) < 768 {
                    Err(WadErr("PLAYPAL too short"))
                } else {
                    Ok(bytes)
                }
            }
        }
    }

    rgb_at : List(U8), U64 -> Try(Rgb, [WadErr(Str)])
    rgb_at = |playpal, ci| {
        if ci >= 256 {
            Err(WadErr("color index"))
        } else {
            base = ci * 3
            match List.get(playpal, base) {
                Err(_) => Err(WadErr("playpal r"))
                Ok(r) => {
                    match List.get(playpal, base + 1) {
                        Err(_) => Err(WadErr("playpal g"))
                        Ok(g) => {
                            match List.get(playpal, base + 2) {
                                Err(_) => Err(WadErr("playpal b"))
                                Ok(b) => Ok({ r, g, b })
                            }
                        }
                    }
                }
            }
        }
    }

    smoke_summary : List(U8) -> Try(Str, [WadErr(Str)])
    smoke_summary = |playpal| {
        match rgb_at(playpal, 0) {
            Err(e) => Err(e)
            Ok(c0) => {
                match rgb_at(playpal, 1) {
                    Err(e) => Err(e)
                    Ok(c1) => {
                        Ok(
                            "c0=(${c0.r.to_str()},${c0.g.to_str()},${c0.b.to_str()}) c1=(${c1.r.to_str()},${c1.g.to_str()},${c1.b.to_str()})",
                        )
                    }
                }
            }
        }
    }
}
