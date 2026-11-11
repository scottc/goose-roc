import pf.Gfx
import Map
import Game

Render := {}.
{
    sw : F32
    sw = 640

    sh : F32
    sh = 400

    bar_h : F32
    bar_h = 36

    view_h : F32
    view_h = 364

    horizon : F32
    horizon = 182

    rays : U64
    rays = 160

    frame! :
        U64,
        Map.State,
        Game.Model,
        List(U8),
        List(U8)
        => Try({}, [GfxErr(Str)])
    frame! = |win, map, game, _pal, _flat| {
        Gfx.clear!(win, 0.05, 0.06, 0.08, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?

        # sky
        Gfx.draw_rect!(win, 0, 0, sw, horizon, 0.35, 0.5, 0.75, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?
        # floor band
        Gfx.draw_rect!(win, 0, horizon, sw, view_h - horizon, 0.2, 0.16, 0.12, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?

        draw_cols!(win, map, game, 0)
            .map_err(|GfxErr(e)| GfxErr(e))?

        draw_actors!(win, map, game, 0)
            .map_err(|GfxErr(e)| GfxErr(e))?

        # status bar
        Gfx.draw_rect!(win, 0, view_h, sw, bar_h, 0.12, 0.12, 0.13, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?
        # health bar (0..100 → width)
        hw = (game.player.health.to_f32() / 100) * 120
        Gfx.draw_rect!(win, 12, view_h + 10, hw, 14, 0.8, 0.15, 0.12, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?

        # player arrow on minimap inset
        mx = 560 + game.player.x * 0.05
        my = 40 - game.player.y * 0.05
        Gfx.draw_rect!(win, mx - 3, my - 3, 6, 6, 1.0, 0.9, 0.2, 1.0)
            .map_err(|GfxErr(e)| GfxErr(e))?

        Gfx.present!(win)
            .map_err(|GfxErr(e)| GfxErr(e))?
        Ok({})
    }

    draw_cols! : U64, Map.State, Game.Model, U64 => Try({}, [GfxErr(Str)])
    draw_cols! = |win, map, game, col| {
        if col >= rays {
            Ok({})
        } else {
            t = (col.to_f32() / rays.to_f32()) - 0.5
            ang = game.player.yaw + t * 1.15
            hit = ray_wall(map, game.player.x, game.player.y, game.player.z + 41, ang)
            match hit {
                None => draw_cols!(win, map, game, col + 1)
                Some(h) => {
                    d =
                        if h.dist < 4 {
                            4.to_f32()
                        } else {
                            h.dist
                        }
                    # project vertical span
                    scale = 9000.to_f32() / d
                    y0 = horizon - (h.top - game.player.z - 41) * scale * 0.05
                    y1 = horizon - (h.bottom - game.player.z - 41) * scale * 0.05
                    top =
                        if y0 < y1 {
                            y0
                        } else {
                            y1
                        }
                    bot =
                        if y0 < y1 {
                            y1
                        } else {
                            y0
                        }
                    top2 =
                        if top < 0 {
                            0
                        } else if top > view_h {
                            view_h
                        } else {
                            top
                        }
                    bot2 =
                        if bot < 0 {
                            0
                        } else if bot > view_h {
                            view_h
                        } else {
                            bot
                        }
                    hh = bot2 - top2
                    if hh > 1 {
                        x = col.to_f32() * (sw / rays.to_f32())
                        w = sw / rays.to_f32() + 0.6
                        shade = 1.0 / (1.0 + d * 0.003)
                        # one-sided vs portal step
                        r = h.shade * 0.55 * shade
                        g = h.shade * 0.5 * shade
                        b = h.shade * 0.4 * shade
                        Gfx.draw_rect!(win, x, top2, w, hh, r, g, b, 1.0)
                            .map_err(|GfxErr(e)| GfxErr(e))?
                        draw_cols!(win, map, game, col + 1)
                    } else {
                        draw_cols!(win, map, game, col + 1)
                    }
                }
            }
        }
    }

    Hit : { dist : F32, bottom : F32, top : F32, shade : F32 }

    ray_wall : Map.State, F32, F32, F32, F32 -> [Some(Hit), None]
    ray_wall = |map, ox, oy, eye_z, ang| {
        ray_go(map, ox, oy, eye_z, ang, 0, 5000, 0, 0, 0, False)
    }

    ## best_* valid only if found
    ray_go :
        Map.State,
        F32,
        F32,
        F32,
        F32,
        U64,
        F32,
        F32,
        F32,
        F32,
        Bool
        -> [Some(Hit), None]
    ray_go = |map, ox, oy, eye_z, ang, i, best, bb, bt, bs, found| {
        n = List.len(map.lines)
        if i >= n {
            if found {
                Some({ dist: best, bottom: bb, top: bt, shade: bs })
            } else {
                None
            }
        } else {
            match List.get(map.lines, i) {
                Err(_) => ray_go(map, ox, oy, eye_z, ang, i + 1, best, bb, bt, bs, found)
                Ok(line) => {
                    dx = Game.cos_approx(ang) * 5000
                    dy = Game.sin_approx(ang) * 5000
                    match ray_seg(ox, oy, ox + dx, oy + dy, line.ax, line.ay, line.bx, line.by) {
                        None => ray_go(map, ox, oy, eye_z, ang, i + 1, best, bb, bt, bs, found)
                        Some(t) => {
                            dist = t * 5000
                            if dist <= 1 {
                                ray_go(map, ox, oy, eye_z, ang, i + 1, best, bb, bt, bs, found)
                            } else if dist >= best {
                                ray_go(map, ox, oy, eye_z, ang, i + 1, best, bb, bt, bs, found)
                            } else {
                                match wall_span(map, line, eye_z) {
                                    None => ray_go(map, ox, oy, eye_z, ang, i + 1, best, bb, bt, bs, found)
                                    Some(span) =>
                                        ray_go(
                                            map,
                                            ox,
                                            oy,
                                            eye_z,
                                            ang,
                                            i + 1,
                                            dist,
                                            span.bottom,
                                            span.top,
                                            span.shade,
                                            True,
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Span : { bottom : F32, top : F32, shade : F32 }

    ## One-sided: full front sector column. Two-sided: upper/lower step only.
    wall_span : Map.State, Map.Line, F32 -> [Some(Span), None]
    wall_span = |map, line, _eye_z| {
        match List.get(map.sides, line.front) {
            Err(_) => None
            Ok(side) => {
                match List.get(map.sectors, side.sector) {
                    Err(_) => None
                    Ok(front) => {
                        if line.back == 65535 {
                            Some({
                                bottom: front.floor,
                                top: front.ceiling,
                                shade: 0.9 + front.light * 0.5,
                            })
                        } else {
                            match List.get(map.sides, line.back) {
                                Err(_) => None
                                Ok(bside) => {
                                    match List.get(map.sectors, bside.sector) {
                                        Err(_) => None
                                        Ok(back) => {
                                            # pick the larger step (upper or lower)
                                            upper = front.ceiling - back.ceiling
                                            lower = back.floor - front.floor
                                            if upper > 4 {
                                                Some({
                                                    bottom: back.ceiling,
                                                    top: front.ceiling,
                                                    shade: 0.7 + front.light * 0.4,
                                                })
                                            } else if lower > 4 {
                                                Some({
                                                    bottom: front.floor,
                                                    top: back.floor,
                                                    shade: 0.65 + front.light * 0.4,
                                                })
                                            } else {
                                                None
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

    ray_seg : F32, F32, F32, F32, F32, F32, F32, F32 -> [Some(F32), None]
    ray_seg = |ax, ay, bx, by, cx, cy, dx, dy| {
        abx = bx - ax
        aby = by - ay
        cdx = dx - cx
        cdy = dy - cy
        den = abx * cdy - aby * cdx
        den_bad =
            if den < 0.00001 {
                if den > -0.00001 {
                    True
                } else {
                    False
                }
            } else {
                False
            }
        if den_bad {
            None
        } else {
            t = ((cx - ax) * cdy - (cy - ay) * cdx) / den
            u = ((cx - ax) * aby - (cy - ay) * abx) / den
            t_ok =
                if t > 0.001 {
                    if t <= 1 {
                        True
                    } else {
                        False
                    }
                } else {
                    False
                }
            u_ok =
                if u >= 0 {
                    if u <= 1 {
                        True
                    } else {
                        False
                    }
                } else {
                    False
                }
            if t_ok {
                if u_ok {
                    Some(t)
                } else {
                    None
                }
            } else {
                None
            }
        }
    }

    ## Simple billboards for nearby actors (rects in view space approximation).
    draw_actors! : U64, Map.State, Game.Model, U64 => Try({}, [GfxErr(Str)])
    draw_actors! = |win, map, game, i| {
        n = List.len(game.actors)
        if i >= n {
            Ok({})
        } else {
            match List.get(game.actors, i) {
                Err(_) => draw_actors!(win, map, game, i + 1)
                Ok(a) => {
                    if a.alive {
                        # camera-relative
                        dx = a.x - game.player.x
                        dy = a.y - game.player.y
                        # rotate by -yaw
                        c = Game.cos_approx(-game.player.yaw)
                        s = Game.sin_approx(-game.player.yaw)
                        rx = dx * c - dy * s
                        ry = dx * s + dy * c
                        if ry > 8 {
                            if ry < 2000 {
                                sx = sw / 2 + rx * (500 / ry)
                                shh = 4000 / ry
                                sy = horizon - shh / 2
                                Gfx.draw_rect!(win, sx - 4, sy, 8, shh, 0.9, 0.3, 0.25, 1.0)
                                    .map_err(|GfxErr(e)| GfxErr(e))?
                                draw_actors!(win, map, game, i + 1)
                            } else {
                                draw_actors!(win, map, game, i + 1)
                            }
                        } else {
                            draw_actors!(win, map, game, i + 1)
                        }
                    } else {
                        draw_actors!(win, map, game, i + 1)
                    }
                }
            }
        }
    }
}
