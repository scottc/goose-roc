platform "goose"
    requires {} { main! : List(Str) => Try({}, [Exit(I32), ..]) }
    exposes [Stdout, Stderr]
    packages { roc: "nightly-2026-10-21-5349569" }
    provides { "roc_main": main_for_host! }
    hosted {
        "roc_stdout_line": Host.stdout_line!,
        "roc_stderr_line": Host.stderr_line!,
    }
    targets: {
        inputs_dir: "targets-out/",
        x64musl: {
            inputs: [
                "crt1.o",
                "libhost.a",
                app,
                "libc.a",
                "libzigc.a",
                "libcompiler_rt.a",
            ],
        },
    }

import Stdout
import Stderr
import Host

main_for_host! : List(Str) => I32
main_for_host! = |args| {
    match main!(args) {
        Ok({}) => 0
        Err(Exit(code)) => code
        Err(other) => {
            _ = Stderr.line!("ERROR: ${Str.inspect(other)}")
            1
        }
    }
}
