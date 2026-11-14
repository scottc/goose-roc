import pf.Gfx
import Map
import Game

## Column raycaster — type module
Render := {}.
{
    scr_w : F32
    scr_w = 640.0

    scr_h : F32
    scr_h = 400.0

    ray_count : U64
    ray_count = 160

    fov : F32
    fov = 1.2

    frame! : U64, List(U8), Map.State, Game.Model => Try({}, [GfxErr(Str)])
    frame! = |win, bytes, map, game| {
        # Sky
        Gfx.clear!(win, 0.45, 0.55, 0.75, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?
        # Floor band
        Gfx.draw_rect!(win, 0, scr_h * 0.5, scr_w, scr_h * 0.5, 0.25, 0.22, 0.18, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?
        # Debug: forced red rect
        Gfx.draw_rect!(win, 8, 8, 40, 40, 1.0, 0.0, 0.0, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?
        draw_columns!(win, bytes, map, game, 0)?
        draw_player_marker!(win)?
        Ok({})
    }

    draw_player_marker! : U64 => Try({}, [GfxErr(Str)])
    draw_player_marker! = |win| {
        sx = scr_w * 0.5
        sy = scr_h * 0.5
        Gfx.draw_rect!(win, sx - 3, sy - 3, 6, 6, 1.0, 0.9, 0.2, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?
        Ok({})
    }

    draw_columns! : U64, List(U8), Map.State, Game.Model, U64 => Try({}, [GfxErr(Str)])
    draw_columns! = |win, bytes, map, game, col| {
        if col >= ray_count {
            Ok({})
        } else {
            t = (col.to_f32() / ray_count.to_f32()) - 0.5
            ang = game.player.yaw + t * fov
            dist = cast_ray(bytes, map, game.player.x, game.player.y, ang)
            col_w = scr_w / ray_count.to_f32()
            x = col.to_f32() * col_w
            if dist < 1.0 {
                draw_columns!(win, bytes, map, game, col + 1)
            } else if dist > 4000.0 {
                draw_columns!(win, bytes, map, game, col + 1)
            } else {
                scale = 12000.0 / dist
                half0 = scale * 0.5
                half =
                    if half0 > scr_h * 0.45 {
                        scr_h * 0.45
                    } else {
                        half0
                    }
                y0 = scr_h * 0.5 - half
                h = half * 2.0
                shade = 1.0 / (1.0 + dist * 0.004)
                r = 0.55 * shade
                g = 0.5 * shade
                b = 0.45 * shade
                Gfx.draw_rect!(win, x, y0, col_w + 1.0, h, r, g, b, 1.0)
                    .map_err(|GfxErr(e)| GfxErr(e))?
                draw_columns!(win, bytes, map, game, col + 1)
            }
        }
    }

    cast_ray : List(U8), Map.State, F32, F32, F32 -> F32
    cast_ray = |bytes, map, ox, oy, ang| {
        cast_ray_go(bytes, map, 0, ox, oy, ang, 1.0e9)
    }

    cast_ray_go : List(U8), Map.State, U64, F32, F32, F32, F32 -> F32
    cast_ray_go = |bytes, map, i, ox, oy, ang, best| {
        if i >= map.ld_count {
            best
        } else {
            match Map.get_line(bytes, map, i) {
                Err(_) => best
                Ok(line) => {
                    solid = line_is_solid(line)
                    if solid {
                        dx = Game.cos_approx(ang) * 5000.0
                        dy = Game.sin_approx(ang) * 5000.0
                        hit = seg_intersect(
                            ox, oy, ox + dx, oy + dy,
                            line.ax, line.ay, line.bx, line.by,
                        )
                        match hit {
                            None => cast_ray_go(bytes, map, i + 1, ox, oy, ang, best)
                            Some(seg_t) => {
                                dist = seg_t * 5000.0
                                next = better_dist(dist, best)
                                cast_ray_go(bytes, map, i + 1, ox, oy, ang, next)
                            }
                        }
                    } else {
                        cast_ray_go(bytes, map, i + 1, ox, oy, ang, best)
                    }
                }
            }
        }
    }

    line_is_solid : Map.Line -> Bool
    line_is_solid = |line| {
        if line.back < 0 {
            True
        } else if line.back == 65535 {
            True
        } else {
            False
        }
    }

    better_dist : F32, F32 -> F32
    better_dist = |dist, best| {
        if dist > 1.0 {
            if dist < best {
                dist
            } else {
                best
            }
        } else {
            best
        }
    }

    seg_intersect :
        F32, F32, F32, F32, F32, F32, F32, F32
        -> [Some(F32), None]
    seg_intersect = |ax, ay, bx, by, cx, cy, dx, dy| {
        abx = bx - ax
        aby = by - ay
        cdx = dx - cx
        cdy = dy - cy
        den = abx * cdy - aby * cdx
        if near_zero(den) {
            None
        } else {
            acx = cx - ax
            acy = cy - ay
            seg_t = (acx * cdy - acy * cdx) / den
            u = (acx * aby - acy * abx) / den
            if in_unit(seg_t) {
                if in_unit(u) {
                    Some(seg_t)
                } else {
                    None
                }
            } else {
                None
            }
        }
    }

    near_zero : F32 -> Bool
    near_zero = |den| {
        if den < 0.0001 {
            if den > -0.0001 {
                True
            } else {
                False
            }
        } else {
            False
        }
    }

    in_unit : F32 -> Bool
    in_unit = |v| {
        if v >= 0.0 {
            if v <= 1.0 {
                True
            } else {
                False
            }
        } else {
            False
        }
    }
}
