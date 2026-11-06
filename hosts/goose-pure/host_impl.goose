// host_impl.goose — concat between types and exports

var arena_cap: i64 = 8 * 1024 * 1024;
var arena: u8[>..] = [];

struct Block { ptr: u64, size: i64 }
var blocks: Block[>..] = [];

fn note_alloc(p: u64, size: i64) {
    blocks.push(Block { ptr: p, size: size });
}

fn lookup_size(p: u64) -> i64 {
    var i = blocks.len;
    while i > 0 {
        i = i - 1;
        if blocks[i].ptr == p {
            return blocks[i].size;
        }
    }
    return -1;
}

extern "gs_ffi_bytes" fn ffi_bytes(p: u64, n: i64, out: u8[>..]&) -> bool;
extern "gs_addr_of_u8" fn addr_of(p: u8&) -> u64;
extern "gs_addr_of_u8_const" fn addr_of_const(p: const u8&) -> u64;
extern "gs_memmove_u64" fn memmove_u64(dst: u64, src: u64, n: i64);
extern "gs_f64_bits" fn f64_bits(x: f64) -> u64;
extern "gs_f32_bits" fn f32_bits(x: f32) -> u64;
extern "roc_alloc" fn host_roc_alloc(size: u64, alignment: u32) -> u64;

fn align_up(n: i64, a: i64) -> i64 {
    ((n + a - 1) / a) * a
}

fn sanitize_align(alignment: i64) -> i64 {
    if alignment == 8 || alignment == 16 || alignment == 32 || alignment == 64 {
        return alignment;
    }
    return 8;
}

let MAX_ONE_ALLOC: i64 = 32 * 1024 * 1024;

fn bump_alloc(size: i64, alignment: i64) -> u64 {
    let al = sanitize_align(alignment);
    if size < 0 {
        abort(str("goose-pure: negative size ", size));
    }
    if size > MAX_ONE_ALLOC {
        abort(str("goose-pure: alloc too large ", size));
    }
    let padding = align_up(arena.len, al) - arena.len;
    let need = padding + size;
    if need > arena_cap - arena.len {
        abort(str("goose-pure: arena soft limit cap=", arena_cap, " used=", arena.len, " need=", need));
    }
    for _ in padding {
        arena.push(0);
    }
    let start = arena.len;
    for _ in size {
        arena.push(0);
    }
    return addr_of(arena[start]);
}

fn impl_roc_alloc(size: u64, alignment: u32) -> u64 {
    if size > 0x7fffffff {
        abort(str("goose-pure: roc_alloc too large ", size));
    }
    let p = bump_alloc(size as i64, alignment);
    note_alloc(p, size as i64);
    return p;
}

fn impl_roc_dealloc(_ptr: u64, _alignment: u32) {
}

fn impl_roc_realloc(ptr: u64, new_size: u64, old_size: u64, alignment: u32) -> u64 {
    if new_size > 0x7fffffff {
        abort(str("goose-pure: realloc too large ", new_size));
    }
    let np = bump_alloc(new_size as i64, alignment);
    if ptr != 0 {
        let tracked = lookup_size(ptr);
        var n: i64 = 0;
        if tracked >= 0 {
            n = tracked;
        } else {
            n = old_size as i64;
        }
        if n > new_size as i64 {
            n = new_size as i64;
        }
        if n < 0 {
            n = 0;
        }
        if n > 0 {
            memmove_u64(np, ptr, n);
        }
        note_alloc(np, new_size as i64);
    }
    return np;
}

fn impl_roc_dbg(_loc: u64, _msg: u64) {
}

fn impl_roc_expect_failed(_loc: u64, _msg: u64) {
    abort("goose-pure: expect failed");
}

fn impl_roc_crashed(_msg: u64) {
    abort("goose-pure: roc crashed");
}

fn line_ok_32() -> HostStdoutLineResult {
    // Same 32-byte Ok layout for all Try line results if glue shapes match.
    // If HostStderrLineResult / HostConfigureArenaResult are distinct types,
    // duplicate helpers or cast via matching field layouts.
    HostStdoutLineResult {
        p0: 0, p1: 0, p2: 0,
        tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn is_small_str(s: RocStr) -> bool {
    (s.len as i64) < 0
}

fn small_str_len(s: RocStr) -> i64 {
    let last = (s.len >> 56) & 0xff;
    (last ^ 0x80) as i64
}

fn rocstr_byte(s: RocStr, i: i64) -> u8 {
    let word = if i < 8 {
        s.bytes
    } else if i < 16 {
        s.cap
    } else {
        s.len
    };
    let shift = (i & 7) * 8;
    ((word >> shift) & 0xff) as u8
}

fn print_small_str(s: RocStr) {
    let n = small_str_len(s);
    if n < 0 || n > 23 {
        abort("goose-pure: corrupt small RocStr");
    }
    var out: u8[>..] = [];
    for i in n {
        out.push(rocstr_byte(s, i));
    }
    print(out);
}

fn print_roc_str(s: RocStr) {
    if is_small_str(s) {
        print_small_str(s);
        return;
    }
    let n = s.len as i64;
    if n <= 0 {
        print("");
        return;
    }
    if s.bytes == 0 {
        abort("goose-pure: null RocStr bytes");
    }
    var out: u8[>..] = [];
    if !ffi_bytes(s.bytes, n, out) {
        abort("goose-pure: gs_ffi_bytes failed");
    }
    print(out);
}

// Match exact type names from roc_platform_abi_types.goose after glue runs.
fn impl_roc_stdout_line(arg0: RocStr) -> HostStdoutLineResult {
    print_roc_str(arg0);
    HostStdoutLineResult {
        p0: 0, p1: 0, p2: 0,
        tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn impl_roc_stderr_line(arg0: RocStr) -> HostStderrLineResult {
    print_roc_str(arg0);
    HostStderrLineResult {
        p0: 0, p1: 0, p2: 0,
        tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn impl_roc_stdout_bytes(arg0: RocList) -> HostStdoutLineResult {
    abort("impl_roc_stdout_bytes");
}

fn impl_roc_stderr_bytes(arg0: RocList) -> HostStderrLineResult {
    abort("impl_roc_stderr_bytes");
}

fn impl_roc_bump_set_limit_bytes(arg0: u64) -> HostBumpSetLimitBytesResult {
    let c = arg0 as i64;
    if c < 0 {
        abort("goose-pure: configure_arena negative");
    }
    if c < arena.len {
        abort(str("goose-pure: configure_arena ", c, " < used ", arena.len));
    }
    arena_cap = c;
    HostBumpSetLimitBytesResult {
        p0: 0, p1: 0, p2: 0,
        tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn impl_roc_bump_used_bytes() -> HostBumpUsedBytesResult {
    abort("impl_roc_bump_used_bytes");
}

fn impl_roc_bump_limit_bytes() -> HostBumpUsedBytesResult {
    abort("impl_roc_bump_limit_bytes");
}


fn empty_roc_list() -> RocList {
    RocList { bytes: 0, length: 0, capacity_or_other: 0 }
}

fn main() {
    arena.clear();
    blocks.clear();
    arena_cap = 8 * 1024 * 1024;
    var args = empty_roc_list();
    exit(roc_main(args));
}
