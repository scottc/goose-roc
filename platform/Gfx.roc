import Host

Gfx := {}.
{
    GfxEvent : Host.GfxEvent

    init! : Str, I32, I32 => Try(U64, [GfxErr(Str)])
    init! = |title, w, h| Host.gfx_init!(title, w, h)

    shutdown! : U64 => Try({}, [GfxErr(Str)])
    shutdown! = |win| Host.gfx_shutdown!(win)

    poll! : U64 => Try(Host.GfxEvent, [GfxErr(Str)])
    poll! = |win| Host.gfx_poll!(win)

    clear! : U64, F32, F32, F32, F32 => Try({}, [GfxErr(Str)])
    clear! = |win, r, g, b, a| Host.gfx_clear!(win, r, g, b, a)

    present! : U64 => Try({}, [GfxErr(Str)])
    present! = |win| Host.gfx_present!(win)

    window_size! : U64 => Try({ width: I32, height: I32 }, [GfxErr(Str)])
    window_size! = |win| Host.gfx_window_size!(win)

    set_title! : U64, Str => Try({}, [GfxErr(Str)])
    set_title! = |win, title| Host.gfx_set_title!(win, title)

    draw_rect! : U64, F32, F32, F32, F32, F32, F32, F32, F32 => Try({}, [GfxErr(Str)])
    draw_rect! = |win, x, y, w, h, r, g, b, a|
        Host.gfx_draw_rect!(win, x, y, w, h, r, g, b, a)
}
