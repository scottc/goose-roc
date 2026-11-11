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
import Render

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
    Bump.set_limit_bytes!(128 * 1024 * 1024)
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
            Err(_) =>
                match Flats.load_flat(loaded, "FLAT5_4") {
                    Ok(f) => Ok(f)
                    Err(_) => Flats.load_flat(loaded, "FLOOR0_1")
                }
        }
            .map_err(|WadErr(e)| WadErr(e))?

    Stdout.line!(
        "mini doom: actors=${List.len(game0.actors).to_str()} at (${game0.player.x.to_str()}, ${game0.player.y.to_str()})",
    )
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    win =
        Gfx.init!("goose-roc mini doom", 640, 400)
            .map_err(|GfxErr(e)| GfxErr(e))?

    run_loop!(win, map, game0, playpal, flat)
        .map_err(|GfxErr(e)| GfxErr(e))?

    Gfx.shutdown!(win)
        .map_err(|GfxErr(e)| GfxErr(e))?

    Stdout.line!("mini doom: exit ok")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    Ok({})
}

is_quit_key : Str -> Bool
is_quit_key = |k| {
    if k == "escape" {
        True
    } else if k == "Escape" {
        True
    } else if k == "q" {
        True
    } else {
        False
    }
}

drain_quit! : U64 => Try(Bool, [GfxErr(Str)])
drain_quit! = |win| {
    drain_quit_n!(win, 8)
}

drain_quit_n! : U64, U64 => Try(Bool, [GfxErr(Str)])
drain_quit_n! = |win, n| {
    if n == 0 {
        Ok(False)
    } else {
        ev =
            Gfx.poll!(win)
                .map_err(|GfxErr(e)| GfxErr(e))?
        match ev {
            Quit => Ok(True)
            KeyDown(k) => {
                if is_quit_key(k) {
                    Ok(True)
                } else {
                    drain_quit_n!(win, n - 1)
                }
            }
            _ => drain_quit_n!(win, n - 1)
        }
    }
}

key_held! : U64, Str => Bool
key_held! = |win, name| {
    match Gfx.key_down!(win, name) {
        Ok(v) => v
        Err(_) => False
    }
}

step_input! : U64, Game.Model, Map.State => Try(Game.Model, [GfxErr(Str)])
step_input! = |win, game, map| {
    g1 =
        if key_held!(win, "w") {
            Game.try_forward(game, map, 8)
        } else {
            game
        }
    g2 =
        if key_held!(win, "s") {
            Game.try_forward(g1, map, -8)
        } else {
            g1
        }
    g3 =
        if key_held!(win, "a") {
            Game.turn(g2, -0.08)
        } else {
            g2
        }
    g4 =
        if key_held!(win, "d") {
            Game.turn(g3, 0.08)
        } else {
            g3
        }
    Ok(g4)
}

run_loop! :
    U64,
    Map.State,
    Game.Model,
    List(U8),
    List(U8)
    => Try({}, [GfxErr(Str)])
run_loop! = |win, map, game, playpal, flat| {
    quit =
        drain_quit!(win)
            .map_err(|GfxErr(e)| GfxErr(e))?
    if quit {
        Ok({})
    } else {
        game2 =
            step_input!(win, game, map)
                .map_err(|GfxErr(e)| GfxErr(e))?

        Render.frame!(win, map, game2, playpal, flat)
            .map_err(|GfxErr(e)| GfxErr(e))?

        _ =
            match Os.sleep_ms!(16) {
                Ok(_) => {}
                Err(_) => {}
            }

        run_loop!(win, map, game2, playpal, flat)
    }
}
