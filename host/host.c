// host.c  – minimal Roc host using the system allocator
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

void *roc_alloc(size_t size, uint32_t alignment) {
    (void)alignment;          // libc malloc is sufficiently aligned for Roc
    return malloc(size ? size : 1);
}

void *roc_realloc(void *ptr, size_t new_size, size_t old_size, uint32_t alignment) {
    (void)old_size;
    (void)alignment;
    return realloc(ptr, new_size ? new_size : 1);
}

void roc_dealloc(void *ptr, uint32_t alignment) {
    (void)alignment;
    free(ptr);
}

void roc_dbg(const uint8_t *bytes, size_t len) {
    fwrite(bytes, 1, len, stderr);
    fputc('\n', stderr);
}

void roc_expect_failed(const uint8_t *bytes, size_t len) {
    fputs("Expect failed: ", stderr);
    fwrite(bytes, 1, len, stderr);
    fputc('\n', stderr);
    abort();
}

void roc_crashed(const uint8_t *bytes, size_t len) {
    fputs("Roc crashed: ", stderr);
    fwrite(bytes, 1, len, stderr);
    fputc('\n', stderr);
    abort();
}

// The symbol the platform’s `provides` section will call into.
// Exact name depends on how you write platform/main.roc; adjust later.
extern void roc__mainForHost_1_exposed_generic(/* args */);  // or whatever the current backend emits

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    // Call the Roc entry point once the platform is wired up.
    // For a pure “hello” you may just need:
    // roc__mainForHost_1_exposed(...);
    return 0;
}
