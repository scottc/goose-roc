app [main!] {
    pf: platform "../platform/main.roc",
    roc: "nightly-2026-10-21-5349569",
}

import pf.Stdout

main! : List(Str) => Try({}, [Exit(I32), StdoutErr(Str)])
main! = |_args| {
    Stdout.line!("hello from roc")?
    Ok({})
}
