module [
    read_file!,
    write_file!,
    append_file!,
    file_exists!,
    remove_file!,
    list_dir!,
    clock_secs!,
    sleep_ms!,
    env_get!,
    read_utf8!,
    write_utf8!,
]

import Host

## Raw bytes (preferred boundary).
read_file! : Str => Try(List(U8), [OsErr(Str)])
read_file! = |path| Host.os_read_file!(path)

write_file! : Str, List(U8) => Try({}, [OsErr(Str)])
write_file! = |path, bytes| Host.os_write_file!(path, bytes)

append_file! : Str, List(U8) => Try({}, [OsErr(Str)])
append_file! = |path, bytes| Host.os_append_file!(path, bytes)

file_exists! : Str => Try(Bool, [OsErr(Str)])
file_exists! = |path| Host.os_file_exists!(path)

remove_file! : Str => Try({}, [OsErr(Str)])
remove_file! = |path| Host.os_remove_file!(path)

list_dir! : Str => Try(List(Str), [OsErr(Str)])
list_dir! = |path| Host.os_list_dir!(path)

clock_secs! : {} => Try(F64, [OsErr(Str)])
clock_secs! = |_| Host.os_clock_secs!({})

sleep_ms! : U64 => Try({}, [OsErr(Str)])
sleep_ms! = |ms| Host.os_sleep_ms!(ms)

env_get! : Str => Try(Str, [OsErr(Str)])
env_get! = |key| Host.os_env_get!(key)

## Convenience: UTF-8 files via Roc Str (host still talks bytes).
read_utf8! : Str => Try(Str, [OsErr(Str)])
read_utf8! = |path| {
    bytes = read_file!(path)?
    # Platform helper or app-level decode; if you lack Str.from_utf8, keep bytes-only in v1.
    Ok(Str.from_utf8(bytes) ? |e| OsErr("utf8: ${Inspect.to_str(e)}"))
}

write_utf8! : Str, Str => Try({}, [OsErr(Str)])
write_utf8! = |path, text| write_file!(path, Str.to_utf8(text))
