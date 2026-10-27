#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void *roc_alloc(size_t length, size_t alignment) {
    (void)alignment;
    if (length == 0)
        length = 1;
    void *p = malloc(length);
    if (!p)
        abort();
    return p;
}

void *roc_realloc(void *ptr, size_t new_length, size_t alignment) {
    (void)alignment;
    if (new_length == 0)
        new_length = 1;
    void *p = realloc(ptr, new_length);
    if (!p)
        abort();
    return p;
}

void roc_dealloc(void *ptr, size_t alignment) {
    (void)alignment;
    free(ptr);
}

void roc_dbg(const uint8_t *bytes, size_t len) {
    if (bytes && len)
        (void)write(2, bytes, len);
    (void)write(2, "\n", 1);
}

void roc_expect_failed(const uint8_t *bytes, size_t len) {
    (void)write(2, "EXPECT FAILED\n", 14);
    if (bytes && len)
        (void)write(2, bytes, len);
    abort();
}

void roc_crashed(const uint8_t *bytes, size_t len) {
    (void)write(2, "ROC CRASHED\n", 12);
    if (bytes && len)
        (void)write(2, bytes, len);
    abort();
}

void host_write_stdout(const uint8_t *bytes, size_t len) {
    if (bytes && len)
        (void)write(1, bytes, len);
}

void host_write_stderr(const uint8_t *bytes, size_t len) {
    if (bytes && len)
        (void)write(2, bytes, len);
}

/* fixed message for Goose to print */
void host_puts_stdout(const char *s) {
    if (!s)
        return;
    host_write_stdout((const uint8_t *)s, strlen(s));
}

typedef struct {
    uint8_t *bytes;
    size_t capacity_or_alloc_ptr;
    size_t length;
} RocStr;

typedef struct {
    uint8_t payload[24];
    uint8_t tag; /* 0 = Err, 1 = Ok */
    uint8_t pad[7];
} HostLineResult; /* 32 bytes, tag @ 24 */

static int roc_str_is_small(RocStr s) {
    return (ssize_t)s.length < 0;
}

static void roc_str_bytes(RocStr s, const uint8_t **out, size_t *len) {
    if (roc_str_is_small(s)) {
        const uint8_t *raw = (const uint8_t *)&s;
        *len = (size_t)(raw[23] ^ 0x80);
        *out = raw;
    } else {
        *out = s.bytes;
        *len = s.length;
    }
}

/* TODO: real decref; leak is ok for first Hello */
HostLineResult roc_stdout_line(RocStr s) {
    const uint8_t *p;
    size_t n;
    roc_str_bytes(s, &p, &n);
    host_write_stdout(p, n);
    host_write_stdout((const uint8_t *)"\n", 1);

    HostLineResult r;
    memset(&r, 0, sizeof(r));
    r.tag = 1; /* Ok */
    return r;
}

HostLineResult roc_stderr_line(RocStr s) {
    const uint8_t *p;
    size_t n;
    roc_str_bytes(s, &p, &n);
    host_write_stderr(p, n);
    host_write_stderr((const uint8_t *)"\n", 1);

    HostLineResult r;
    memset(&r, 0, sizeof(r));
    r.tag = 1;
    return r;
}
