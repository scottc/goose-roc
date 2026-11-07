// Roc ↔ Goose gfx (singleton). Result types = roc_platform_abi_types.goose only.

import gfx;

var gfx_open: bool = false;
var gfx_w: i32 = 0;
var gfx_h: i32 = 0;
var in_pass: bool = false;
var clear_r: f32 = 0.1;
var clear_g: f32 = 0.1;
var clear_b: f32 = 0.12;
var clear_a: f32 = 1.0;

// host_impl / polyfill: addr_of, ffi_bytes, bytes_to_rocstr, bytes_to_roclist,
// rocstr_to_bytes, f32_bits, f64_bits

extern "gs_gfx_texture_upload_rgba" fn c_tex_upload(id: u32, pixels: u64, nbytes: i64) -> bool;

fn gfx_upload_rgba(t: gfx::Texture, pixels: u8[>..]) -> bool {
    if pixels.len == 0 {
        return false;
    }
    let pix = copy(pixels);
    if pix.len == 0 {
        return false;
    }
    let p = addr_of(pix[0]);
    c_tex_upload(t.id, p, pix.len)
}

fn gfx_bytes_to_rocstr(msg: const u8[:]) -> RocStr {
    bytes_to_rocstr(msg)
}

fn gfx_growable_to_rocstr(msg: u8[>..]) -> RocStr {
    bytes_to_roclist_as_str(copy(msg))
}

fn bytes_to_roclist_as_str(buf: u8[>..]) -> RocStr {
    if buf.len == 0 {
        return RocStr { bytes: 0, cap: 0, len: 0 };
    }
    let list = bytes_to_roclist(copy(buf));
    RocStr {
        bytes: list.bytes,
        cap: list.capacity_or_other,
        len: list.length,
    }
}

fn gfx_unit_ok() -> HostGfxShutdownResult {
    HostGfxShutdownResult {
        p0: 0, p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_unit_err(msg: const u8[:]) -> HostGfxShutdownResult {
    let s = gfx_bytes_to_rocstr(msg);
    HostGfxShutdownResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_init_ok(id: u64) -> HostGfxInitResult {
    HostGfxInitResult {
        p0: id, p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

// All Try(Bool, [GfxErr(Str)]) → HostGfxFrameResult (glue dedupe)
fn gfx_bool_ok(v: bool) -> HostGfxFrameResult {
    let bit: u64 = if v { 1 } else { 0 };
    HostGfxFrameResult {
        p0: bit, p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_bool_err(msg: const u8[:]) -> HostGfxFrameResult {
    let s = gfx_bytes_to_rocstr(msg);
    HostGfxFrameResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_mouse_delta_ok(x: f32, y: f32) -> HostGfxMouseDeltaResult {
    HostGfxMouseDeltaResult {
        p0: f32_bits(x), p1: f32_bits(y), p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_mouse_delta_err(msg: const u8[:]) -> HostGfxMouseDeltaResult {
    let s = gfx_bytes_to_rocstr(msg);
    HostGfxMouseDeltaResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_mouse_pos_ok(x: f32, y: f32) -> HostGfxMousePosResult {
    HostGfxMousePosResult {
        p0: f32_bits(x), p1: f32_bits(y), p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_mouse_pos_err(msg: const u8[:]) -> HostGfxMousePosResult {
    let s = gfx_bytes_to_rocstr(msg);
    HostGfxMousePosResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_winsize_ok(w: i32, h: i32) -> HostGfxWindowSizeResult {
    HostGfxWindowSizeResult {
        p0: w as u64, p1: h as u64, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_winsize_err(msg: const u8[:]) -> HostGfxWindowSizeResult {
    let s = gfx_bytes_to_rocstr(msg);
    HostGfxWindowSizeResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_dt_ok(v: f64) -> HostGfxDeltaTimeResult {
    HostGfxDeltaTimeResult {
        p0: f64_bits(v), p1: 0, p2: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_dt_err(msg: const u8[:]) -> HostGfxDeltaTimeResult {
    let s = gfx_bytes_to_rocstr(msg);
    HostGfxDeltaTimeResult {
        p0: s.bytes, p1: s.cap, p2: s.len, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_poll_ok_none() -> HostGfxPollResult {
    HostGfxPollResult {
        p0: 7, p1: 0, p2: 0, p3: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_poll_ok_quit() -> HostGfxPollResult {
    HostGfxPollResult {
        p0: 0, p1: 0, p2: 0, p3: 0, tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn gfx_poll_err(msg: const u8[:]) -> HostGfxPollResult {
    let s = gfx_bytes_to_rocstr(msg);
    HostGfxPollResult {
        p0: s.bytes, p1: s.cap, p2: s.len, p3: 0, tag: 0,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

// Pack a short C-ish message as Roc small-string (64-bit LE).
// Last byte of the 24-byte value holds length with high bit set (same as your is_small_str).
fn rocstr_sso_from_msg(msg: const u8[:]) -> RocStr {
    var n = msg.len;
    if n > 23 {
        n = 23;
    }
    var b0: u64 = 0;
    var b1: u64 = 0;
    var b2: u64 = 0;
    for i in n {
        let byte = msg[i] as u64;
        if i < 8 {
            b0 = b0 | (byte << (i * 8));
        } else if i < 16 {
            b1 = b1 | (byte << ((i - 8) * 8));
        } else {
            b2 = b2 | (byte << ((i - 16) * 8));
        }
    }
    // length in top byte of third word, with 0x80 marker (matches your small_str_len)
    let len_byte = (n as u64) ^ 0x80;
    b2 = (b2 & 0x00ffffffffffffff) | (len_byte << 56);
    RocStr { bytes: b0, cap: b1, len: b2 }
}

fn gfx_init_err(msg: const u8[:]) -> HostGfxInitResult {
    let s = rocstr_sso_from_msg(msg);
    HostGfxInitResult {
        p0: s.bytes,
        p1: s.cap,
        p2: s.len,
        tag: 0, // Err
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn impl_roc_gfx_init(title: RocStr, w: i32, h: i32) -> HostGfxInitResult {
    print("host: gfx_init real 1");
    if gfx_open {
        return gfx_init_err("gfx already open");
    }

    print("host: gfx_init real 2");
    let t = rocstr_to_bytes(title);

    print("host: gfx_init real 3");
    if !gfx::open(t, w, h) {
        // See the real reason without feeding Roc a bad Str
        var err: u8[>..] = gfx::error();
        print("host: gfx open failed:");
        print(err);
        // Short fixed SSO only — not gfx_growable_to_rocstr
        return gfx_init_err("gfx open failed");
    }

    print("host: gfx_init real 4");
    gfx_open = true;
    gfx_w = w;
    gfx_h = h;
    in_pass = false;
    print("host: gfx_init real 5");
    gfx_init_ok(1)
}

fn impl_roc_gfx_shutdown(win: u64) -> HostGfxShutdownResult {
    if gfx_open {
        if in_pass {
            gfx::end_pass();
            in_pass = false;
        }
        gfx::close();
        gfx_open = false;
    }
    gfx_unit_ok()
}

fn impl_roc_gfx_frame(win: u64) -> HostGfxFrameResult {
    if !gfx_open {
        return gfx_bool_err("gfx not open");
    }
    if in_pass {
        gfx::end_pass();
        in_pass = false;
    }
    gfx_bool_ok(gfx::frame())
}

fn impl_roc_gfx_poll(win: u64) -> HostGfxPollResult {
    if !gfx_open {
        return gfx_poll_err("gfx not open");
    }
    if gfx::key_pressed("Escape") {
        return gfx_poll_ok_quit();
    }
    gfx_poll_ok_none()
}

fn impl_roc_gfx_clear(win: u64, r: f32, g: f32, b: f32, a: f32) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    clear_r = r;
    clear_g = g;
    clear_b = b;
    clear_a = a;
    if in_pass {
        gfx::end_pass();
        in_pass = false;
    }
    if !gfx::begin_screen(float4 { r, g, b, a }) {
        return gfx_unit_err("gfx::begin_screen failed");
    }
    in_pass = true;
    gfx_unit_ok()
}

fn impl_roc_gfx_present(win: u64) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    if in_pass {
        gfx::end_pass();
        in_pass = false;
    }
    gfx_unit_ok()
}

fn impl_roc_gfx_window_size(win: u64) -> HostGfxWindowSizeResult {
    if !gfx_open {
        return gfx_winsize_err("gfx not open");
    }
    gfx_winsize_ok(gfx_w, gfx_h)
}

fn impl_roc_gfx_set_title(win: u64, title: RocStr) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    gfx::set_title(rocstr_to_bytes(title));
    gfx_unit_ok()
}

fn impl_roc_gfx_draw_rect(
    win: u64,
    x: f32, y: f32, rw: f32, rh: f32,
    r: f32, g: f32, b: f32, a: f32,
) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    if !in_pass {
        if !gfx::begin_screen(float4 { clear_r, clear_g, clear_b, clear_a }) {
            return gfx_unit_err("begin_screen for draw_rect");
        }
        in_pass = true;
    }
    let _ = x;
    let _ = y;
    let _ = rw;
    let _ = rh;
    let _ = r;
    let _ = g;
    let _ = b;
    let _ = a;
    gfx_unit_ok()
}

fn impl_roc_gfx_key_down(win: u64, name: RocStr) -> HostGfxFrameResult {
    if !gfx_open {
        return gfx_bool_err("gfx not open");
    }
    gfx_bool_ok(gfx::key_down(rocstr_to_bytes(name)))
}

fn impl_roc_gfx_key_pressed(win: u64, name: RocStr) -> HostGfxFrameResult {
    if !gfx_open {
        return gfx_bool_err("gfx not open");
    }
    gfx_bool_ok(gfx::key_pressed(rocstr_to_bytes(name)))
}

fn impl_roc_gfx_mouse_down(win: u64, button: i32) -> HostGfxFrameResult {
    if !gfx_open {
        return gfx_bool_err("gfx not open");
    }
    gfx_bool_ok(gfx::mouse_down(button))
}

fn impl_roc_gfx_mouse_delta(win: u64) -> HostGfxMouseDeltaResult {
    if !gfx_open {
        return gfx_mouse_delta_err("gfx not open");
    }
    let d = gfx::mouse_delta();
    gfx_mouse_delta_ok(d.x, d.y)
}

fn impl_roc_gfx_mouse_pos(win: u64) -> HostGfxMousePosResult {
    if !gfx_open {
        return gfx_mouse_pos_err("gfx not open");
    }
    let p = gfx::mouse_pos();
    gfx_mouse_pos_ok(p.x, p.y)
}

fn impl_roc_gfx_set_mouse_relative(win: u64, on: bool) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    let _ = gfx::set_mouse_relative(on);
    gfx_unit_ok()
}

fn impl_roc_gfx_set_cursor_visible(win: u64, visible: bool) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    let _ = gfx::set_cursor_visible(visible);
    gfx_unit_ok()
}

fn impl_roc_gfx_delta_time(win: u64) -> HostGfxDeltaTimeResult {
    if !gfx_open {
        return gfx_dt_err("gfx not open");
    }
    gfx_dt_ok(gfx::delta_time())
}

fn impl_roc_gfx_texture_create(w: i32, h: i32) -> HostGfxInitResult {
    if !gfx_open {
        return gfx_init_err("gfx not open");
    }
    if w <= 0 || h <= 0 {
        return gfx_init_err("texture size");
    }
    let t = gfx::texture2d(w, h);
    gfx_init_ok(t.id)
}

fn impl_roc_gfx_texture_destroy(tex: u64) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    let t = gfx::Texture { id: tex as u32 };
    gfx::release(t);
    gfx_unit_ok()
}

fn impl_roc_gfx_texture_upload_rgba(tex: u64, rgba: RocList) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    let n = rgba.length as i64;
    if n <= 0 || rgba.bytes == 0 {
        return gfx_unit_err("empty rgba");
    }
    var bytes: u8[>..] = [];
    if !ffi_bytes(rgba.bytes, n, bytes) {
        return gfx_unit_err("rgba copy failed");
    }
    let t = gfx::Texture { id: tex as u32 };
    if !gfx_upload_rgba(t, copy(bytes)) {
        return gfx_unit_err("texture upload failed");
    }
    gfx_unit_ok()
}

fn impl_roc_gfx_draw_textured_quad(
    win: u64,
    x: f32, y: f32, qw: f32, qh: f32,
    tex: u64,
    u0: f32, v0: f32, u1: f32, v1: f32,
) -> HostGfxShutdownResult {
    if !gfx_open {
        return gfx_unit_err("gfx not open");
    }
    if !in_pass {
        if !gfx::begin_screen(float4 { clear_r, clear_g, clear_b, clear_a }) {
            return gfx_unit_err("begin_screen for quad");
        }
        in_pass = true;
    }
    let _ = x;
    let _ = y;
    let _ = qw;
    let _ = qh;
    let _ = tex;
    let _ = u0;
    let _ = v0;
    let _ = u1;
    let _ = v1;
    gfx_unit_ok()
}
