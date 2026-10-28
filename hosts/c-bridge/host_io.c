/* host/host_io.c */
#include <stdio.h>
#include <stdlib.h>
void host_write_stderr(const char *p, size_t n) {
    fwrite(p, 1, n, stderr);
    fputc('\n', stderr);
}
