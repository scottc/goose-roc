# app/smoke_gfx.roc  — native only; expect GfxErr on headless CI
app [main!] { pf: platform "../platform/main.roc", roc: "nightly-…" }

import pf.Gfx
import pf.Stdout

main! = |_args| {
    win = Gfx.init!("goose-roc", 640, 480)?
    _ = Gfx.clear!(win, 0.1, 0.1, 0.15, 1.0)?
    _ = Gfx.present!(win)?
    _ = Gfx.shutdown!(win)?
    Stdout.line!("gfx smoke ok")?
    Ok({})
}
