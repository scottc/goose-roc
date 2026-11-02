platform "goose"
    requires {} { main! : List(Str) => Try({}, [Exit(I32), ..]) }
    exposes [Arena, Stdout, Stderr]
    packages { }
    provides { "roc_main": main_for_host! }
    hosted {
        "roc_stdout_line": Host.stdout_line!,
        "roc_stderr_line": Host.stderr_line!,
        "roc_configure_arena": Host.configure_arena!,

        "roc_math_sin": Host.math_sin!,
        "roc_math_cos": Host.math_cos!,
        "roc_math_sqrt": Host.math_sqrt!,

        "roc_os_read_file": Host.os_read_file!,
        "roc_os_write_file": Host.os_write_file!,
        "roc_os_append_file": Host.os_append_file!,
        "roc_os_file_exists": Host.os_file_exists!,
        "roc_os_remove_file": Host.os_remove_file!,
        "roc_os_list_dir": Host.os_list_dir!,
        "roc_os_clock_secs": Host.os_clock_secs!,
        "roc_os_sleep_ms": Host.os_sleep_ms!,
        "roc_os_env_get": Host.os_env_get!,

        "roc_gfx_init": Host.gfx_init!,
        "roc_gfx_shutdown": Host.gfx_shutdown!,
        "roc_gfx_poll": Host.gfx_poll!,
        "roc_gfx_clear": Host.gfx_clear!,
        "roc_gfx_present": Host.gfx_present!,
        "roc_gfx_window_size": Host.gfx_window_size!,

        "roc_audio_init": Host.audio_init!,
        "roc_audio_shutdown": Host.audio_shutdown!,
        "roc_audio_play_tone": Host.audio_play_tone!,
        "roc_audio_stop_all": Host.audio_stop_all!,

        "roc_phys_world_create": Host.phys_world_create!,
        "roc_phys_world_step": Host.phys_world_step!,
        "roc_phys_world_destroy": Host.phys_world_destroy!,
        "roc_phys_body_create": Host.phys_body_create!,
        "roc_phys_body_set_transform": Host.phys_body_set_transform!,
        "roc_phys_body_get_transform": Host.phys_body_get_transform!,

        "roc_ui_frame_begin": Host.ui_frame_begin!,
        "roc_ui_frame_end": Host.ui_frame_end!,
        "roc_ui_text": Host.ui_text!,
        "roc_ui_button": Host.ui_button!,
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

import Host
import Arena
import Stdout
import Stderr

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
