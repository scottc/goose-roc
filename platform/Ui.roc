module [frame_begin!, frame_end!, text!, button!]

import Host

## Immediate-mode UI tied to a gfx window handle.
frame_begin! : U64 => Try({}, [UiErr(Str)])
frame_begin! = |win| Host.ui_frame_begin!(win)

frame_end! : U64 => Try({}, [UiErr(Str)])
frame_end! = |win| Host.ui_frame_end!(win)

text! : Str, F32, F32 => Try({}, [UiErr(Str)])
text! = |label, x, y| Host.ui_text!(label, x, y)

button! : Str, F32, F32, F32, F32 => Try(Bool, [UiErr(Str)])
button! = |label, x, y, w, h| Host.ui_button!(label, x, y, w, h)
