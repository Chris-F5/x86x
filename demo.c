#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include "./x86x.h"

#define WIDTH 500
#define HEIGHT 400

extern char **environ;

unsigned int window, gc, pixmap;
unsigned short mouse_x, mouse_y;

void motion_notify_callback(
    unsigned int event_window,
    unsigned short event_x,
    unsigned short event_y)
{
    if (event_window == window) {
        mouse_x = event_x;
        mouse_y = event_y;
    }
    return;
}

int
main(int argc, char *argv[])
{
    unsigned short x, y;
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 2e7L; // 2ms == 50fps.

    x86x_open_display(environ);
    x = (x86x_root_width() - WIDTH - 2) / 2;
    y = (x86x_root_height() - HEIGHT - 2) / 2;
    x86x_configure_window_override_redirect(1);
    x86x_configure_window_border_width(1);
    window = x86x_create_window(x, y, WIDTH, HEIGHT, 0x40 | 0x20000); // PointerMotion |  StructureNotify
    pixmap = x86x_create_pixmap(window, WIDTH, HEIGHT);
    x86x_map_window(window);
    gc = x86x_create_gc(window);
    x86x_register_event_callback_motion_notify(motion_notify_callback);
    for (;;) {
        x86x_handle_events();
        x86x_change_gc(gc, ~0, ~0);
        x86x_fill_rect(pixmap, gc, 0, 0, WIDTH, HEIGHT);
        x86x_change_gc(gc, 0, 0);
        x86x_draw_line(pixmap, gc, 50, 50, mouse_x, mouse_y);
        x86x_copy_area(pixmap, window, gc, 0, 0, 0, 0, WIDTH, HEIGHT);
        nanosleep(&ts, NULL);
    }
    return 0;
}
