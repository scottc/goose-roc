module [init!, shutdown!, play_tone!, stop_all!]

import Host

init! : {} => Try({}, [AudioErr(Str)])
init! = |_| Host.audio_init!({})

shutdown! : {} => Try({}, [AudioErr(Str)])
shutdown! = |_| Host.audio_shutdown!({})

## Procedural beep; voice handle for later stop/priority.
play_tone! : F32, F32, F32 => Try(U64, [AudioErr(Str)])
play_tone! = |freq_hz, seconds, gain| Host.audio_play_tone!(freq_hz, seconds, gain)

stop_all! : {} => Try({}, [AudioErr(Str)])
stop_all! = |_| Host.audio_stop_all!({})
