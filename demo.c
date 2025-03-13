#include <stdio.h>
#include "./x86x.h"

extern char **environ;

int
main(int argc, char *argv[])
{
    int window;
    x86x_open_display(environ);
    window = x86x_create_window(100, 100, 0, 0xffffffff);
    x86x_map_window(window);
    for (;;) ;
    return 0;
}
