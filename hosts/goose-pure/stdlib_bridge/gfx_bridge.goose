// hosts/goose-pure/stdlib_bridge/gfx_bridge.goose
import gfx;

var gfx_open = false;
var gfx_w: i32 = 640;
var gfx_h: i32 = 400;
var in_pass = false;
var frame_live = false;

var fb: u8[>..] = [];
var fb_w: i32 = 0;
var fb_h: i32 = 0;

// Last clear (used when begin_screen must match Roc clear!)
var clear_r: f32 = 0.0;
var clear_g: f32 = 0.0;
var clear_b: f32 = 0.0;
var clear_a: f32 = 1.0;

// One screen-sized texture for FB blit (id 0 = none)
var screen_tex: u32 = 0;
var screen_tex_w: i32 = 0;
var screen_tex_h: i32 = 0;

extern fn c_tex_upload(id: u32, pixels: u64, nbytes: i64) -> bool = "gs_gfx_texture_upload_rgba";
extern fn c_tex_create(w: i32, h: i32) -> u32 = "gs_gfx_create_texture";
extern fn c_tex_release(id: u32) = "gs_gfx_release_texture";
extern fn addr_of_u8(p: u8&) -> u64 = "gs_addr_of_u8";

fn clamp_byte(x: f32) -> u8 {
    if x <= 0.0 { return 0; }
    if x >= 255.0 { return 255; }
    x as u8
}

fn fb_resize(w_in: i32, h_in: i32) {
    var w = w_in;
    var h = h_in;
    if w < 1 { w = 1; }
    if h < 1 { h = 1; }
    fb_w = w;
    fb_h = h;
    fb.resize((w * h * 4) as i64, 0);
    // Drop stale GPU texture; recreated on present
    if screen_tex != 0 {
        c_tex_release(screen_tex);
        screen_tex = 0;
        screen_tex_w = 0;
        screen_tex_h = 0;
    }
}

fn fb_clear(r: f32, g: f32, b: f32, a: f32) {
    clear_r = r;
    clear_g = g;
    clear_b = b;
    clear_a = a;
    let R = clamp_byte(r * 255.0);
    let G = clamp_byte(g * 255.0);
    let B = clamp_byte(b * 255.0);
    let A = clamp_byte(a * 255.0);
    var i: i64 = 0;
    let n = fb.len;
    while i + 3 < n {
        fb[i] = R;
        fb[i + 1] = G;
        fb[i + 2] = B;
        fb[i + 3] = A;
        i += 4;
    }
}

fn fb_fill_rect(x: f32, y: f32, rw: f32, rh: f32, r: f32, g: f32, b: f32, a: f32) {
    if fb_w <= 0 || fb_h <= 0 { return; }
    var x0 = x as i64;
    var y0 = y as i64;
    var x1 = (x + rw) as i64;
    var y1 = (y + rh) as i64;
    if x0 < 0 { x0 = 0; }
    if y0 < 0 { y0 = 0; }
    if x1 > fb_w { x1 = fb_w; }
    if y1 > fb_h { y1 = fb_h; }
    if x1 <= x0 || y1 <= y0 { return; }
    let R = clamp_byte(r * 255.0);
    let G = clamp_byte(g * 255.0);
    let B = clamp_byte(b * 255.0);
    let A = clamp_byte(a * 255.0);
    var py = y0;
    while py < y1 {
        var px = x0;
        while px < x1 {
            let at = (py * fb_w + px) * 4;
            fb[at] = R;
            fb[at + 1] = G;
            fb[at + 2] = B;
            fb[at + 3] = A;
            px += 1;
        }
        py += 1;
    }
}

fn ensure_frame() -> bool {
    if !gfx_open { return false; }
    if frame_live { return true; }
    if !gfx::frame() { return false; }
    frame_live = true;
    true
}

fn end_pass_if_needed() {
    if in_pass {
        gfx::end_pass();
        in_pass = false;
    }
}

fn ensure_screen_tex() -> bool {
    if screen_tex != 0 && screen_tex_w == fb_w && screen_tex_h == fb_h {
        return true;
    }
    if screen_tex != 0 {
        c_tex_release(screen_tex);
        screen_tex = 0;
    }
    let id = c_tex_create(fb_w, fb_h);
    if id == 0 { return false; }
    screen_tex = id;
    screen_tex_w = fb_w;
    screen_tex_h = fb_h;
    true
}

fn upload_fb() -> bool {
    if fb.len == 0 { return false; }
    if !ensure_screen_tex() { return false; }
    // Contiguous growable buffer: address of first byte
    let p = addr_of_u8(fb[0]);
    c_tex_upload(screen_tex, p, fb.len)
}

// ---- packers (same as before; keep yours if identical) ----

fn unit_ok() -> HostGfxShutdownResult {
    HostGfxShutdownResult {
        p0: 0, p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn unit_err(msg: const u8[:]) -> HostGfxShutdownResult {
    let s = bytes_to_rocstr(msg);
    HostGfxShutdownResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn init_ok(handle: u64) -> HostGfxInitResult {
    HostGfxInitResult {
        p0: handle, p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn init_err(msg: const u8[:]) -> HostGfxInitResult {
    let s = bytes_to_rocstr(msg);
    HostGfxInitResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn frame_bool_ok(v: bool) -> HostGfxFrameResult {
    HostGfxFrameResult {
        p0: if v { 1 } else { 0 }, p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn frame_bool_err(msg: const u8[:]) -> HostGfxFrameResult {
    let s = bytes_to_rocstr(msg);
    HostGfxFrameResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn poll_ok_none() -> HostGfxPollResult {
    HostGfxPollResult {
        p0: 0, p1: 0, p2: 0, p3: 5, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn poll_err(msg: const u8[:]) -> HostGfxPollResult {
    let s = bytes_to_rocstr(msg);
    HostGfxPollResult {
        p0: s.bytes, p1: s.cap, p2: s.len, p3: 0, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn window_size_ok(w: i32, h: i32) -> HostGfxWindowSizeResult {
    let bits = (h as u64) & 0xffffffff | (((w as u64) & 0xffffffff) << 32);
    HostGfxWindowSizeResult {
        p0: bits, p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn window_size_err(msg: const u8[:]) -> HostGfxWindowSizeResult {
    let s = bytes_to_rocstr(msg);
    HostGfxWindowSizeResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn mouse_pos_ok(x: f32, y: f32) -> HostGfxMousePosResult {
    let xb = f32_bits(x) as u64;
    let yb = f32_bits(y) as u64;
    HostGfxMousePosResult {
        p0: (xb & 0xffffffff) | (yb << 32), p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn mouse_pos_err(msg: const u8[:]) -> HostGfxMousePosResult {
    let s = bytes_to_rocstr(msg);
    HostGfxMousePosResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn mouse_delta_ok(dx: f32, dy: f32) -> HostGfxMouseDeltaResult {
    let xb = f32_bits(dx) as u64;
    let yb = f32_bits(dy) as u64;
    HostGfxMouseDeltaResult {
        p0: (xb & 0xffffffff) | (yb << 32), p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn mouse_delta_err(msg: const u8[:]) -> HostGfxMouseDeltaResult {
    let s = bytes_to_rocstr(msg);
    HostGfxMouseDeltaResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn delta_time_ok(v: f64) -> HostGfxDeltaTimeResult {
    HostGfxDeltaTimeResult {
        p0: f64_bits(v), p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn delta_time_err(msg: const u8[:]) -> HostGfxDeltaTimeResult {
    let s = bytes_to_rocstr(msg);
    HostGfxDeltaTimeResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

// ---- impls ----

fn impl_roc_gfx_init(title: RocStr, w: i32, h: i32) -> HostGfxInitResult {
    if gfx_open { return init_err("gfx already open"); }
    let t = rocstr_to_bytes(title);
    if !gfx::open(t, w, h) {
        return init_err("gfx::open failed");
    }
    gfx_open = true;
    gfx_w = w;
    gfx_h = h;
    in_pass = false;
    frame_live = false;
    screen_tex = 0;
    fb_resize(w, h);
    init_ok(1)
}

fn impl_roc_gfx_shutdown(win: u64) -> HostGfxShutdownResult {
    let _ = win;
    if !gfx_open { return unit_ok(); }
    end_pass_if_needed();
    if screen_tex != 0 {
        c_tex_release(screen_tex);
        screen_tex = 0;
    }
    gfx::close();
    gfx_open = false;
    frame_live = false;
    fb.resize(0, 0);
    unit_ok()
}

fn impl_roc_gfx_frame(win: u64) -> HostGfxFrameResult {
    let _ = win;
    if !gfx_open { return frame_bool_err("gfx not open"); }
    frame_live = false;
    if !gfx::frame() { return frame_bool_ok(false); }
    frame_live = true;
    frame_bool_ok(true)
}

fn impl_roc_gfx_poll(win: u64) -> HostGfxPollResult {
    let _ = win;
    if !gfx_open { return poll_err("gfx not open"); }
    poll_ok_none()
}

fn impl_roc_gfx_clear(win: u64, r: f32, g: f32, b: f32, a: f32) -> HostGfxShutdownResult {
    let _ = win;
    if !gfx_open { return unit_err("gfx not open"); }
    if !ensure_frame() { return unit_err("gfx::frame failed"); }
    fb_clear(r, g, b, a);
    unit_ok()
}

fn impl_roc_gfx_draw_rect(
    win: u64, x: f32, y: f32, w: f32, h: f32,
    r: f32, g: f32, b: f32, a: f32,
) -> HostGfxShutdownResult {
    let _ = win;
    if !gfx_open { return unit_err("gfx not open"); }
    if !ensure_frame() { return unit_err("gfx::frame failed"); }
    fb_fill_rect(x, y, w, h, r, g, b, a);
    unit_ok()
}

fn impl_roc_gfx_present(win: u64) -> HostGfxShutdownResult {
    let _ = win;
    if !gfx_open { return unit_err("gfx not open"); }
    if !ensure_frame() { return unit_err("gfx::frame failed"); }

    end_pass_if_needed();

    // 1) Always clear GPU to last Roc clear (sky/floor visible even if upload fails)
    if !gfx::begin_screen(float4 { clear_r, clear_g, clear_b, clear_a }) {
        frame_live = false;
        return unit_err("begin_screen failed");
    }
    in_pass = true;

    // 2) Upload software FB (walls/rects). Requires polyfills in gs_ffi_polyfill.c
    let _ = upload_fb();
    // Optional: if you have a fullscreen textured draw in goose_gfx, call it here
    // with screen_tex covering the viewport. Without it, begin_screen still shows clear_*.

    gfx::end_pass();
    in_pass = false;
    frame_live = false;
    unit_ok()
}

fn impl_roc_gfx_window_size(win: u64) -> HostGfxWindowSizeResult {
    let _ = win;
    if !gfx_open { return window_size_err("gfx not open"); }
    window_size_ok(gfx_w, gfx_h)
}

fn impl_roc_gfx_set_title(win: u64, title: RocStr) -> HostGfxShutdownResult {
    let _ = win;
    let _ = title;
    if !gfx_open { return unit_err("gfx not open"); }
    unit_ok()
}

fn impl_roc_gfx_key_down(win: u64, name: RocStr) -> HostGfxFrameResult {
    let _ = win;
    if !gfx_open { return frame_bool_err("gfx not open"); }
    let k = rocstr_to_bytes(name);
    frame_bool_ok(gfx::key_down(k))
}

fn impl_roc_gfx_key_pressed(win: u64, name: RocStr) -> HostGfxFrameResult {
    let _ = win;
    if !gfx_open { return frame_bool_err("gfx not open"); }
    let k = rocstr_to_bytes(name);
    frame_bool_ok(gfx::key_pressed(k))
}

fn impl_roc_gfx_mouse_delta(win: u64) -> HostGfxMouseDeltaResult {
    let _ = win;
    if !gfx_open { return mouse_delta_err("gfx not open"); }
    mouse_delta_ok(0.0, 0.0)
}

fn impl_roc_gfx_mouse_pos(win: u64) -> HostGfxMousePosResult {
    let _ = win;
    if !gfx_open { return mouse_pos_err("gfx not open"); }
    mouse_pos_ok(0.0, 0.0)
}

fn impl_roc_gfx_mouse_down(win: u64, button: i32) -> HostGfxFrameResult {
    let _ = win;
    let _ = button;
    if !gfx_open { return frame_bool_err("gfx not open"); }
    frame_bool_ok(false)
}

fn impl_roc_gfx_set_mouse_relative(win: u64, on: bool) -> HostGfxShutdownResult {
    let _ = win;
    let _ = on;
    if !gfx_open { return unit_err("gfx not open"); }
    unit_ok()
}

fn impl_roc_gfx_set_cursor_visible(win: u64, on: bool) -> HostGfxShutdownResult {
    let _ = win;
    let _ = on;
    if !gfx_open { return unit_err("gfx not open"); }
    unit_ok()
}

fn impl_roc_gfx_delta_time(win: u64) -> HostGfxDeltaTimeResult {
    let _ = win;
    if !gfx_open { return delta_time_err("gfx not open"); }
    delta_time_ok(1.0 / 60.0)
}

fn impl_roc_gfx_texture_create(w: i32, h: i32) -> HostGfxInitResult {
    if !gfx_open { return init_err("gfx not open"); }
    let id = c_tex_create(w, h);
    if id == 0 { return init_err("texture create failed"); }
    init_ok(id as u64)
}

fn impl_roc_gfx_texture_destroy(tex: u64) -> HostGfxShutdownResult {
    if tex != 0 { c_tex_release(tex as u32); }
    unit_ok()
}

fn impl_roc_gfx_texture_upload_rgba(tex: u64, rgba: RocList) -> HostGfxShutdownResult {
    if tex == 0 { return unit_err("bad texture"); }
    let n = rgba.length as i64;
    if n <= 0 || rgba.bytes == 0 { return unit_err("empty rgba"); }
    if !c_tex_upload(tex as u32, rgba.bytes, n) {
        return unit_err("upload failed");
    }
    unit_ok()
}

fn impl_roc_gfx_draw_textured_quad(
    win: u64, x: f32, y: f32, qw: f32, qh: f32,
    tex: u64, u0: f32, v0: f32, u1: f32, v1: f32,
) -> HostGfxShutdownResult {
    let _ = win; let _ = x; let _ = y; let _ = qw; let _ = qh;
    let _ = tex; let _ = u0; let _ = v0; let _ = u1; let _ = v1;
    unit_ok()
}
