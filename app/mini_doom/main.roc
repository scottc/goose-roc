app [main!] {
    pf: platform "../../platform/main.roc",
    roc: "nightly-2026-10-28-bad769b",
}

import pf.Stdout
import pf.Os
import pf.Bump
import pf.Gfx
import Wad
import Map
import Game
import Palette
import Flats

default_wad : Str
default_wad = "data/freedoom1-e1m1.wad"

wad_path_from_args : List(Str) -> Str
wad_path_from_args = |args| {
    len = List.len(args)
    if len >= 3 {
        flag =
            match List.get(args, 1) {
                Ok(s) => s
                Err(_) => ""
            }
        path =
            match List.get(args, 2) {
                Ok(s) => s
                Err(_) => default_wad
            }
        if flag == "--wad" {
            path
        } else {
            default_wad
        }
    } else {
        default_wad
    }
}

main! : List(Str) => Try(
    {},
    [Exit(I32), StdoutErr(Str), OsErr(Str), BumpErr(Str), WadErr(Str), GfxErr(Str)],
)
main! = |args| {
    # Geometry + things only; no big RGB lists
    Bump.set_limit_bytes!(64 * 1024 * 1024)
        .map_err(|BumpErr(e)| BumpErr(e))?

    path = wad_path_from_args(args)
    Stdout.line!("mini doom: reading ${path}")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    bytes =
        Os.read_file!(path)
            .map_err(|OsErr(e)| OsErr(e))?

    loaded =
        Wad.load_from_bytes(bytes)
            .map_err(|WadErr(e)| WadErr(e))?

    map =
        Map.load(loaded)
            .map_err(|WadErr(e)| WadErr(e))?

    things =
        Wad.records(loaded.wad, loaded.lumps, "THINGS", 10)
            .map_err(|WadErr(e)| WadErr(e))?

    game0 =
        Game.load_from_things(things)
            .map_err(|WadErr(e)| WadErr(e))?

    playpal =
        Palette.load_playpal(loaded)
            .map_err(|WadErr(e)| WadErr(e))?

    flat =
        match Flats.load_flat(loaded, "FLOOR4_8") {
            Ok(f) => Ok(f)
            Err(_) => {
                match Flats.load_flat(loaded, "FLAT5_4") {
                    Ok(f) => Ok(f)
                    Err(_) => Flats.load_flat(loaded, "FLOOR0_1")
                }
            }
        }
            .map_err(|WadErr(e)| WadErr(e))?

    Stdout.line!(
        "mini doom: actors=${List.len(game0.actors).to_str()} at (${game0.player.x.to_str()}, ${game0.player.y.to_str()})",
    )
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    Stdout.line!("before gfx_init").map_err(|StdoutErr(e)| StdoutErr(e))?

    win =
        Gfx.init!("goose-roc mini doom", 640, 400)
            .map_err(|GfxErr(e)| GfxErr(e))?

    # One frame: sky, floor band, flat sample grid (draw_rect only)
    draw_frame!(win, playpal, flat)
        .map_err(
            |err| {
                match err {
                    GfxErr(e) => GfxErr(e)
                    WadErr(e) => WadErr(e)
                }
            },
        )?

    loop_frames!(win, map, game0, playpal, flat, 0, 300)
        .map_err(|e| e)?

    Gfx.shutdown!(win)
        .map_err(|GfxErr(e)| GfxErr(e))?

    Stdout.line!("mini doom: gfx rect smoke done")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    Ok({})
}

## Sky + floor + 16×16 samples of the 64×64 flat (scaled).
draw_frame! : U64, List(U8), List(U8) => Try({}, [GfxErr(Str), WadErr(Str)])
draw_frame! = |win, playpal, flat| {
    Gfx.clear!(win, 0.05, 0.05, 0.08, 1.0)
        .map_err(|GfxErr(e)| GfxErr(e))?

    # sky
    Gfx.draw_rect!(win, 0, 0, 640, 200, 0.2, 0.35, 0.55, 1.0)
        .map_err(|GfxErr(e)| GfxErr(e))?

    # floor
    Gfx.draw_rect!(win, 0, 200, 640, 200, 0.15, 0.12, 0.1, 1.0)
        .map_err(|GfxErr(e)| GfxErr(e))?

    draw_flat_samples!(win, playpal, flat, 0)
        .map_err(|e| e)?

    Gfx.present!(win)
        .map_err(|GfxErr(e)| GfxErr(e))?

    Ok({})
}

## i in 0..256 → 16×16 grid, each cell 8×8 px from flat texel (i*4 % 64, …)
draw_flat_samples! : U64, List(U8), List(U8), U64 => Try({}, [GfxErr(Str), WadErr(Str)])
draw_flat_samples! = |win, playpal, flat, i| {
    if i >= 256 {
        Ok({})
    } else {
        gx = i % 16
        gy = i // 16
        fx = (gx * 4) % 64
        fy = (gy * 4) % 64
        match Flats.index_at(flat, fx, fy) {
            Err(e) => Err(e)
            Ok(ci) => {
                match Palette.rgb_at(playpal, ci.to_u64()) {
                    Err(e) => Err(e)
                    Ok(c) => {
                        x = 40 + gx.to_f32() * 8
                        y = 40 + gy.to_f32() * 8
                        r = c.r.to_f32() / 255
                        g = c.g.to_f32() / 255
                        b = c.b.to_f32() / 255
                        Gfx.draw_rect!(win, x, y, 8, 8, r, g, b, 1.0)
                            .map_err(|GfxErr(e)| GfxErr(e))?
                        draw_flat_samples!(win, playpal, flat, i + 1)
                    }
                }
            }
        }
    }
}

loop_frames! :
    U64,
    Map.State,
    Game.Model,
    List(U8),
    List(U8),
    U64,
    U64
    => Try({}, [GfxErr(Str), WadErr(Str)])
loop_frames! = |win, map, game, playpal, flat, frame, max_frames| {
    if frame >= max_frames {
        Ok({})
    } else {
        ev =
            Gfx.poll!(win)
                .map_err(|GfxErr(e)| GfxErr(e))?
        match ev {
            Quit => Ok({})
            KeyDown(k) => {
                game2 = apply_key(game, map, k)
                draw_frame!(win, playpal, flat)
                    .map_err(|e| e)?
                # show player as a rect
                draw_player!(win, game2)
                    .map_err(|GfxErr(e)| GfxErr(e))?
                Gfx.present!(win)
                    .map_err(|GfxErr(e)| GfxErr(e))?
                loop_frames!(win, map, game2, playpal, flat, frame + 1, max_frames)
            }
            _ => {
                draw_frame!(win, playpal, flat)
                    .map_err(|e| e)?
                draw_player!(win, game)
                    .map_err(|GfxErr(e)| GfxErr(e))?
                Gfx.present!(win)
                    .map_err(|GfxErr(e)| GfxErr(e))?
                loop_frames!(win, map, game, playpal, flat, frame + 1, max_frames)
            }
        }
    }
}

apply_key : Game.Model, Map.State, Str -> Game.Model
apply_key = |game, map, k| {
    if k == "w" {
        Game.try_forward(game, map, 16)
    } else if k == "s" {
        Game.try_forward(game, map, -16)
    } else if k == "a" {
        Game.turn(game, -0.15)
    } else if k == "d" {
        Game.turn(game, 0.15)
    } else {
        game
    }
}

## Map player xy into window (crude top-down: center + scale).
draw_player! : U64, Game.Model => Try({}, [GfxErr(Str)])
draw_player! = |win, game| {
    # E1M1 coords ~ -400..400 → screen
    sx = 320 + game.player.x * 0.15
    sy = 200 - game.player.y * 0.15
    Gfx.draw_rect!(win, sx - 4, sy - 4, 8, 8, 1.0, 0.9, 0.2, 1.0)
        .map_err(|GfxErr(e)| GfxErr(e))?
    Ok({})
}
