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
                                Ok(angle_deg) => {
                                    match Wad.u16le(data, i + 6) {
                                        Err(e) => Err(e)
                                        Ok(kind) => {
                                            next_model = apply_thing(model, px, py, angle_deg, kind)
                                            load_things_go(data, i + 10, next_model)
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
    apply_thing = |model, px, py, angle_deg, kind| {
        angle = angle_deg * 3.14159265 / 180.0
        if kind == 1 {
            {
                player: {
                    x: px,
                    y: py,
                    z: 0,
                    yaw: angle,
                    health: 100,
                },
                have_start: True,
                actors: model.actors,
            }
        } else {
            actor = {
                x: px,
                y: py,
                kind: kind,
                angle: angle,
                alive: True,
            }
            {
                player: model.player,
                have_start: model.have_start,
                actors: List.append(model.actors, actor),
            }
        }
    }

    line_blocks : Map.Line -> Bool
    line_blocks = |line| {
        if line.back == 65535 {
            True
        } else if line.flags % 2 == 1 {
            True
        } else {
            False
        }
    }

    cross2 : F32, F32, F32, F32 -> F32
    cross2 = |ax, ay, bx, by| {
        ax * by - ay * bx
    }

    segs_cross : F32, F32, F32, F32, F32, F32, F32, F32 -> Bool
    segs_cross = |ax, ay, bx, by, cx, cy, dx, dy| {
        abx = bx - ax
        aby = by - ay
        cdx = dx - cx
        cdy = dy - cy
        den = cross2(abx, aby, cdx, cdy)
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
        F32, F32, F32, F32, F32, F32,
        F32, F32, F32, F32, F32
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

    blocked_by_lines : List(U8), Map.State, F32, F32, F32, F32 -> Bool
    blocked_by_lines = |bytes, map, x0, y0, x1, y1| {
        blocked_go(bytes, map, 0, x0, y0, x1, y1)
    }

    blocked_go : List(U8), Map.State, U64, F32, F32, F32, F32 -> Bool
    blocked_go = |bytes, map, i, x0, y0, x1, y1| {
        if i >= map.ld_count {
            False
        } else {
            match Map.get_line(bytes, map, i) {
                Err(_) => False
                Ok(line) => {
                    if line_blocks(line) {
                        if segs_cross(x0, y0, x1, y1, line.ax, line.ay, line.bx, line.by) {
                            True
                        } else {
                            blocked_go(bytes, map, i + 1, x0, y0, x1, y1)
                        }
                    } else {
                        blocked_go(bytes, map, i + 1, x0, y0, x1, y1)
                    }
                }
            }
        }
    }

    try_move : List(U8), Model, Map.State, F32, F32 -> Model
    try_move = |bytes, model, map, dx, dy| {
        nx = model.player.x + dx
        ny = model.player.y + dy
        if blocked_by_lines(bytes, map, model.player.x, model.player.y, nx, ny) {
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

    try_forward : List(U8), Model, Map.State, F32 -> Model
    try_forward = |bytes, model, map, dist| {
        dx = dist * cos_approx(model.player.yaw)
        dy = dist * sin_approx(model.player.yaw)
        try_move(bytes, model, map, dx, dy)
    }

    wrap_pi : F32 -> F32
    wrap_pi = |a| {
        pi = 3.14159265
        two_pi = 6.2831853
        wrap_pi_go(a, pi, two_pi, 0)
    }

    wrap_pi_go : F32, F32, F32, I64 -> F32
    wrap_pi_go = |x, pi, two_pi, n| {
        if n > 64 {
            x
        } else if x > pi {
            wrap_pi_go(x - two_pi, pi, two_pi, n + 1)
        } else if x < -pi {
            wrap_pi_go(x + two_pi, pi, two_pi, n + 1)
        } else {
            x
        }
    }

    cos_approx : F32 -> F32
    cos_approx = |a| {
        x = wrap_pi(a)
        x2 = x * x
        1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720
    }

    sin_approx : F32 -> F32
    sin_approx = |a| {
        x = wrap_pi(a)
        x2 = x * x
        x * (1 - x2 / 6 + x2 * x2 / 120)
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

    smoke_walk : List(U8), Model, Map.State, U64 -> Model
    smoke_walk = |bytes, model, map, steps| {
        smoke_walk_go(bytes, model, map, steps)
    }

    smoke_walk_go : List(U8), Model, Map.State, U64 -> Model
    smoke_walk_go = |bytes, model, map, left| {
        if left == 0 {
            model
        } else {
            m1 = turn(model, 0.05)
            m2 = try_forward(bytes, m1, map, 8)
            smoke_walk_go(bytes, m2, map, left - 1)
        }
    }
}
