import Host

Stdout := [].{
    line! : Str => Try({}, [StdoutErr(Str)])
    line! = |msg| Host.stdout_line!(msg)

    ## Optional: raw bytes, no trailing newline policy in host
    bytes! : List(U8) => Try({}, [StdoutErr(Str)])
    bytes! = |b| Host.stdout_bytes!(b)
}
