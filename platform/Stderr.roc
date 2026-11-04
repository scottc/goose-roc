import Host

Stderr := [].{
    line! : Str => Try({}, [StderrErr(Str)])
    line! = |msg| Host.stderr_line!(msg)

    bytes! : List(U8) => Try({}, [StderrErr(Str)])
    bytes! = |b| Host.stderr_bytes!(b)
}
