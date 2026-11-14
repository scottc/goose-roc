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

extern fn ffi_bytes(p: u64, n: i64, out: u8[>..]&) -> bool = "gs_ffi_bytes";
extern fn addr_of(p: u8&) -> u64 = "gs_addr_of_u8";
extern fn addr_of_const(p: const u8&) -> u64 = "gs_addr_of_u8_const";
extern fn memmove_u64(dst: u64, src: u64, n: i64) = "gs_memmove_u64";
extern fn f64_bits(x: f64) -> u64 = "gs_f64_bits";
extern fn f32_bits(x: f32) -> u64 = "gs_f32_bits";
extern fn host_roc_alloc(size: u64, alignment: u32) -> u64 = "roc_alloc";

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




// =============================================================================
// Slice Pool + Slot Pool – final compiling version
// =============================================================================

// ----- basic types ----------------------------------------------------------

struct Slice {
    pool_id: u64,
    offset: u64,
    len: u64,
}

struct HostBuffer {
    ptr: u64,
    len: u64,
}

// Use the real allocator already present in the host
fn host_alloc(size: u64) -> u64 {
    // Re-use the existing bump allocator
    return impl_roc_alloc(size, 8);
}

fn host_free(ptr: u64) {
    // bump allocator does not free individual blocks
}

fn host_panic(msg: u8[>..]) {
    abort(msg);
}

fn host_read_file(path: u8[>..]) -> HostBuffer {
    // TODO: wire to a real file reader when available
    return HostBuffer { ptr: 0, len: 0 };
}

fn host_memcpy(dst: u64, src: u64, len: u64) {
    memmove_u64(dst, src, len as i64);
}

fn host_free_temp(ptr: u64) {
    // nothing for the bump allocator
}

fn host_load_u8(addr: u64) -> u8 {
    // very slow fallback – replace with a real load later
    var tmp: u8[>..] = [];
    if !ffi_bytes(addr, 1, tmp) {
        abort("host_load_u8 failed");
    }
    return tmp[0];
}

// ----- Slice Pool -----------------------------------------------------------

struct SlicePool {
    id: u64,
    base: u64,
    capacity: u64,
    used: u64,
    alive: bool,
}

var slice_pools: SlicePool[>..] = [];
var next_slice_pool_id: u64 = 1;

fn slice_pool_create(capacity_hint: u64) -> u64 {
    var cap: u64 = capacity_hint;
    if cap < 4096 {
        cap = 4096;
    }
    var mem: u64 = host_alloc(cap);
    var id: u64 = next_slice_pool_id;
    next_slice_pool_id = next_slice_pool_id + 1;

    var pool: SlicePool = SlicePool {
        id: id,
        base: mem,
        capacity: cap,
        used: 0,
        alive: true,
    };
    slice_pools.push(pool);
    return id;
}

fn slice_pool_destroy(pool_id: u64) {
    var i: u64 = 0;
    while i < slice_pools.len {
        if slice_pools[i].id == pool_id {
            if slice_pools[i].alive {
                host_free(slice_pools[i].base);
                slice_pools[i].alive = false;
                slice_pools[i].used = 0;
            }
            return;
        }
        i = i + 1;
    }
}

fn slice_pool_alloc(pool_id: u64, len: u64) -> Slice {
    var i: u64 = 0;
    while i < slice_pools.len {
        if slice_pools[i].id == pool_id {
            if slice_pools[i].alive == false {
                host_panic("slice_pool_alloc: pool dead");
            }
            if slice_pools[i].used + len > slice_pools[i].capacity {
                host_panic("slice_pool_alloc: out of space");
            }
            var off: u64 = slice_pools[i].used;
            slice_pools[i].used = slice_pools[i].used + len;
            return Slice {
                pool_id: pool_id,
                offset: off,
                len: len,
            };
        }
        i = i + 1;
    }
    host_panic("slice_pool_alloc: bad pool id");
    return Slice { pool_id: 0, offset: 0, len: 0 };
}

fn slice_pool_load_file(pool_id: u64, path: u8[>..]) -> Slice {
    var file: HostBuffer = host_read_file(copy(path));
    var s: Slice = slice_pool_alloc(pool_id, file.len);
    host_memcpy(slice_pools_get_base(pool_id) + s.offset, file.ptr, file.len);
    host_free_temp(file.ptr);
    return s;
}

fn slice_pool_get_byte(pool_id: u64, abs_offset: u64) -> u8 {
    var base: u64 = slice_pools_get_base(pool_id);
    return host_load_u8(base + abs_offset);
}

fn slice_pool_to_list(pool_id: u64, offset: u64, len: u64) -> u8[>..] {
    var base: u64 = slice_pools_get_base(pool_id);
    var out: u8[>..] = [];
    var i: u64 = 0;
    while i < len {
        out.push(host_load_u8(base + offset + i));
        i = i + 1;
    }
    return out;
}

fn slice_pools_get_base(pool_id: u64) -> u64 {
    var i: u64 = 0;
    while i < slice_pools.len {
        if slice_pools[i].id == pool_id {
            if slice_pools[i].alive {
                return slice_pools[i].base;
            }
        }
        i = i + 1;
    }
    host_panic("slice_pools_get_base: bad id");
    return 0;
}

// ----- Fixed Slot Pool ------------------------------------------------------

struct FixedSlotPool {
    id: u64,
    slot_size: u64,
    capacity: u64,
    base: u64,
    alive: bool,
    free_start: u64,
    free_len: u64,
}

var fixed_slot_pools: FixedSlotPool[>..] = [];
var free_storage: u64[>..] = [];
var next_slot_pool_id: u64 = 1;

fn slot_pool_create_fixed(slot_size: u64, capacity: u64) -> u64 {
    var bytes: u64 = slot_size * capacity;
    var mem: u64 = host_alloc(bytes);
    var id: u64 = next_slot_pool_id;
    next_slot_pool_id = next_slot_pool_id + 1;

    // explicit cast – .len is i64
    var start: u64 = free_storage.len as u64;
    var i: u64 = 0;
    while i < capacity {
        free_storage.push(i);
        i = i + 1;
    }

    var pool: FixedSlotPool = FixedSlotPool {
        id: id,
        slot_size: slot_size,
        capacity: capacity,
        base: mem,
        alive: true,
        free_start: start,
        free_len: capacity,
    };
    fixed_slot_pools.push(pool);
    return id;
}

fn slot_pool_destroy(pool_id: u64) {
    var i: u64 = 0;
    while i < fixed_slot_pools.len {
        if fixed_slot_pools[i].id == pool_id {
            if fixed_slot_pools[i].alive {
                host_free(fixed_slot_pools[i].base);
                fixed_slot_pools[i].alive = false;
            }
            return;
        }
        i = i + 1;
    }
}

fn slot_pool_alloc_fixed(pool_id: u64) -> u64 {
    var i: u64 = 0;
    while i < fixed_slot_pools.len {
        if fixed_slot_pools[i].id == pool_id {
            if fixed_slot_pools[i].alive == false {
                host_panic("slot_pool_alloc_fixed: pool dead");
            }
            if fixed_slot_pools[i].free_len == 0 {
                host_panic("slot_pool_alloc_fixed: pool full");
            }
            var idx: u64 = fixed_slot_pools[i].free_start + fixed_slot_pools[i].free_len - 1;
            var slot: u64 = free_storage[idx];
            fixed_slot_pools[i].free_len = fixed_slot_pools[i].free_len - 1;
            return slot;
        }
        i = i + 1;
    }
    host_panic("slot_pool_alloc_fixed: bad pool id");
    return 0;
}

fn slot_pool_free(pool_id: u64, slot: u64) {
    var i: u64 = 0;
    while i < fixed_slot_pools.len {
        if fixed_slot_pools[i].id == pool_id {
            if fixed_slot_pools[i].alive {
                var idx: u64 = fixed_slot_pools[i].free_start + fixed_slot_pools[i].free_len;
                if idx < free_storage.len as u64 {
                    free_storage[idx] = slot;
                } else {
                    free_storage.push(slot);
                }
                fixed_slot_pools[i].free_len = fixed_slot_pools[i].free_len + 1;
            }
            return;
        }
        i = i + 1;
    }
}

// ----- Variable Slot Pool (bump) --------------------------------------------

struct VarSlotPool {
    id: u64,
    base: u64,
    capacity: u64,
    used: u64,
    alive: bool,
}

var var_slot_pools: VarSlotPool[>..] = [];

fn slot_pool_create_var(capacity_hint_bytes: u64) -> u64 {
    var cap: u64 = capacity_hint_bytes;
    if cap < 4096 {
        cap = 4096;
    }
    var mem: u64 = host_alloc(cap);
    var id: u64 = next_slot_pool_id;
    next_slot_pool_id = next_slot_pool_id + 1;

    var pool: VarSlotPool = VarSlotPool {
        id: id,
        base: mem,
        capacity: cap,
        used: 0,
        alive: true,
    };
    var_slot_pools.push(pool);
    return id;
}

fn slot_pool_alloc_var(pool_id: u64, bytes: u64) -> u64 {
    var i: u64 = 0;
    while i < var_slot_pools.len {
        if var_slot_pools[i].id == pool_id {
            if var_slot_pools[i].alive == false {
                host_panic("slot_pool_alloc_var: pool dead");
            }
            var aligned: u64 = (bytes + 7) & (~7);
            if var_slot_pools[i].used + aligned > var_slot_pools[i].capacity {
                host_panic("slot_pool_alloc_var: out of space");
            }
            var slot: u64 = var_slot_pools[i].used;
            var_slot_pools[i].used = var_slot_pools[i].used + aligned;
            return slot;
        }
        i = i + 1;
    }
    host_panic("slot_pool_alloc_var: bad pool id");
    return 0;
}

// ---- Slice pool effects (called from Roc) ---------------------------------

fn impl_roc_slice_pool_create(capacity_hint: u64) -> HostSlicePoolCreateResult {
    let id = slice_pool_create(capacity_hint);
    // return the same 32-byte Ok layout other effects use
    // (adjust field names to match your generated Host*Result types)
    HostSlicePoolCreateResult {
        p0: id, p1: 0, p2: 0,
        tag: 1,
        _pad0: 0, _pad1: 0, _pad2: 0, _pad3: 0, _pad4: 0, _pad5: 0, _pad6: 0,
    }
}

fn impl_roc_slice_pool_destroy(pool_id: u64) -> HostSlicePoolDestroyResult {
    slice_pool_destroy(pool_id);
    line_ok_32()          // reuse the helper that returns an empty Ok
}

fn impl_roc_slice_pool_alloc(pool_id: u64, len: u64) -> HostSlicePoolAllocResult {
    let s = slice_pool_alloc(pool_id, len);
    // pack Slice {pool_id, offset, len} into the result
    HostSlicePoolAllocResult {
        pool_id: s.pool_id,
        offset: s.offset,
        len: s.len,
        tag: 1,
        // padding as required by glue
    }
}

// The important one: copy a Roc List(U8) into the pool
fn impl_roc_slice_pool_from_list(pool_id: u64, list: RocList) -> HostSlicePoolFromListResult {
    let len = list.length;
    if len == 0 {
        // empty slice
        // ...
    }
    let s = slice_pool_alloc(pool_id, len);
    // copy bytes from the Roc list into the pool
    if list.bytes != 0 && len > 0 {
        memmove_u64(slice_pools_get_base(pool_id) + s.offset, list.bytes, len as i64);
    }
    // return the Slice
    ...
}

fn impl_roc_slice_pool_get_byte(pool_id: u64, abs_offset: u64) -> HostSlicePoolGetByteResult {
    let b = slice_pool_get_byte(pool_id, abs_offset);
    // return Ok(b)
    ...
}

fn impl_roc_slot_pool_create_fixed(slot_size: u64, capacity: u64) -> HostSlotPoolCreateResult {
    let id = slot_pool_create_fixed(slot_size, capacity);
    // pack Ok(id) in the usual 32-byte result layout
    ...
}

fn impl_roc_slot_pool_create_var(capacity_hint: u64) -> HostSlotPoolCreateResult {
    let id = slot_pool_create_var(capacity_hint);
    ...
}

fn impl_roc_slot_pool_destroy(pool_id: u64) -> HostSlotPoolDestroyResult {
    slot_pool_destroy(pool_id);
    line_ok_32()
}

fn impl_roc_slot_pool_alloc_fixed(pool_id: u64) -> HostSlotPoolAllocResult {
    let slot = slot_pool_alloc_fixed(pool_id);
    // return Ok(slot)
    ...
}

fn impl_roc_slot_pool_alloc_var(pool_id: u64, bytes: u64) -> HostSlotPoolAllocResult {
    let slot = slot_pool_alloc_var(pool_id, bytes);
    ...
}

fn impl_roc_slot_pool_free(pool_id: u64, slot: u64) -> HostSlotPoolFreeResult {
    slot_pool_free(pool_id, slot);
    line_ok_32()
}

// get_fixed / set_fixed – copy to/from a temporary Roc List
fn impl_roc_slot_pool_get_fixed(pool_id: u64, slot: u64, expected_size: u64) -> HostSlotPoolGetFixedResult {
    // allocate a Roc list of expected_size, copy the slot bytes into it, return Ok(list)
    ...
}

fn impl_roc_slot_pool_set_fixed(pool_id: u64, slot: u64, list: RocList) -> HostSlotPoolSetFixedResult {
    // copy list.bytes into the slot
    ...
}
