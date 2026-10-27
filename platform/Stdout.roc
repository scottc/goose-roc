import Host

Stdout := [].{
    line! : Str => Try({}, [StdoutErr(Str)])
    line! = |message|
        match Host.stdout_line!(message) {
            Ok({}) => Ok({})
            Err(StdoutErr(e)) => Err(StdoutErr(e))
        }
}
