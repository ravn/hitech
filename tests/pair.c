/* Multi-source linking — main file. */
#include <stdio.h>

extern int compute(int);

int main(void) {
    printf("compute(5)=%d\n", compute(5));
    printf("compute(11)=%d\n", compute(11));
    return 0;
}
