module [
    GfxEvent,
    init!,
    shutdown!,
    poll!,
    clear!,
    present!,
    window_size!,
    run_frame!,
]

import Host

GfxEvent : Host.GfxEvent  # if your Roc allows; else duplicate the tag union

# ## Minimal event set — expand when Goose gfx events are wired.
# GfxEvent : [
#     Quit,
#     KeyDown(Str),
#     KeyUp(Str),
#     Resize(I32, I32),
#     None,
# ]

## Create window + device. Returns opaque handle.
init! : Str, I32, I32 => Try(U64, [GfxErr(Str)])
init! = |title, w, h| Host.gfx_init!(title, w, h)

shutdown! : U64 => Try({}, [GfxErr(Str)])
shutdown! = |win| Host.gfx_shutdown!(win)

poll! : U64 => Try(GfxEvent, [GfxErr(Str)])
poll! = |win| Host.gfx_poll!(win)

clear! : U64, F32, F32, F32, F32 => Try({}, [GfxErr(Str)])
clear! = |win, r, g, b, a| Host.gfx_clear!(win, r, g, b, a)

present! : U64 => Try({}, [GfxErr(Str)])
present! = |win| Host.gfx_present!(win)

window_size! : U64 => Try({ width: I32, height: I32 }, [GfxErr(Str)])
window_size! = |win| Host.gfx_window_size!(win)

## One frame helper for smoke tests (not a full game loop).
run_frame! : U64, ({} => Try({}, [GfxErr(Str)])) => Try(Bool, [GfxErr(Str)])
run_frame! = |win, draw!| {
    ev = poll!(win)?
    match ev {
        Quit => Ok(Bool.false)
        _ => {
            draw!({})?
            present!(win)?
            Ok(Bool.true)
        }
    }
}
