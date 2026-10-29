// Pure Goose Roc host: bump arena only. No libc malloc/free/realloc.

//import ffi;

let ARENA_CAP = 1048576;

var arena: u8[ARENA_CAP] = [0; ARENA_CAP];
var arena_used: i64 = 0;

fn align_up(n: i64, a: i64) -> i64 {
    ((n + a - 1) / a) * a
}

fn bump_alloc(size: i64, alignment: i64) -> u64 {
    let al = if alignment < 8 { 8 } else { alignment };
    let start = align_up(arena_used, al);
    let end = start + size;
    if end > ARENA_CAP {
        abort("goose-pure: bump arena exhausted");
    }
    arena_used = end;
    abort("goose-pure: bump pointer as u64 not wired");
}

export "roc_alloc" fn roc_alloc(size: u64, alignment: u32) -> u64 {
    bump_alloc(size as i64, alignment)  // u32 → i64 is implicit
}

export "roc_dealloc" fn roc_dealloc(_ptr: u64, _alignment: u32) {
}

export "roc_realloc" fn roc_realloc(_ptr: u64, _new_size: u64, _old: u64, _alignment: u32) -> u64 {
    abort("goose-pure: roc_realloc not supported on bump arena")
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
    print("goose-pure: bump-only host, no libc heap");
    arena_used = 0;
    let code = roc_main();
    exit(code);
}
