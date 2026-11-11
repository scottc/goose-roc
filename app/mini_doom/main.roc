app [main!] {
    pf: platform "../../platform/main.roc",
}

import pf.Stdout
import pf.Os
import pf.Bump
import pf.Gfx
import Wad
import Map
import Game
import Render

default_wad : Str
default_wad = "data/freedoom1-e1m1.wad"

main! : List(Str) => Try(
    {},
    [Exit(I32), StdoutErr(Str), OsErr(Str), BumpErr(Str), WadErr(Str), GfxErr(Str)],
)
main! = |_args| {
    Bump.set_limit_bytes!(128 * 1024 * 1024)
        .map_err(|BumpErr(e)| BumpErr(e))?

    Stdout.line!("mini doom: reading ${default_wad}")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    bytes =
        Os.read_file!(default_wad)
            .map_err(|OsErr(e)| OsErr(e))?

    Stdout.line!("read bytes...")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    loaded =
        Wad.load_from_bytes(bytes)
            .map_err(|WadErr(e)| WadErr(e))?

    Stdout.line!("loaded...")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    map =
        Map.load(loaded)
            .map_err(|WadErr(e)| WadErr(e))?

    Stdout.line!("map...")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    things =
        Wad.lump_bytes(loaded, "THINGS")
            .map_err(|WadErr(e)| WadErr(e))?

    Stdout.line!("things...")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    game0 =
        Game.load_from_things(things)
            .map_err(|WadErr(e)| WadErr(e))?

    Stdout.line!("game...")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    n = List.len(game0.actors).to_str()
    px = game0.player.x.to_str()
    py = game0.player.y.to_str()
    Stdout.line!("mini doom: actors=${n} at (${px}, ${py})")
        .map_err(|StdoutErr(e)| StdoutErr(e))?

    win =
        Gfx.init!("goose-roc mini doom", 640, 400)
            .map_err(|GfxErr(e)| GfxErr(e))?

    run_loop!(win, map, game0)?

    Gfx.shutdown!(win)
        .map_err(|GfxErr(e)| GfxErr(e))?
    Ok({})
}

run_loop! : U64, Map.State, Game.Model => Try({}, [GfxErr(Str)])
run_loop! = |win, map, game| {
    Render.frame!(win, map, game)
        .map_err(|GfxErr(e)| GfxErr(e))?
    Gfx.present!(win)
        .map_err(|GfxErr(e)| GfxErr(e))?

    game2 = step_input!(win, map, game)?
    _ = Os.sleep_ms!(16)
    run_loop!(win, map, game2)
}

step_input! : U64, Map.State, Game.Model => Try(Game.Model, [GfxErr(Str)])
step_input! = |win, map, game| {
    g1 = key_move!(win, map, game, "w", 8.0)?
    g2 = key_move!(win, map, g1, "s", -8.0)?
    g3 = key_turn!(win, g2, "a", -0.08)?
    g4 = key_turn!(win, g3, "d", 0.08)?
    Ok(g4)
}

key_move! : U64, Map.State, Game.Model, Str, F32 => Try(Game.Model, [GfxErr(Str)])
key_move! = |win, map, game, key, dist| {
    down =
        Gfx.key_down!(win, key)
            .map_err(|GfxErr(e)| GfxErr(e))?
    if down {
        Ok(Game.try_forward(game, map, dist))
    } else {
        Ok(game)
    }
}

key_turn! : U64, Game.Model, Str, F32 => Try(Game.Model, [GfxErr(Str)])
key_turn! = |win, game, key, da| {
    down =
        Gfx.key_down!(win, key)
            .map_err(|GfxErr(e)| GfxErr(e))?
    if down {
        Ok(Game.turn(game, da))
    } else {
        Ok(game)
    }
}
