// Pure Goose Roc host: bump arena only. No libc malloc/free/realloc.

//import ffi;

// Soft limit only — actual storage is grow-only on the Goose data stack.
var arena_cap: i64 = 8 * 1024 * 1024; // default until app configures
var arena: u8[>..] = [];
var arena_used: i64 = 0; // high-water / logical used (optional; can use arena.len)

// Soft-limit only. Does not shrink the data stack; raises the budget.
export "roc_configure_arena" fn roc_configure_arena(cap: u64) -> HostLineResult {
    let c = cap as i64;
    if c < 0 {
        abort("goose-pure: configure_arena negative");
    }
    if c < arena.len {
        abort(str(
            "goose-pure: configure_arena ",
            c,
            " < already used ",
            arena.len
        ));
    }
    arena_cap = c;
    line_ok()
}

// parallel to arena: last alloc size for each returned ptr (linear scan is fine for smoke)
struct Block { ptr: u64, size: i64 }
var blocks: Block[>..] = [];

fn note_alloc(p: u64, size: i64) { blocks.push(Block { ptr: p, size: size }); }

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

extern "gs_addr_of_u8" fn addr_of(p: u8&) -> u64;

fn align_up(n: i64, a: i64) -> i64 {
    ((n + a - 1) / a) * a
}

fn sanitize_align(alignment: i64) -> i64 {
    // Valid Roc/host aligns are 8 or 16 (sometimes 32). Anything else is ABI noise.
    if alignment == 8 || alignment == 16 || alignment == 32 || alignment == 64 {
        return alignment;
    }
    //print(str("goose-pure: clamping align ", alignment, " → 8"));
    return 8;
}

let MAX_ONE_ALLOC: i64 = 32 * 1024 * 1024; // 32 MiB single request ceiling

fn bump_alloc(size: i64, alignment: i64) -> u64 {
    let al = sanitize_align(alignment);
    if size < 0 {
        abort(str("goose-pure: negative size ", size));
    }
    if size > MAX_ONE_ALLOC {
        abort(str("goose-pure: alloc too large size=", size, " align=", alignment));
    }

    let padding = align_up(arena.len, al) - arena.len;
    let need = padding + size;
    if need > arena_cap - arena.len {
        abort(str(
            "goose-pure: arena soft limit (cap=",
            arena_cap,
            " used=",
            arena.len,
            " need=",
            need,
            " size=",
            size,
            " raw_align=",
            alignment,
            ")"
        ));
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

export "roc_alloc" fn roc_alloc(size: u64, alignment: u32) -> u64 {
    // Keep width explicit; reject sizes that don't fit i64 budgets
    if size > 0x7fffffff {
        abort(str("goose-pure: roc_alloc size doesn't fit budget: ", size, " align ", alignment));
    }
    //print(str("alloc ", size, " ", alignment));
    let p = bump_alloc(size as i64, alignment);
    note_alloc(p, size as i64);
    return p;
}

extern "gs_memmove_u64" fn memmove_u64(dst: u64, src: u64, n: i64);

export "roc_realloc" fn roc_realloc(ptr: u64, new_size: u64, old_size: u64, alignment: u32) -> u64 {
    //print(str("realloc ptr=", ptr, " new=", new_size, " old=", old_size, " align=", alignment));
    if new_size > 0x7fffffff {
        abort(str("goose-pure: roc_realloc huge new_size=", new_size));
    }
    let np = bump_alloc(new_size as i64, alignment);
    if ptr != 0 {
        var n = old_size;
        if new_size < n {
            n = new_size;
        }
        if n > 0 {
            let tracked = lookup_size(ptr); // from note_alloc on every alloc/realloc
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
            memmove_u64(np, ptr, n);
            note_alloc(np, new_size as i64);
            //print("printing one line after memmove_u64");
        }
    }
    return np;
}

export "roc_dealloc" fn roc_dealloc(_ptr: u64, _alignment: u32) {
    //print("WARN roc_dealloc was called, but goose has grow-only never-free arena pointer data stacks, so this is a no-op & an unnesssary fn call.");
}

export "roc_dbg" fn roc_dbg(_loc: u64, _msg: u64) {
}

export "roc_expect_failed" fn roc_expect_failed(_loc: u64, _msg: u64) {
    abort("goose-pure: expect failed")
}

export "roc_crashed" fn roc_crashed(_msg: u64) {
    abort("goose-pure: roc crashed")
}

// --- RocStr / hosted line result (x86_64 SysV, little-endian) ---

struct RocStr {
    bytes: u64,
    cap: u64,
    len: u64,
}

struct HostLineResult {
    p0: u64,
    p1: u64,
    p2: u64,
    tag: u8,
    _0: u8,
    _1: u8,
    _2: u8,
    _3: u8,
    _4: u8,
    _5: u8,
    _6: u8,
}

fn line_ok() -> HostLineResult {
    HostLineResult {
        p0: 0, p1: 0, p2: 0,
        tag: 1,
        _0: 0, _1: 0, _2: 0, _3: 0, _4: 0, _5: 0, _6: 0,
    }
}

fn is_small_str(s: RocStr) -> bool {
    (s.len as i64) < 0
}

fn small_str_len(s: RocStr) -> i64 {
    // last byte of the 24-byte value = MSB of len on LE
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
    //print(str("sso bytes=", s.bytes, " cap=", s.cap, " len=", s.len));
    print(out); // Goose print adds the newline
}

extern "gs_ffi_bytes" fn ffi_bytes(p: u64, n: i64, out: u8[>..]&) -> bool;
extern "gs_ffi_cstr"  fn ffi_cstr(p: u64, out: u8[>..]&) -> bool;

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

export "roc_stdout_line" fn roc_stdout_line(s: RocStr) -> HostLineResult {
    print_roc_str(s);
    line_ok()
}

export "roc_stderr_line" fn roc_stderr_line(s: RocStr) -> HostLineResult {
    // Same path for now; later print to stderr if Goose exposes it.
    print_roc_str(s);
    line_ok()
}

extern fn roc_main() -> i32; // adjust once arg layout is known

fn main() {
    //print("goose-pure: grow-only bump, app sets soft cap");
    arena.clear(); // or leave empty; reset used
    arena_cap = 8 * 1024 * 1024; // 8MiB default.
    let code = roc_main();
    //print(str("goose-pure: roc_main returned ", code));
    exit(code);  // or return and let process end without gs_exit if that is safer
}
