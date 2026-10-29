import Host

Arena := [].{
    configure! : U64 => Try({}, [ArenaErr(Str)])
    configure! = Host.configure_arena!
}
