fn impl_roc_gfx_init(title: RocStr, w: i32, h: i32) -> HostGfxInitResult {
    abort("impl_roc_gfx_init: not implemented");
}

fn impl_roc_gfx_shutdown(win: u64) -> HostGfxShutdownResult {
    abort("impl_roc_gfx_shutdown: not implemented");
}

fn impl_roc_gfx_poll(win: u64) -> HostGfxPollResult {
    abort("impl_roc_gfx_poll: not implemented");
}

fn impl_roc_gfx_clear(win: u64, r: f32, g: f32, b: f32, a: f32) -> HostGfxShutdownResult {
    abort("impl_roc_gfx_clear: not implemented");
}

fn impl_roc_gfx_present(win: u64) -> HostGfxShutdownResult {
    abort("impl_roc_gfx_present: not implemented");
}

fn impl_roc_gfx_window_size(win: u64) -> HostGfxWindowSizeResult {
    abort("impl_roc_gfx_window_size: not implemented");
}

fn impl_roc_gfx_set_title(arg0: u64, arg1: RocStr) -> HostGfxShutdownResult {
    abort("impl_roc_gfx_set_title");
}

fn impl_roc_gfx_draw_rect(arg0: u64, arg1: f32, arg2: f32, arg3: f32, arg4: f32, arg5: f32, arg6: f32, arg7: f32, arg8: f32) -> HostGfxShutdownResult {
    abort("impl_roc_gfx_draw_rect");
}
