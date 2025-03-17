#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include "./x86x.h"

#define WIDTH 500
#define HEIGHT 400

extern char **environ;

unsigned int window, gc, pixmap, font;
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

void text_extents_callback(
    unsigned short ascent,
    unsigned short descent,
    unsigned int width)
{
    printf("%d %d %d\n", ascent, descent, width);
}

int
main(int argc, char *argv[])
{
    unsigned short x, y;
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 2e7L; // 2ms == 50fps.

    x86x_open_display(environ);
    x86x_register_callback_motion_notify_event(motion_notify_callback);
    x86x_register_callback_text_extents_reply(text_extents_callback);
    font = x86x_open_font();
    x86x_query_text_extents(font, "hello world");
    x86x_process_queue(1);
    x = (x86x_root_width() - WIDTH - 2) / 2;
    y = (x86x_root_height() - HEIGHT - 2) / 2;
    x86x_configure_window_override_redirect(1);
    x86x_configure_window_border_width(1);
    window = x86x_create_window(x, y, WIDTH, HEIGHT, 0x40 | 0x20000); // PointerMotion |  StructureNotify
    pixmap = x86x_create_pixmap(window, WIDTH, HEIGHT);
    x86x_map_window(window);
    gc = x86x_create_gc(window);
    for (;;) {
        x86x_process_queue(0);
        x86x_change_gc(gc, ~0, ~0);
        x86x_fill_rect(pixmap, gc, 0, 0, WIDTH, HEIGHT);
        x86x_change_gc(gc, 0, 0);
        x86x_draw_line(pixmap, gc, 50, 50, mouse_x, mouse_y);
        x86x_draw_text(pixmap, gc, 50, 50, font, "hello world");
        x86x_copy_area(pixmap, window, gc, 0, 0, 0, 0, WIDTH, HEIGHT);
        nanosleep(&ts, NULL);
    }
    // TODO: Gracefull exit.
    return 0;
}
