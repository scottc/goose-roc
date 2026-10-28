// host/host.goose — Roc host ABI; heap via host_libc.c wrappers

extern fn host_malloc(size: u64) -> u64;
extern fn host_realloc(ptr: u64, size: u64) -> u64;
extern fn host_free(ptr: u64);
extern fn host_exit(code: i32);

extern fn host_puts_stdout(msg: u64);
extern fn goose_hello_msg() -> u64;

export "goose_hello" fn goose_hello() {
    host_puts_stdout(goose_hello_msg());
}

fn main() {
}
