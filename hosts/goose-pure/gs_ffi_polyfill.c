/* Polyfill for Goose runtime symbols missing from v2026.3 --standalone.
 * Layout must match generated host.c (gs_rhdr / gs_stack / gs_rref). */
#include <stdint.h>
#include <string.h>

typedef struct {
    uint8_t *base;
    int64_t len;
} gs_rhdr;

typedef struct {
    uint8_t *top;
} gs_stack;

typedef struct {
    gs_rhdr *hdr;
    gs_stack *stk;
} gs_rref;

static void gs_bld_append(gs_rref b, const void *p, int64_t n) {
    if (n <= 0) return;
    memcpy(b.stk->top, p, (size_t)n);
    b.stk->top += n;
    b.hdr->len += n;
}

uint8_t gs_ffi_bytes(uint64_t p, int64_t n, gs_rref out) {
    if (!p) return 0;
    gs_bld_append(out, (const void *)(uintptr_t)p, n);
    return 1;
}

uint8_t gs_ffi_cstr(uint64_t p, gs_rref out) {
    const char *s = (const char *)(uintptr_t)p;
    if (!s) return 0;
    gs_bld_append(out, s, (int64_t)strlen(s));
    return 1;
}

/* Address of a Goose u8& for Roc / other foreign runtimes.
 * Goose has no ref→integer cast; C receives the pointer. */
uint64_t gs_addr_of_u8(uint8_t *p) {
    return (uint64_t)(uintptr_t)p;
}

void gs_memmove_u64(uint64_t dst, uint64_t src, int64_t n) {
    if (n <= 0 || dst == 0 || src == 0) return;
    memmove((void *)(uintptr_t)dst, (const void *)(uintptr_t)src, (size_t)n);
}
