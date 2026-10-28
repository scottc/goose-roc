#include <stdint.h>
#include <stdlib.h>

uint64_t host_malloc(uint64_t size) {
    return (uint64_t)(uintptr_t)malloc((size_t)size);
}

uint64_t host_realloc(uint64_t ptr, uint64_t size) {
    return (uint64_t)(uintptr_t)realloc((void *)(uintptr_t)ptr, (size_t)size);
}

void host_free(uint64_t ptr) {
    free((void *)(uintptr_t)ptr);
}

void host_exit(int code) {
    exit(code);
}
