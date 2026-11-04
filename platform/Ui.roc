import Host

Ui := {}.
{
    frame_begin! : U64 => Try({}, [UiErr(Str)])
    frame_begin! = |win| Host.ui_frame_begin!(win)

    frame_end! : U64 => Try({}, [UiErr(Str)])
    frame_end! = |win| Host.ui_frame_end!(win)

    text! : Str, F32, F32 => Try({}, [UiErr(Str)])
    text! = |s, x, y| Host.ui_text!(s, x, y)

    button! : Str, F32, F32, F32, F32 => Try(Bool, [UiErr(Str)])
    button! = |s, x, y, w, h| Host.ui_button!(s, x, y, w, h)

    checkbox! : Str, F32, F32, Bool => Try(Bool, [UiErr(Str)])
    checkbox! = |s, x, y, on| Host.ui_checkbox!(s, x, y, on)

    slider! : Str, F32, F32, F32, F32, F32 => Try(F32, [UiErr(Str)])
    slider! = |s, x, y, w, lo, hi| Host.ui_slider!(s, x, y, w, lo, hi)
}
