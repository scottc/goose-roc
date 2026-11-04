import Host

Audio := {}.
{
    init! : {} => Try({}, [AudioErr(Str)])
    init! = |_| Host.audio_init!({})

    shutdown! : {} => Try({}, [AudioErr(Str)])
    shutdown! = |_| Host.audio_shutdown!({})

    play_tone! : F32, F32, F32 => Try(U64, [AudioErr(Str)])
    play_tone! = |hz, sec, gain| Host.audio_play_tone!(hz, sec, gain)

    stop! : U64 => Try({}, [AudioErr(Str)])
    stop! = |voice| Host.audio_stop!(voice)

    stop_all! : {} => Try({}, [AudioErr(Str)])
    stop_all! = |_| Host.audio_stop_all!({})

    set_master_gain! : F32 => Try({}, [AudioErr(Str)])
    set_master_gain! = |g| Host.audio_set_master_gain!(g)
}
