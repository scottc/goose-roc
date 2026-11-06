import Host

Gfx := {}.
{
    GfxEvent : Host.GfxEvent

    init! : Str, I32, I32 => Try(U64, [GfxErr(Str)])
    init! = |title, w, h| Host.gfx_init!(title, w, h)

    shutdown! : U64 => Try({}, [GfxErr(Str)])
    shutdown! = |win| Host.gfx_shutdown!(win)

    frame! : U64 => Try(Bool, [GfxErr(Str)])
    frame! = |win| Host.gfx_frame!(win)

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

    key_down! : U64, Str => Try(Bool, [GfxErr(Str)])
    key_down! = |win, name| Host.gfx_key_down!(win, name)

    key_pressed! : U64, Str => Try(Bool, [GfxErr(Str)])
    key_pressed! = |win, name| Host.gfx_key_pressed!(win, name)

    mouse_delta! : U64 => Try({ dx: F32, dy: F32 }, [GfxErr(Str)])
    mouse_delta! = |win| Host.gfx_mouse_delta!(win)

    mouse_pos! : U64 => Try({ x: F32, y: F32 }, [GfxErr(Str)])
    mouse_pos! = |win| Host.gfx_mouse_pos!(win)

    mouse_down! : U64, I32 => Try(Bool, [GfxErr(Str)])
    mouse_down! = |win, btn| Host.gfx_mouse_down!(win, btn)

    set_mouse_relative! : U64, Bool => Try({}, [GfxErr(Str)])
    set_mouse_relative! = |win, on| Host.gfx_set_mouse_relative!(win, on)

    set_cursor_visible! : U64, Bool => Try({}, [GfxErr(Str)])
    set_cursor_visible! = |win, v| Host.gfx_set_cursor_visible!(win, v)

    delta_time! : U64 => Try(F64, [GfxErr(Str)])
    delta_time! = |win| Host.gfx_delta_time!(win)

    texture_create! : I32, I32 => Try(U64, [GfxErr(Str)])
    texture_create! = |w, h| Host.gfx_texture_create!(w, h)

    texture_destroy! : U64 => Try({}, [GfxErr(Str)])
    texture_destroy! = |tex| Host.gfx_texture_destroy!(tex)

    texture_upload_rgba! : U64, List(U8) => Try({}, [GfxErr(Str)])
    texture_upload_rgba! = |tex, rgba| Host.gfx_texture_upload_rgba!(tex, rgba)

    draw_textured_quad! :
        U64, F32, F32, F32, F32, U64, F32, F32, F32, F32
        => Try({}, [GfxErr(Str)])
    draw_textured_quad! = |win, x, y, w, h, tex, u0, v0, u1, v1|
        Host.gfx_draw_textured_quad!(win, x, y, w, h, tex, u0, v0, u1, v1)
}
