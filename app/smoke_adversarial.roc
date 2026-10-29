app [main!] {
    pf: platform "../platform/main.roc",
    roc: "nightly-2026-10-21-5349569",
}

import pf.Arena
import pf.Stdout
import pf.Stderr

## Adversarial smoke for pure-Goose vs c-bridge hosts.
## Each section is a design probe: pure host should either succeed or abort
## with a clear message (then file DESIGN_EDGES.md / upstream issue).

main! = |_args| {
    Arena.configure!(64 * 1024 * 1024)
        .map_err(|ArenaErr(e)| ArenaErr(e))?
    Stdout.line!("ok")?
    Ok({})
}

# main! : List(Str) => Try({}, [Exit(I32), ArenaErr(Str), StdoutErr(Str), StderrErr(Str)])
# main! = |_args| {
#     Arena.configure!(64 * 1024 * 1024) # 64MiB
#         .map_err(|ArenaErr(e)| ArenaErr(e))?
#
#     # --- 1. Small string (SSO, no roc_alloc) ---
#     Stdout.line!("smoke: small str ok")?
#
#     # Grow arena at runtime!
#     Arena.configure!(256 * 1024 * 1024) # 256MiB
#         .map_err(|ArenaErr(e)| ArenaErr(e))?
#
#     # --- 2. Empty / borderline small ---
#     Stdout.line!("")?
#     Stdout.line!("xxxxxxxxxxxxxxxxxxxxxxx")? # 23 x — max small on 64-bit if exact
#
#     # --- 3. Long string (heap / roc_alloc) ---
#     Stdout.line!(long_block())?
#
#     # --- 4. List growth (many allocs + RC traffic) ---
#     # list_probe!()?
#
#     # --- 5. Nested / composed strings ---
#     Stdout.line!("prefix-${long_block()}-suffix")?
#
#     # --- 6. Stderr path ---
#     Stderr.line!("smoke: stderr small")?
#
#     Stdout.line!("smoke: reached end (host survived all probes)")?
#     Ok({})
# }
#
# long_block : () -> Str
# long_block = || {
#     # Well over 23 bytes → not SSO
#     "LONG:"
#     |> Str.concat("abcdefghijklmnopqrstuvwxyz")
#     |> Str.concat("0123456789")
#     |> Str.concat("|more than twenty three bytes of payload for heap path|")
#     |> Str.concat("|repeat-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa|")
# }
#
# list_probe! : () => Try({}, [StdoutErr(Str)])
# list_probe! = || {
#     $xs : List(Str)
#     var $xs = []
#     $xs = List.append($xs, "a")
#     $xs = List.append($xs, "b")
#     $xs = List.append($xs, long_block())
#     # walk forces reads; may share / slice / RC
#     List.for_each!($xs, |s| {
#         _ = Stdout.line!("list_item:${s}")
#         {}
#     })
#     # rebuild larger list (optimistic mutation / realloc pressure)
#     $xs = List.concat($xs, $xs)
#     Stdout.line!("list_len=${List.len($xs).to_str()}")?
#     Ok({})
# }
