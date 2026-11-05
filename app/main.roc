app [main!] {
    pf: platform "../platform/main.roc",
}

import pf.Bump
import pf.Stdout

main! : List(Str) => Try({}, [Exit(I32)])
main! = |_args| {
    # Bump.configure!(64 * 1024 * 1024) # 64MiB
    #     .map_err(|ArenaErr(e)| ArenaErr(e))?

    _ = Stdout.line!("hello from roc")

    # # Grow arena at runtime!
    # Bump.configure!(256 * 1024 * 1024) # 256MiB
    #     .map_err(|ArenaErr(e)| ArenaErr(e))?

    # Stdout.line!(
    #     \\hello from roc, but a very long str that would need to be "heap allocated".
    #     \\hello from roc, but a very long str that would need to be "heap allocated".
    #     \\hello from roc, but a very long str that would need to be "heap allocated".
    # )?
    Ok({})
}
