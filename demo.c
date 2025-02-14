#include <stdio.h>
#include "./x86x.h"

int
main(int argc, char *argv[])
{
    long x;
    x = x86x_test();
    printf("%ld\n", x);
    return 0;
}
