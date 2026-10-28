/* Process entry only. Goose forbids export "main".
 * goose_init runs Goose fn main() (and thus any roc_main you call from there). */
void goose_init(int argc, char **argv);

int main(int argc, char **argv) {
    goose_init(argc, argv);
    return 0;
}
