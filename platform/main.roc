platform "goose"
    requires {} { main! : List(Str) => Try({}, [Exit(I32), ..]) }
    exposes [Audio, Bump, Gfx, Math, Os, Physics, Stderr, Stdout, Ui]
    packages { }
    provides { "roc_main": main_for_host! }
    hosted {
        "roc_bump_set_limit_bytes": Host.bump_set_limit_bytes!,
        "roc_bump_used_bytes": Host.bump_used_bytes!,
        "roc_bump_limit_bytes": Host.bump_limit_bytes!,

        "roc_stdout_line": Host.stdout_line!,
        "roc_stderr_line": Host.stderr_line!,
        "roc_stdout_bytes": Host.stdout_bytes!,
        "roc_stderr_bytes": Host.stderr_bytes!,

        "roc_math_sin": Host.math_sin!,
        "roc_math_cos": Host.math_cos!,
        "roc_math_tan": Host.math_tan!,
        "roc_math_asin": Host.math_asin!,
        "roc_math_acos": Host.math_acos!,
        "roc_math_atan": Host.math_atan!,
        "roc_math_atan2": Host.math_atan2!,
        "roc_math_sqrt": Host.math_sqrt!,
        "roc_math_pow": Host.math_pow!,
        "roc_math_exp": Host.math_exp!,
        "roc_math_log": Host.math_log!,
        "roc_math_floor": Host.math_floor!,
        "roc_math_ceil": Host.math_ceil!,
        "roc_math_abs": Host.math_abs!,

        "roc_os_read_file": Host.os_read_file!,
        "roc_os_write_file": Host.os_write_file!,
        "roc_os_append_file": Host.os_append_file!,
        "roc_os_file_exists": Host.os_file_exists!,
        "roc_os_remove_file": Host.os_remove_file!,
        "roc_os_list_dir": Host.os_list_dir!,
        "roc_os_create_dir": Host.os_create_dir!,
        "roc_os_remove_dir": Host.os_remove_dir!,
        "roc_os_cwd": Host.os_cwd!,
        "roc_os_set_cwd": Host.os_set_cwd!,
        "roc_os_clock_secs": Host.os_clock_secs!,
        "roc_os_monotonic_secs": Host.os_monotonic_secs!,
        "roc_os_sleep_ms": Host.os_sleep_ms!,
        "roc_os_env_get": Host.os_env_get!,
        "roc_os_env_set": Host.os_env_set!,
        "roc_os_env_list": Host.os_env_list!,

        "roc_gfx_init": Host.gfx_init!,
        "roc_gfx_shutdown": Host.gfx_shutdown!,
        "roc_gfx_poll": Host.gfx_poll!,
        "roc_gfx_clear": Host.gfx_clear!,
        "roc_gfx_present": Host.gfx_present!,
        "roc_gfx_window_size": Host.gfx_window_size!,
        "roc_gfx_set_title": Host.gfx_set_title!,
        "roc_gfx_draw_rect": Host.gfx_draw_rect!,

        "roc_audio_init": Host.audio_init!,
        "roc_audio_shutdown": Host.audio_shutdown!,
        "roc_audio_play_tone": Host.audio_play_tone!,
        "roc_audio_stop": Host.audio_stop!,
        "roc_audio_stop_all": Host.audio_stop_all!,
        "roc_audio_set_master_gain": Host.audio_set_master_gain!,

        "roc_phys_world_create": Host.phys_world_create!,
        "roc_phys_world_step": Host.phys_world_step!,
        "roc_phys_world_destroy": Host.phys_world_destroy!,
        "roc_phys_body_create": Host.phys_body_create!,
        "roc_phys_body_destroy": Host.phys_body_destroy!,
        "roc_phys_body_set_transform": Host.phys_body_set_transform!,
        "roc_phys_body_get_transform": Host.phys_body_get_transform!,
        "roc_phys_body_set_velocity": Host.phys_body_set_velocity!,
        "roc_phys_body_get_velocity": Host.phys_body_get_velocity!,

        "roc_ui_frame_begin": Host.ui_frame_begin!,
        "roc_ui_frame_end": Host.ui_frame_end!,
        "roc_ui_text": Host.ui_text!,
        "roc_ui_button": Host.ui_button!,
        "roc_ui_checkbox": Host.ui_checkbox!,
        "roc_ui_slider": Host.ui_slider!,
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

import Audio
import Bump
import Gfx
import Host
import Math
import Os
import Physics
import Stderr
import Stdout
import Ui

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
