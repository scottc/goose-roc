## Hosted effects + ABI types (implemented in Goose).
Host :: [].{
    GfxEvent : [
        Quit,
        KeyDown(Str),
        KeyUp(Str),
        MouseMove(F32, F32),
        MouseDown(I32),
        MouseUp(I32),
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

    # Bump
    bump_set_limit_bytes! : U64 => Try({}, [BumpErr(Str)])
    bump_used_bytes! : {} => Try(U64, [BumpErr(Str)])
    bump_limit_bytes! : {} => Try(U64, [BumpErr(Str)])

    # Stdout / Stderr
    stdout_line! : Str => Try({}, [StdoutErr(Str)])
    stderr_line! : Str => Try({}, [StderrErr(Str)])
    stdout_bytes! : List(U8) => Try({}, [StdoutErr(Str)])
    stderr_bytes! : List(U8) => Try({}, [StderrErr(Str)])

    # Math
    math_sin! : F64 => Try(F64, [MathErr(Str)])
    math_cos! : F64 => Try(F64, [MathErr(Str)])
    math_tan! : F64 => Try(F64, [MathErr(Str)])
    math_asin! : F64 => Try(F64, [MathErr(Str)])
    math_acos! : F64 => Try(F64, [MathErr(Str)])
    math_atan! : F64 => Try(F64, [MathErr(Str)])
    math_atan2! : F64, F64 => Try(F64, [MathErr(Str)])
    math_sqrt! : F64 => Try(F64, [MathErr(Str)])
    math_pow! : F64, F64 => Try(F64, [MathErr(Str)])
    math_exp! : F64 => Try(F64, [MathErr(Str)])
    math_log! : F64 => Try(F64, [MathErr(Str)])
    math_floor! : F64 => Try(F64, [MathErr(Str)])
    math_ceil! : F64 => Try(F64, [MathErr(Str)])
    math_abs! : F64 => Try(F64, [MathErr(Str)])

    # Os
    os_read_file! : Str => Try(List(U8), [OsErr(Str)])
    os_write_file! : Str, List(U8) => Try({}, [OsErr(Str)])
    os_append_file! : Str, List(U8) => Try({}, [OsErr(Str)])
    os_file_exists! : Str => Try(Bool, [OsErr(Str)])
    os_remove_file! : Str => Try({}, [OsErr(Str)])
    os_list_dir! : Str => Try(List(Str), [OsErr(Str)])
    os_create_dir! : Str => Try({}, [OsErr(Str)])
    os_remove_dir! : Str => Try({}, [OsErr(Str)])
    os_cwd! : {} => Try(Str, [OsErr(Str)])
    os_set_cwd! : Str => Try({}, [OsErr(Str)])
    os_clock_secs! : {} => Try(F64, [OsErr(Str)])
    os_monotonic_secs! : {} => Try(F64, [OsErr(Str)])
    os_sleep_ms! : U64 => Try({}, [OsErr(Str)])
    os_env_get! : Str => Try(Str, [OsErr(Str)])
    os_env_set! : Str, Str => Try({}, [OsErr(Str)])
    os_env_list! : {} => Try(List({ key: Str, value: Str }), [OsErr(Str)])

    # Gfx
    gfx_init! : Str, I32, I32 => Try(U64, [GfxErr(Str)])
    gfx_shutdown! : U64 => Try({}, [GfxErr(Str)])
    gfx_poll! : U64 => Try(GfxEvent, [GfxErr(Str)])
    gfx_clear! : U64, F32, F32, F32, F32 => Try({}, [GfxErr(Str)])
    gfx_present! : U64 => Try({}, [GfxErr(Str)])
    gfx_window_size! : U64 => Try({ width: I32, height: I32 }, [GfxErr(Str)])
    gfx_set_title! : U64, Str => Try({}, [GfxErr(Str)])
    gfx_draw_rect! : U64, F32, F32, F32, F32, F32, F32, F32, F32 => Try({}, [GfxErr(Str)])

    # Audio
    audio_init! : {} => Try({}, [AudioErr(Str)])
    audio_shutdown! : {} => Try({}, [AudioErr(Str)])
    audio_play_tone! : F32, F32, F32 => Try(U64, [AudioErr(Str)])
    audio_stop! : U64 => Try({}, [AudioErr(Str)])
    audio_stop_all! : {} => Try({}, [AudioErr(Str)])
    audio_set_master_gain! : F32 => Try({}, [AudioErr(Str)])

    # Physics
    phys_world_create! : F32, F32 => Try(U64, [PhysErr(Str)])
    phys_world_step! : U64, F32 => Try({}, [PhysErr(Str)])
    phys_world_destroy! : U64 => Try({}, [PhysErr(Str)])
    phys_body_create! : U64, BodyDef => Try(U64, [PhysErr(Str)])
    phys_body_destroy! : U64 => Try({}, [PhysErr(Str)])
    phys_body_set_transform! : U64, F32, F32, F32 => Try({}, [PhysErr(Str)])
    phys_body_get_transform! : U64 => Try({ x: F32, y: F32, angle: F32 }, [PhysErr(Str)])
    phys_body_set_velocity! : U64, F32, F32, F32 => Try({}, [PhysErr(Str)])
    phys_body_get_velocity! : U64 => Try({ vx: F32, vy: F32, omega: F32 }, [PhysErr(Str)])

    # Ui
    ui_frame_begin! : U64 => Try({}, [UiErr(Str)])
    ui_frame_end! : U64 => Try({}, [UiErr(Str)])
    ui_text! : Str, F32, F32 => Try({}, [UiErr(Str)])
    ui_button! : Str, F32, F32, F32, F32 => Try(Bool, [UiErr(Str)])
    ui_checkbox! : Str, F32, F32, Bool => Try(Bool, [UiErr(Str)])
    ui_slider! : Str, F32, F32, F32, F32, F32 => Try(F32, [UiErr(Str)])
}
