import Host

Os := {}.
{
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

    create_dir! : Str => Try({}, [OsErr(Str)])
    create_dir! = |path| Host.os_create_dir!(path)

    remove_dir! : Str => Try({}, [OsErr(Str)])
    remove_dir! = |path| Host.os_remove_dir!(path)

    cwd! : {} => Try(Str, [OsErr(Str)])
    cwd! = |_| Host.os_cwd!({})

    set_cwd! : Str => Try({}, [OsErr(Str)])
    set_cwd! = |path| Host.os_set_cwd!(path)

    clock_secs! : {} => Try(F64, [OsErr(Str)])
    clock_secs! = |_| Host.os_clock_secs!({})

    monotonic_secs! : {} => Try(F64, [OsErr(Str)])
    monotonic_secs! = |_| Host.os_monotonic_secs!({})

    sleep_ms! : U64 => Try({}, [OsErr(Str)])
    sleep_ms! = |ms| Host.os_sleep_ms!(ms)

    env_get! : Str => Try(Str, [OsErr(Str)])
    env_get! = |key| Host.os_env_get!(key)

    env_set! : Str, Str => Try({}, [OsErr(Str)])
    env_set! = |key, val| Host.os_env_set!(key, val)

    env_list! : {} => Try(List({ key: Str, value: Str }), [OsErr(Str)])
    env_list! = |_| Host.os_env_list!({})
}
