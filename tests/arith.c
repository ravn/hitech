/* Integer arithmetic — exercises cgen + optim. */
#include <stdio.h>

int main(void) {
    int a = 1000;
    int b = 7;

    printf("a+b=%d\n", a + b);
    printf("a-b=%d\n", a - b);
    printf("a*b=%d\n", a * b);
    printf("a/b=%d\n", a / b);
    printf("a%%b=%d\n", a % b);
    printf("neg=%d\n", -a);
    printf("shl=%d\n", b << 4);
    printf("shr=%d\n", a >> 3);
    printf("and=%d\n", a & b);
    printf("or=%d\n", a | b);
    printf("xor=%d\n", a ^ b);
    return 0;
}
