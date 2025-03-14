#include <stdio.h>
#include <unistd.h>
#include "./x86x.h"

extern char **environ;

void motion_notify_callback(
    unsigned int event_window,
    unsigned short event_x,
    unsigned short event_y)
{
    printf("%u, %u, %u\n", event_window, event_x, event_y);
    return;
}

int
main(int argc, char *argv[])
{
    int window, gc;
    x86x_open_display(environ);
    window = x86x_create_window(100, 100, ~0, ~0, 0x40 | 0x20000); // PointerMotion |  StructureNotify
    printf("%u\n", window);
    x86x_map_window(window);
    gc = x86x_create_gc(window);
    x86x_change_gc(gc, 0, 0);
    x86x_register_event_callback_motion_notify(motion_notify_callback);
    x86x_draw_line(window, gc, 10, 10, 50, 50);
    for (;;) {
        x86x_handle_events();
    }
    return 0;
}
