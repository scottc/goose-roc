#include <stdint.h>
#include <string.h>
#include <unistd.h>

typedef struct {
    void *elements;
    size_t length;
    size_t capacity_or_alloc_ptr;
} RocList;

extern int32_t roc_main(RocList args);
extern void goose_init(int argc, char **argv);
extern void goose_hello(void);

static void log_msg(const char *s) {
    size_t n = 0;
    while (s[n])
        n++;
    (void)write(2, s, n);
}

int main(int argc, char **argv) {
    goose_init(argc, argv);
    goose_hello();

    RocList empty = {0};
    return (int)roc_main(empty);
}
