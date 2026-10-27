## Internal hosted boundary. Apps use Stdout / Stderr.
Host := [].{
    stdout_line! : Str => Try({}, [StdoutErr(Str)])
    stderr_line! : Str => Try({}, [StderrErr(Str)])
}
