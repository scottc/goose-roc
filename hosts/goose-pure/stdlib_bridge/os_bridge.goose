// Same symbols as stdlib/os.goose (runtime_os.h)
extern "gs_os_read_file" fn os_read_file(path: const u8[:], out: u8[>..]&) -> bool;
extern "gs_os_write_file" fn os_write_file(path: const u8[:], data: const u8[:]) -> bool;
extern "gs_os_append_file" fn os_append_file(path: const u8[:], data: const u8[:]) -> bool;
extern "gs_os_file_exists" fn os_file_exists(path: const u8[:]) -> bool;
extern "gs_os_remove_file" fn os_delete_file(path: const u8[:]) -> bool;
extern "gs_os_make_dir" fn os_make_dir(path: const u8[:]) -> bool;
extern "gs_os_remove_dir" fn os_delete_dir(path: const u8[:]) -> bool;
extern "gs_os_list_dir" fn os_list_dir(path: const u8[:], out: u8[>..]&) -> bool;
extern "gs_os_getenv" fn os_env(name: const u8[:], out: u8[>..]&) -> bool;
extern "gs_os_time_ns" fn os_time_ns() -> i64;
extern "gs_os_clock_ns" fn os_clock_ns() -> i64;
extern "gs_os_sleep_ms" fn os_sleep_ms(ms: i64);

struct TryParts {
    p0: u64,
    p1: u64,
    p2: u64,
    tag: u8,
}

fn rocstr_is_small(s: RocStr) -> bool {
    (s.len as i64) < 0
}

fn rocstr_small_len(s: RocStr) -> i64 {
    let last = (s.len >> 56) & 0xff;
    (last ^ 0x80) as i64
}

fn rocstr_byte_at(s: RocStr, i: i64) -> u8 {
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

fn rocstr_to_bytes(s: RocStr) -> u8[>..] {
    var out: u8[>..] = [];
    if rocstr_is_small(s) {
        let n = rocstr_small_len(s);
        if n < 0 || n > 23 {
            abort("os_bridge: corrupt small RocStr");
        }
        for i in n {
            out.push(rocstr_byte_at(s, i));
        }
        return out;
    }
    let n = s.len as i64;
    if n <= 0 {
        return out;
    }
    if s.bytes == 0 {
        abort("os_bridge: null RocStr bytes");
    }
    if !ffi_bytes(s.bytes, n, out) {
        abort("os_bridge: ffi_bytes failed");
    }
    out
}

fn roclist_to_bytes(list: RocList) -> u8[>..] {
    var out: u8[>..] = [];
    let n = list.length as i64;
    if n <= 0 {
        return out;
    }
    if list.bytes == 0 {
        abort("os_bridge: null RocList bytes");
    }
    if !ffi_bytes(list.bytes, n, out) {
        abort("os_bridge: roclist ffi_bytes failed");
    }
    out
}

fn copy_into_roc_ptr(dst: u64, src: const u8[:]) {
    if src.len <= 0 {
        return;
    }
    let sp = addr_of_const(src[0]);
    memmove_u64(dst, sp, src.len);
}

fn bytes_to_roclist(src: const u8[:]) -> RocList {
    if src.len <= 0 {
        return RocList { bytes: 0, length: 0, capacity_or_other: 0 };
    }
    let n = src.len as u64;
    let ptr = host_roc_alloc(n, 8);
    if ptr == 0 {
        abort("os_bridge: roc_alloc failed for list");
    }
    copy_into_roc_ptr(ptr, src);
    RocList { bytes: ptr, length: n, capacity_or_other: n }
}

fn bytes_to_rocstr(src: const u8[:]) -> RocStr {
    if src.len <= 23 {
        var bytes: u64 = 0;
        var cap: u64 = 0;
        var len: u64 = 0;
        for i in src.len {
            let b = src[i] as u64;
            let shift = (i & 7) * 8;
            if i < 8 {
                bytes = bytes | (b << shift);
            } else if i < 16 {
                cap = cap | (b << shift);
            } else {
                len = len | (b << shift);
            }
        }
        let last = (src.len as u64) ^ 0x80;
        len = (len & 0x00ffffffffffffff) | (last << 56);
        return RocStr { bytes, cap, len };
    }
    let n = src.len as u64;
    let ptr = host_roc_alloc(n, 8);
    if ptr == 0 {
        abort("os_bridge: roc_alloc failed for str");
    }
    copy_into_roc_ptr(ptr, src);
    RocStr { bytes: ptr, cap: n, len: n }
}

fn try_err_str(msg: const u8[:]) -> TryParts {
    let s = bytes_to_rocstr(msg);
    TryParts { p0: s.bytes, p1: s.cap, p2: s.len, tag: 0 }
}

fn try_ok_list(list: RocList) -> TryParts {
    TryParts {
        p0: list.bytes,
        p1: list.length,
        p2: list.capacity_or_other,
        tag: 1,
    }
}

fn try_ok_unit() -> TryParts {
    TryParts { p0: 0, p1: 0, p2: 0, tag: 1 }
}

fn try_ok_bool(v: bool) -> TryParts {
    let x: u64 = if v { 1 } else { 0 };
    TryParts { p0: x, p1: 0, p2: 0, tag: 1 }
}

fn try_ok_f64(v: f64) -> TryParts {
    TryParts { p0: f64_bits(v), p1: 0, p2: 0, tag: 1 }
}

fn pack_write(t: TryParts) -> HostOsWriteFileResult {
    HostOsWriteFileResult {
        p0: t.p0, p1: t.p1, p2: t.p2, tag: t.tag,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn pack_read(t: TryParts) -> HostOsReadFileResult {
    HostOsReadFileResult {
        p0: t.p0, p1: t.p1, p2: t.p2, tag: t.tag,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn pack_exists(t: TryParts) -> HostOsFileExistsResult {
    HostOsFileExistsResult {
        p0: t.p0, p1: t.p1, p2: t.p2, tag: t.tag,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn pack_list_dir(t: TryParts) -> HostOsListDirResult {
    HostOsListDirResult {
        p0: t.p0, p1: t.p1, p2: t.p2, tag: t.tag,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn pack_cwd(t: TryParts) -> HostOsCwdResult {
    HostOsCwdResult {
        p0: t.p0, p1: t.p1, p2: t.p2, tag: t.tag,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn pack_clock(t: TryParts) -> HostOsClockSecsResult {
    HostOsClockSecsResult {
        p0: t.p0, p1: t.p1, p2: t.p2, tag: t.tag,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn pack_env_list(t: TryParts) -> HostOsEnvListResult {
    HostOsEnvListResult {
        p0: t.p0, p1: t.p1, p2: t.p2, tag: t.tag,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn impl_roc_os_read_file(path: RocStr) -> HostOsReadFileResult {
    let p = rocstr_to_bytes(path);
    var buf: u8[>..] = [];
    if !os_read_file(p, buf) {
        return pack_read(try_err_str("read_file failed"));
    }
    pack_read(try_ok_list(bytes_to_roclist(buf)))
}

fn impl_roc_os_write_file(path: RocStr, bytes: RocList) -> HostOsWriteFileResult {
    let p = rocstr_to_bytes(path);
    let data = roclist_to_bytes(bytes);
    if !os_write_file(p, data) {
        return pack_write(try_err_str("write_file failed"));
    }
    pack_write(try_ok_unit())
}

fn impl_roc_os_append_file(path: RocStr, bytes: RocList) -> HostOsWriteFileResult {
    let p = rocstr_to_bytes(path);
    let data = roclist_to_bytes(bytes);
    if !os_append_file(p, data) {
        return pack_write(try_err_str("append_file failed"));
    }
    pack_write(try_ok_unit())
}

fn impl_roc_os_file_exists(path: RocStr) -> HostOsFileExistsResult {
    let p = rocstr_to_bytes(path);
    pack_exists(try_ok_bool(os_file_exists(p)))
}

fn impl_roc_os_remove_file(path: RocStr) -> HostOsWriteFileResult {
    let p = rocstr_to_bytes(path);
    if !os_delete_file(p) {
        return pack_write(try_err_str("delete_file failed"));
    }
    pack_write(try_ok_unit())
}

fn impl_roc_os_list_dir(path: RocStr) -> HostOsListDirResult {
    pack_list_dir(try_err_str("list_dir: List(Str) encode not wired"))
}

fn impl_roc_os_create_dir(path: RocStr) -> HostOsWriteFileResult {
    let p = rocstr_to_bytes(path);
    if !os_make_dir(p) {
        return pack_write(try_err_str("make_dir failed"));
    }
    pack_write(try_ok_unit())
}

fn impl_roc_os_remove_dir(path: RocStr) -> HostOsWriteFileResult {
    let p = rocstr_to_bytes(path);
    if !os_delete_dir(p) {
        return pack_write(try_err_str("delete_dir failed"));
    }
    pack_write(try_ok_unit())
}

fn impl_roc_os_cwd() -> HostOsCwdResult {
    pack_cwd(try_err_str("cwd: not in Goose os"))
}

fn impl_roc_os_set_cwd(path: RocStr) -> HostOsWriteFileResult {
    pack_write(try_err_str("set_cwd: not in Goose os"))
}

fn impl_roc_os_clock_secs() -> HostOsClockSecsResult {
    let secs = (os_time_ns() as f64) / 1000000000.0;
    pack_clock(try_ok_f64(secs))
}

fn impl_roc_os_monotonic_secs() -> HostOsClockSecsResult {
    let secs = (os_clock_ns() as f64) / 1000000000.0;
    pack_clock(try_ok_f64(secs))
}

fn impl_roc_os_sleep_ms(ms: u64) -> HostOsWriteFileResult {
    os_sleep_ms(ms as i64);
    pack_write(try_ok_unit())
}

fn impl_roc_os_env_get(key: RocStr) -> HostOsCwdResult {
    let k = rocstr_to_bytes(key);
    var buf: u8[>..] = [];
    if !os_env(k, buf) {
        return pack_cwd(try_err_str("env not set"));
    }
    let s = bytes_to_rocstr(buf);
    pack_cwd(TryParts { p0: s.bytes, p1: s.cap, p2: s.len, tag: 1 })
}

fn impl_roc_os_env_set(key: RocStr, val: RocStr) -> HostOsWriteFileResult {
    pack_write(try_err_str("env_set: not in Goose os"))
}

fn impl_roc_os_env_list() -> HostOsEnvListResult {
    pack_env_list(try_err_str("env_list: not in Goose os"))
}
