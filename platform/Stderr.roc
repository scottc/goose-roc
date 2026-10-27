import Host

Stderr := [].{
    line! : Str => Try({}, [StderrErr(Str)])
    line! = |message|
        match Host.stderr_line!(message) {
            Ok({}) => Ok({})
            Err(StderrErr(e)) => Err(StderrErr(e))
        }
}
