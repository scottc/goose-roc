#include <stdint.h>

/* Must match what Goose --standalone emits (see host.h / host.c). */
void goose_init(int argc, char **argv);

int main(int argc, char **argv) {
    goose_init(argc, argv);
    return 0;
}
