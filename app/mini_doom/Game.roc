import Wad
import Map

Game := {}.
{
    Player : {
        x : F32,
        y : F32,
        z : F32,
        yaw : F32,
        health : I64,
    }

    Actor : {
        x : F32,
        y : F32,
        kind : U64,
        angle : F32,
        alive : Bool,
    }

    Model : {
        player : Player,
        have_start : Bool,
        actors : List(Actor),
    }

    init_empty : Model
    init_empty = {
        player: { x: 0, y: 0, z: 0, yaw: 0, health: 100 },
        have_start: False,
        actors: [],
    }

    load_from_things : List(U8) -> Try(Model, [WadErr(Str)])
    load_from_things = |things| {
        load_things_go(things, 0, init_empty)
    }

    ## Back-compat name used by main
    load_player_start : List(U8) -> Try(Model, [WadErr(Str)])
    load_player_start = |things| {
        load_from_things(things)
    }

    load_things_go : List(U8), U64, Model -> Try(Model, [WadErr(Str)])
    load_things_go = |data, i, model| {
        if i + 10 > List.len(data) {
            if model.have_start {
                Ok(model)
            } else {
                Err(WadErr("no player start (thing type 1)"))
            }
        } else {
            match Wad.i16le_f32(data, i) {
                Err(e) => Err(e)
                Ok(px) => {
                    match Wad.i16le_f32(data, i + 2) {
                        Err(e) => Err(e)
                        Ok(py) => {
                            match Wad.i16le_f32(data, i + 4) {
                                Err(e) => Err(e)
                                Ok(angle) => {
                                    match Wad.u16le(data, i + 6) {
                                        Err(e) => Err(e)
                                        Ok(kind) => {
                                            next = apply_thing(model, px, py, angle, kind)
                                            load_things_go(data, i + 10, next)
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

    apply_thing : Model, F32, F32, F32, U64 -> Model
    apply_thing = |model, px, py, angle, kind| {
        if kind == 1 {
            {
                player: {
                    x: px,
                    y: py,
                    z: 0,
                    yaw: angle * 3.14159265 / 180,
                    health: 100,
                },
                have_start: True,
                actors: model.actors,
            }
        } else {
            actor = {
                x: px,
                y: py,
                kind,
                angle: angle * 3.14159265 / 180,
                alive: True,
            }
            {
                player: model.player,
                have_start: model.have_start,
                actors: List.append(model.actors, actor),
            }
        }
    }

    # ---- collision (Goose-style line blocking) ----

    ## Solid if one-sided or ML_BLOCKING (flag bit 0).
    line_blocks : Map.Line -> Bool
    line_blocks = |line| {
        if line.back == 65535 {
            True
        } else {
            # flags & 1
            if line.flags % 2 == 1 {
                True
            } else {
                False
            }
        }
    }

    cross2 : F32, F32, F32, F32 -> F32
    cross2 = |ax, ay, bx, by| {
        ax * by - ay * bx
    }

    ## Segment intersection (open interval): does [a→b] cross [c→d]?
    segs_cross : F32, F32, F32, F32, F32, F32, F32, F32 -> Bool
    segs_cross = |ax, ay, bx, by, cx, cy, dx, dy| {
        abx = bx - ax
        aby = by - ay
        cdx = dx - cx
        cdy = dy - cy
        den = cross2(abx, aby, cdx, cdy)
        # parallel-ish
        if den < 0.0001 {
            if den > -0.0001 {
                False
            } else {
                segs_cross_den(ax, ay, bx, by, cx, cy, abx, aby, cdx, cdy, den)
            }
        } else {
            segs_cross_den(ax, ay, bx, by, cx, cy, abx, aby, cdx, cdy, den)
        }
    }

    segs_cross_den :
        F32,
        F32,
        F32,
        F32,
        F32,
        F32,
        F32,
        F32,
        F32,
        F32,
        F32
        -> Bool
    segs_cross_den = |ax, ay, _bx, _by, cx, cy, abx, aby, cdx, cdy, den| {
        acx = cx - ax
        acy = cy - ay
        t = cross2(acx, acy, cdx, cdy) / den
        u = cross2(acx, acy, abx, aby) / den
        if t > 0.001 {
            if t < 0.999 {
                if u > 0.001 {
                    if u < 0.999 {
                        True
                    } else {
                        False
                    }
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

    ## True if move from (x0,y0) to (x1,y1) hits a blocking linedef.
    blocked_by_lines : Map.State, F32, F32, F32, F32 -> Bool
    blocked_by_lines = |map, x0, y0, x1, y1| {
        blocked_go(map.lines, 0, x0, y0, x1, y1)
    }

    blocked_go : List(Map.Line), U64, F32, F32, F32, F32 -> Bool
    blocked_go = |lines, i, x0, y0, x1, y1| {
        if i >= List.len(lines) {
            False
        } else {
            match List.get(lines, i) {
                Err(_) => False
                Ok(line) => {
                    if line_blocks(line) {
                        if segs_cross(x0, y0, x1, y1, line.ax, line.ay, line.bx, line.by) {
                            True
                        } else {
                            blocked_go(lines, i + 1, x0, y0, x1, y1)
                        }
                    } else {
                        blocked_go(lines, i + 1, x0, y0, x1, y1)
                    }
                }
            }
        }
    }

    ## Try move player by (dx, dy). On block, stay put.
    try_move : Model, Map.State, F32, F32 -> Model
    try_move = |model, map, dx, dy| {
        nx = model.player.x + dx
        ny = model.player.y + dy
        if blocked_by_lines(map, model.player.x, model.player.y, nx, ny) {
            model
        } else {
            {
                player: {
                    x: nx,
                    y: ny,
                    z: model.player.z,
                    yaw: model.player.yaw,
                    health: model.player.health,
                },
                have_start: model.have_start,
                actors: model.actors,
            }
        }
    }

    ## Move forward along yaw by `dist` map units.
    try_forward : Model, Map.State, F32 -> Model
    try_forward = |model, map, dist| {
        # cos/sin via host later; approx with small steps or platform Math
        dx = dist * cos_approx(model.player.yaw)
        dy = dist * sin_approx(model.player.yaw)
        try_move(model, map, dx, dy)
    }

    ## Crude poly for smoke without Math.sin host (replace with pf.Math later).
    cos_approx : F32 -> F32
    cos_approx = |a| {
        # normalize poorly; good enough for smoke
        x = a
        x2 = x * x
        1 - x2 / 2 + x2 * x2 / 24
    }

    sin_approx : F32 -> F32
    sin_approx = |a| {
        x = a
        x2 = x * x
        x - x * x2 / 6 + x * x2 * x2 / 120
    }

    turn : Model, F32 -> Model
    turn = |model, da| {
        {
            player: {
                x: model.player.x,
                y: model.player.y,
                z: model.player.z,
                yaw: model.player.yaw + da,
                health: model.player.health,
            },
            have_start: model.have_start,
            actors: model.actors,
        }
    }

    ## N fixed sim steps: turn a bit, walk forward.
    smoke_walk : Model, Map.State, U64 -> Model
    smoke_walk = |model, map, steps| {
        smoke_walk_go(model, map, steps)
    }

    smoke_walk_go : Model, Map.State, U64 -> Model
    smoke_walk_go = |model, map, left| {
        if left == 0 {
            model
        } else {
            m1 = turn(model, 0.05)
            m2 = try_forward(m1, map, 8)
            smoke_walk_go(m2, map, left - 1)
        }
    }
}
