/* runtime_ext.h (newer Goose) */
typedef struct { uint8_t *base; int64_t len; } gs_rhdr;
typedef struct { uint8_t *top; } gs_stack;
typedef struct { gs_rhdr *hdr; gs_stack *stk; } gs_rref;

static void gs_bld_append(gs_rref b, const void *p, int64_t n) {
    if (n <= 0) return;
    memcpy(b.stk->top, p, (size_t)n);
    b.stk->top += n;
    b.hdr->len += n;
}

static uint8_t gs_ffi_bytes(uint64_t p, int64_t n, gs_rref out) {
    if (!p) return 0;
    gs_bld_append(out, (const void *)(uintptr_t)p, n);
    return 1;
}
