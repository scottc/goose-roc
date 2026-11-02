## Hosted effects + ABI types (implemented in Goose).
Host :: [].{
    GfxEvent : [
        Quit,
        KeyDown(Str),
        KeyUp(Str),
        Resize(I32, I32),
        None,
    ]

    BodyDef : {
        mass : F32,
        x : F32,
        y : F32,
        angle : F32,
        dynamic : Bool,
    }

    stdout_line! : Str => Try({}, [StdoutErr(Str)])
    stderr_line! : Str => Try({}, [StderrErr(Str)])
    configure_arena! : U64 => Try({}, [ArenaErr(Str)])

    math_sin! : F64 => Try(F64, [MathErr(Str)])
    math_cos! : F64 => Try(F64, [MathErr(Str)])
    math_sqrt! : F64 => Try(F64, [MathErr(Str)])

    os_read_file! : Str => Try(List(U8), [OsErr(Str)])
    os_write_file! : Str, List(U8) => Try({}, [OsErr(Str)])
    os_append_file! : Str, List(U8) => Try({}, [OsErr(Str)])
    os_file_exists! : Str => Try(Bool, [OsErr(Str)])
    os_remove_file! : Str => Try({}, [OsErr(Str)])
    os_list_dir! : Str => Try(List(Str), [OsErr(Str)])
    os_clock_secs! : {} => Try(F64, [OsErr(Str)])
    os_sleep_ms! : U64 => Try({}, [OsErr(Str)])
    os_env_get! : Str => Try(Str, [OsErr(Str)])

    gfx_init! : Str, I32, I32 => Try(U64, [GfxErr(Str)])
    gfx_shutdown! : U64 => Try({}, [GfxErr(Str)])
    gfx_poll! : U64 => Try(GfxEvent, [GfxErr(Str)])
    gfx_clear! : U64, F32, F32, F32, F32 => Try({}, [GfxErr(Str)])
    gfx_present! : U64 => Try({}, [GfxErr(Str)])
    gfx_window_size! : U64 => Try({ width: I32, height: I32 }, [GfxErr(Str)])

    audio_init! : {} => Try({}, [AudioErr(Str)])
    audio_shutdown! : {} => Try({}, [AudioErr(Str)])
    audio_play_tone! : F32, F32, F32 => Try(U64, [AudioErr(Str)])
    audio_stop_all! : {} => Try({}, [AudioErr(Str)])

    phys_world_create! : F32, F32 => Try(U64, [PhysErr(Str)])
    phys_world_step! : U64, F32 => Try({}, [PhysErr(Str)])
    phys_world_destroy! : U64 => Try({}, [PhysErr(Str)])
    phys_body_create! : U64, BodyDef => Try(U64, [PhysErr(Str)])
    phys_body_set_transform! : U64, F32, F32, F32 => Try({}, [PhysErr(Str)])
    phys_body_get_transform! : U64 => Try({ x: F32, y: F32, angle: F32 }, [PhysErr(Str)])

    ui_frame_begin! : U64 => Try({}, [UiErr(Str)])
    ui_frame_end! : U64 => Try({}, [UiErr(Str)])
    ui_text! : Str, F32, F32 => Try({}, [UiErr(Str)])
    ui_button! : Str, F32, F32, F32, F32 => Try(Bool, [UiErr(Str)])
}
