## Internal hosted boundary. Apps use Stdout / Stderr.
Host := [].{
    stdout_line! : Str => Try({}, [StdoutErr(Str)])
    stderr_line! : Str => Try({}, [StderrErr(Str)])

    ## Soft bump-arena budget in bytes (goose-pure). No-op on c-bridge where malloc exists.
    configure_arena! : U64 => Try({}, [ArenaErr(Str)])
}
