app [main!] {
    pf: platform "../platform/main.roc",
    roc: "nightly-2026-10-21-5349569",

    }
import pf.Arena
import pf.Stdout

main! : List(Str) => Try({}, [Exit(I32), StdoutErr(Str)])
main! = |_args| {
    Arena.configure!(64 * 1024 * 1024) # 64MiB
        .map_err(|ArenaErr(e)| ArenaErr(e))?

    Stdout.line!("hello from roc")?

    # Grow arena at runtime!
    Arena.configure!(256 * 1024 * 1024) # 256MiB
        .map_err(|ArenaErr(e)| ArenaErr(e))?

    Stdout.line!(
        \\hello from roc, but a very long str that would need to be "heap allocated".
        \\hello from roc, but a very long str that would need to be "heap allocated".
        \\hello from roc, but a very long str that would need to be "heap allocated".
    )?
    Ok({})
}
