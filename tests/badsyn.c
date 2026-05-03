/* Compile-failure test: this is intentionally invalid C. The test
 * passes if zc rejects the file with a non-zero exit status. */
int main(void) {
    this is not valid C syntax;
    return 0;
}
