# app/smoke_os.roc
app [main!] { pf: platform "../platform/main.roc", roc: "nightly-…" }

import pf.Stdout
import pf.Os

main! = |_args| {
    t = Os.clock_secs!({})?
    Stdout.line!("clock=${t.to_str()}")?
    _ = Os.write_file!("/tmp/goose-roc-smoke.bin", [1, 2, 3])?
    bytes = Os.read_file!("/tmp/goose-roc-smoke.bin")?
    Stdout.line!("read_len=${List.len(bytes).to_str()}")?
    Ok({})
}
