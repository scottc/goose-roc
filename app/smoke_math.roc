# app/smoke_os_math.roc
app [main!] { pf: platform "../platform/main.roc" }

import pf.Stdout
import pf.Math

main! = |_args| {
    s = Math.sin!(0.0)?
    Stdout.line!("sin0=${s.to_str()}")?
    # Os.read_file! only after Str/List bridge works
    Ok({})
}
