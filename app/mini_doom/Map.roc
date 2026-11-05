import Wad

Map := {}.
{
    Side : {
        ox : F32,
        oy : F32,
        upper : I64,
        lower : I64,
        middle : I64,
        sector : U64,
    }

    Line : {
        ax : F32,
        ay : F32,
        bx : F32,
        by : F32,
        flags : U64,
        special : U64,
        tag : U64,
        front : U64,
        # 65535 = no back side
        back : U64,
    }

    Sector : {
        floor : F32,
        ceiling : F32,
        light : F32,
        special : F32,
        tag : F32,
    }

    Seg : {
        ax : F32,
        ay : F32,
        bx : F32,
        by : F32,
        sector : U64,
    }

    Subsector : {
        first : U64,
        count : U64,
        sector : U64,
    }

    Node : {
        ox : F32,
        oy : F32,
        dx : F32,
        dy : F32,
        front : U64,
        back : U64,
    }

    State : {
        vertices : List({ x : F32, y : F32 }),
        sides : List(Side),
        lines : List(Line),
        sectors : List(Sector),
        segs : List(Seg),
        subsectors : List(Subsector),
        nodes : List(Node),
    }

    empty : State
    empty = {
        vertices: [],
        sides: [],
        lines: [],
        sectors: [],
        segs: [],
        subsectors: [],
        nodes: [],
    }

    load_vertices : List(U8) -> Try(List({ x : F32, y : F32 }), [WadErr(Str)])
    load_vertices = |data| {
        load_vertices_go(data, 0, [])
    }

    load_vertices_go :
        List(U8),
        U64,
        List({ x : F32, y : F32 })
        -> Try(List({ x : F32, y : F32 }), [WadErr(Str)])
    load_vertices_go = |data, i, out| {
        if i + 4 > List.len(data) {
            Ok(out)
        } else {
            match Wad.i16le_f32(data, i) {
                Err(e) => Err(e)
                Ok(x) => {
                    match Wad.i16le_f32(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(y) => {
                            load_vertices_go(data, i + 4, List.append(out, { x, y }))
                        }
                    }
                }
            }
        }
    }

    load_sectors : List(U8) -> Try(List(Sector), [WadErr(Str)])
    load_sectors = |data| {
        load_sectors_go(data, 0, [])
    }

    load_sectors_go : List(U8), U64, List(Sector) -> Try(List(Sector), [WadErr(Str)])
    load_sectors_go = |data, i, out| {
        if i + 26 > List.len(data) {
            Ok(out)
        } else {
            match Wad.i16le_f32(data, i) {
                Err(e) => Err(e)
                Ok(floor) => {
                    match Wad.i16le_f32(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(ceiling) => {
                            match Wad.i16le_f32(data, i + 20) {
                                Err(e) => Err(e)
                                Ok(light_i) => {
                                    match Wad.i16le_f32(data, i + 22) {
                                        Err(e) => Err(e)
                                        Ok(special) => {
                                            match Wad.i16le_f32(data, i + 24) {
                                                Err(e) => Err(e)
                                                Ok(tag) => {
                                                    sec = {
                                                        floor,
                                                        ceiling,
                                                        light: light_i / 255,
                                                        special,
                                                        tag,
                                                    }
                                                    load_sectors_go(data, i + 26, List.append(out, sec))
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

    load_sides : List(U8), U64 -> Try(List(Side), [WadErr(Str)])
    load_sides = |data, sector_count| {
        load_sides_go(data, 0, sector_count, [])
    }

    load_sides_go : List(U8), U64, U64, List(Side) -> Try(List(Side), [WadErr(Str)])
    load_sides_go = |data, i, sector_count, out| {
        if i + 30 > List.len(data) {
            Ok(out)
        } else {
            match Wad.i16le_f32(data, i) {
                Err(e) => Err(e)
                Ok(ox) => {
                    match Wad.i16le_f32(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(oy) => {
                            match Wad.u16le(data, i + 28) {
                                Err(e) => Err(e)
                                Ok(sector) => {
                                    if sector >= sector_count {
                                        Err(WadErr("bad sidedef sector"))
                                    } else {
                                        side = {
                                            ox,
                                            oy,
                                            upper: -1,
                                            lower: -1,
                                            middle: -1,
                                            sector,
                                        }
                                        load_sides_go(
                                            data,
                                            i + 30,
                                            sector_count,
                                            List.append(out, side),
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

    load_lines :
        List(U8),
        List({ x : F32, y : F32 }),
        U64
        -> Try(List(Line), [WadErr(Str)])
    load_lines = |data, vertices, side_count| {
        load_lines_go(data, 0, vertices, side_count, [])
    }

    load_lines_go :
        List(U8),
        U64,
        List({ x : F32, y : F32 }),
        U64,
        List(Line)
        -> Try(List(Line), [WadErr(Str)])
    load_lines_go = |data, i, vertices, side_count, out| {
        if i + 14 > List.len(data) {
            Ok(out)
        } else {
            match Wad.u16le(data, i) {
                Err(e) => Err(e)
                Ok(ai) => {
                    match Wad.u16le(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(bi) => {
                            match Wad.u16le(data, i + 4) {
                                Err(e) => Err(e)
                                Ok(flags) => {
                                    match Wad.u16le(data, i + 6) {
                                        Err(e) => Err(e)
                                        Ok(special) => {
                                            match Wad.u16le(data, i + 8) {
                                                Err(e) => Err(e)
                                                Ok(tag) => {
                                                    match Wad.u16le(data, i + 10) {
                                                        Err(e) => Err(e)
                                                        Ok(front) => {
                                                            match Wad.u16le(data, i + 12) {
                                                                Err(e) => Err(e)
                                                                Ok(back_u) => {
                                                                    nv = List.len(vertices)
                                                                    if ai >= nv {
                                                                        Err(WadErr("bad linedef vertex a"))
                                                                    } else if bi >= nv {
                                                                        Err(WadErr("bad linedef vertex b"))
                                                                    } else if front >= side_count {
                                                                        Err(WadErr("bad linedef front"))
                                                                    } else if back_u != 65535 {
                                                                        if back_u >= side_count {
                                                                            Err(WadErr("bad linedef back"))
                                                                        } else {
                                                                            finish_line(
                                                                                data,
                                                                                i,
                                                                                vertices,
                                                                                side_count,
                                                                                out,
                                                                                ai,
                                                                                bi,
                                                                                flags,
                                                                                special,
                                                                                tag,
                                                                                front,
                                                                                back_u,
                                                                            )
                                                                        }
                                                                    } else {
                                                                        finish_line(
                                                                            data,
                                                                            i,
                                                                            vertices,
                                                                            side_count,
                                                                            out,
                                                                            ai,
                                                                            bi,
                                                                            flags,
                                                                            special,
                                                                            tag,
                                                                            front,
                                                                            back_u,
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
                            }
                        }
                    }
                }
            }
        }
    }

    finish_line :
        List(U8),
        U64,
        List({ x : F32, y : F32 }),
        U64,
        List(Line),
        U64,
        U64,
        U64,
        U64,
        U64,
        U64,
        U64
        -> Try(List(Line), [WadErr(Str)])
    finish_line = |data, i, vertices, side_count, out, ai, bi, flags, special, tag, front, back_u| {
        match List.get(vertices, ai) {
            Err(_) => Err(WadErr("vertex a"))
            Ok(va) => {
                match List.get(vertices, bi) {
                    Err(_) => Err(WadErr("vertex b"))
                    Ok(vb) => {
                        line = {
                            ax: va.x,
                            ay: va.y,
                            bx: vb.x,
                            by: vb.y,
                            flags,
                            special,
                            tag,
                            front,
                            back: back_u,
                        }
                        load_lines_go(
                            data,
                            i + 14,
                            vertices,
                            side_count,
                            List.append(out, line),
                        )
                    }
                }
            }
        }
    }

    load_segs :
        List(U8),
        List({ x : F32, y : F32 }),
        List(Line),
        List(Side)
        -> Try(List(Seg), [WadErr(Str)])
    load_segs = |data, vertices, lines, sides| {
        load_segs_go(data, 0, vertices, lines, sides, [])
    }

    load_segs_go :
        List(U8),
        U64,
        List({ x : F32, y : F32 }),
        List(Line),
        List(Side),
        List(Seg)
        -> Try(List(Seg), [WadErr(Str)])
    load_segs_go = |data, i, vertices, lines, sides, out| {
        if i + 12 > List.len(data) {
            Ok(out)
        } else {
            match Wad.u16le(data, i) {
                Err(e) => Err(e)
                Ok(ai) => {
                    match Wad.u16le(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(bi) => {
                            match Wad.u16le(data, i + 6) {
                                Err(e) => Err(e)
                                Ok(line_i) => {
                                    match Wad.u16le(data, i + 8) {
                                        Err(e) => Err(e)
                                        Ok(direction) => {
                                            nv = List.len(vertices)
                                            nl = List.len(lines)
                                            if ai >= nv {
                                                Err(WadErr("bad seg"))
                                            } else if bi >= nv {
                                                Err(WadErr("bad seg"))
                                            } else if line_i >= nl {
                                                Err(WadErr("bad seg"))
                                            } else if direction > 1 {
                                                Err(WadErr("bad seg"))
                                            } else {
                                                match List.get(lines, line_i) {
                                                    Err(_) => Err(WadErr("seg line"))
                                                    Ok(line) => {
                                                        if direction == 1 {
                                                            if line.back == 65535 {
                                                                Err(WadErr("seg has no sidedef"))
                                                            } else {
                                                                seg_with_side(
                                                                    data,
                                                                    i,
                                                                    vertices,
                                                                    lines,
                                                                    sides,
                                                                    out,
                                                                    ai,
                                                                    bi,
                                                                    line.back,
                                                                )
                                                            }
                                                        } else {
                                                            seg_with_side(
                                                                data,
                                                                i,
                                                                vertices,
                                                                lines,
                                                                sides,
                                                                out,
                                                                ai,
                                                                bi,
                                                                line.front,
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
                }
            }
        }
    }

    seg_with_side :
        List(U8),
        U64,
        List({ x : F32, y : F32 }),
        List(Line),
        List(Side),
        List(Seg),
        U64,
        U64,
        U64
        -> Try(List(Seg), [WadErr(Str)])
    seg_with_side = |data, i, vertices, lines, sides, out, ai, bi, side_i| {
        match List.get(sides, side_i) {
            Err(_) => Err(WadErr("seg side"))
            Ok(side) => {
                match List.get(vertices, ai) {
                    Err(_) => Err(WadErr("seg va"))
                    Ok(va) => {
                        match List.get(vertices, bi) {
                            Err(_) => Err(WadErr("seg vb"))
                            Ok(vb) => {
                                seg = {
                                    ax: va.x,
                                    ay: va.y,
                                    bx: vb.x,
                                    by: vb.y,
                                    sector: side.sector,
                                }
                                load_segs_go(
                                    data,
                                    i + 12,
                                    vertices,
                                    lines,
                                    sides,
                                    List.append(out, seg),
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    load_subsectors : List(U8), List(Seg) -> Try(List(Subsector), [WadErr(Str)])
    load_subsectors = |data, segs| {
        load_subsectors_go(data, 0, segs, [])
    }

    load_subsectors_go :
        List(U8),
        U64,
        List(Seg),
        List(Subsector)
        -> Try(List(Subsector), [WadErr(Str)])
    load_subsectors_go = |data, i, segs, out| {
        if i + 4 > List.len(data) {
            Ok(out)
        } else {
            match Wad.u16le(data, i) {
                Err(e) => Err(e)
                Ok(count) => {
                    match Wad.u16le(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(first) => {
                            ns = List.len(segs)
                            if count == 0 {
                                Err(WadErr("bad subsector"))
                            } else if first + count > ns {
                                Err(WadErr("bad subsector"))
                            } else {
                                match List.get(segs, first) {
                                    Err(_) => Err(WadErr("subsector seg"))
                                    Ok(seg) => {
                                        ss = { first, count, sector: seg.sector }
                                        load_subsectors_go(
                                            data,
                                            i + 4,
                                            segs,
                                            List.append(out, ss),
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

    load_nodes : List(U8) -> Try(List(Node), [WadErr(Str)])
    load_nodes = |data| {
        load_nodes_go(data, 0, [])
    }

    load_nodes_go : List(U8), U64, List(Node) -> Try(List(Node), [WadErr(Str)])
    load_nodes_go = |data, i, out| {
        if i + 28 > List.len(data) {
            Ok(out)
        } else {
            match Wad.i16le_f32(data, i) {
                Err(e) => Err(e)
                Ok(ox) => {
                    match Wad.i16le_f32(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(oy) => {
                            match Wad.i16le_f32(data, i + 4) {
                                Err(e) => Err(e)
                                Ok(dx) => {
                                    match Wad.i16le_f32(data, i + 6) {
                                        Err(e) => Err(e)
                                        Ok(dy) => {
                                            match Wad.u16le(data, i + 24) {
                                                Err(e) => Err(e)
                                                Ok(front) => {
                                                    match Wad.u16le(data, i + 26) {
                                                        Err(e) => Err(e)
                                                        Ok(back) => {
                                                            node = { ox, oy, dx, dy, front, back }
                                                            load_nodes_go(
                                                                data,
                                                                i + 28,
                                                                List.append(out, node),
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
                }
            }
        }
    }

    cross2 : F32, F32, F32, F32 -> F32
    cross2 = |ax, ay, bx, by| {
        ax * by - ay * bx
    }

    sector_at : State, F32, F32 -> Try(U64, [WadErr(Str)])
    sector_at = |map, px, py| {
        nn = List.len(map.nodes)
        if nn == 0 {
            Err(WadErr("no nodes"))
        } else {
            sector_at_go(map, nn - 1, px, py, 0)
        }
    }

    sector_at_go : State, U64, F32, F32, U64 -> Try(U64, [WadErr(Str)])
    sector_at_go = |map, child, px, py, steps| {
        nn = List.len(map.nodes)
        nss = List.len(map.subsectors)
        if steps > nn {
            Err(WadErr("invalid BSP tree"))
        } else if child >= 32768 {
            leaf = child - 32768
            if leaf >= nss {
                Err(WadErr("bad BSP leaf"))
            } else {
                match List.get(map.subsectors, leaf) {
                    Err(_) => Err(WadErr("leaf"))
                    Ok(ss) => Ok(ss.sector)
                }
            }
        } else if child >= nn {
            Err(WadErr("bad BSP node"))
        } else {
            match List.get(map.nodes, child) {
                Err(_) => Err(WadErr("node"))
                Ok(n) => {
                    cx = cross2(n.dx, n.dy, px - n.ox, py - n.oy)
                    next =
                        if cx <= 0 {
                            n.front
                        } else {
                            n.back
                        }
                    sector_at_go(map, next, px, py, steps + 1)
                }
            }
        }
    }

    load : Wad.Loaded -> Try(State, [WadErr(Str)])
    load = |loaded| {
        match Wad.records(loaded.wad, loaded.lumps, "VERTEXES", 4) {
            Err(e) => Err(e)
            Ok(vdata) => {
                match load_vertices(vdata) {
                    Err(e) => Err(e)
                    Ok(vertices) => {
                        match Wad.records(loaded.wad, loaded.lumps, "SECTORS", 26) {
                            Err(e) => Err(e)
                            Ok(sdata) => {
                                match load_sectors(sdata) {
                                    Err(e) => Err(e)
                                    Ok(sectors) => {
                                        match Wad.records(loaded.wad, loaded.lumps, "SIDEDEFS", 30) {
                                            Err(e) => Err(e)
                                            Ok(sddata) => {
                                                match load_sides(sddata, List.len(sectors)) {
                                                    Err(e) => Err(e)
                                                    Ok(sides) => {
                                                        match Wad.records(loaded.wad, loaded.lumps, "LINEDEFS", 14) {
                                                            Err(e) => Err(e)
                                                            Ok(lddata) => {
                                                                match load_lines(lddata, vertices, List.len(sides)) {
                                                                    Err(e) => Err(e)
                                                                    Ok(lines) => {
                                                                        match Wad.records(loaded.wad, loaded.lumps, "SEGS", 12) {
                                                                            Err(e) => Err(e)
                                                                            Ok(sgdata) => {
                                                                                match load_segs(sgdata, vertices, lines, sides) {
                                                                                    Err(e) => Err(e)
                                                                                    Ok(segs) => {
                                                                                        match Wad.records(loaded.wad, loaded.lumps, "SSECTORS", 4) {
                                                                                            Err(e) => Err(e)
                                                                                            Ok(ssdata) => {
                                                                                                match load_subsectors(ssdata, segs) {
                                                                                                    Err(e) => Err(e)
                                                                                                    Ok(subsectors) => {
                                                                                                        match Wad.records(loaded.wad, loaded.lumps, "NODES", 28) {
                                                                                                            Err(e) => Err(e)
                                                                                                            Ok(nddata) => {
                                                                                                                match load_nodes(nddata) {
                                                                                                                    Err(e) => Err(e)
                                                                                                                    Ok(nodes) => {
                                                                                                                        Ok({
                                                                                                                            vertices,
                                                                                                                            sides,
                                                                                                                            lines,
                                                                                                                            sectors,
                                                                                                                            segs,
                                                                                                                            subsectors,
                                                                                                                            nodes,
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
