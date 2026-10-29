// Vendored from upstream stdlib/ffi.goose — works if the runtime
// defines gs_ffi_bytes / gs_ffi_cstr (newer Goose). On v2026.3, verify with nm.

namespace ffi;

extern fn cstr(p: u64, out: u8[>..]&) -> bool = "gs_ffi_cstr";
extern fn bytes(p: u64, n: i64, out: u8[>..]&) -> bool = "gs_ffi_bytes";

fn cstr(p: u64) -> u8[>..] {
    var out: u8[>..] = [];
    cstr(p, out);
    return out;
}

fn bytes(p: u64, n: i64) -> u8[>..] {
    var out: u8[>..] = [];
    bytes(p, n, out);
    return out;
}
