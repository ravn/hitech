/* string.h functions from libc.lib. */
#include <stdio.h>
#include <string.h>

int main(void) {
    char buf[32];

    strcpy(buf, "abc");
    strcat(buf, "def");
    printf("len=%d\n", (int)strlen(buf));
    printf("str=%s\n", buf);

    /* equal: must be 0 per ISO C */
    printf("eq=%d\n", strcmp(buf, "abcdef"));

    /* less-than / greater-than: any negative / positive; normalise to bool */
    printf("less=%d\n", strcmp(buf, "xyz") < 0 ? 1 : 0);
    printf("greater=%d\n", strcmp(buf, "aaa") > 0 ? 1 : 0);
    return 0;
}
