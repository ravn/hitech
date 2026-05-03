/* printf format specifiers — exercises libc number formatting. */
#include <stdio.h>

int main(void) {
    printf("dec=%d\n", 42);
    printf("neg=%d\n", -1);
    printf("hex=%x\n", 0xdead);
    printf("oct=%o\n", 0755);
    printf("char=%c\n", 'A');
    printf("str=%s\n", "ok");
    printf("pct=%%\n");
    return 0;
}
