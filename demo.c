#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include "./x86x.h"

extern char **environ;

#define VPADDING 4
#define HPADDING 16

char *msg = "Locked";
unsigned int window, gc, pixmap, font;
unsigned short mouse_x, mouse_y;
unsigned short text_extents_ascent, text_extents_descent, text_extents_width;

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
    text_extents_ascent = ascent;
    text_extents_descent = descent;
    text_extents_width = width;
}

int
main(int argc, char *argv[])
{
    unsigned short x, y, width, height;
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 2e7L; // 2ms == 50fps.

    x86x_open_display(environ);
    x86x_register_callback_motion_notify_event(motion_notify_callback);
    x86x_register_callback_text_extents_reply(text_extents_callback);
    font = x86x_open_font();
    x86x_query_text_extents(font, msg);
    x86x_process_queue(1);

    width = text_extents_width + 2 * HPADDING;
    height = text_extents_descent + text_extents_ascent + 2 * VPADDING;

    x = (x86x_root_width() - width - 2) / 2;
    y = (x86x_root_height() - height - 2) / 2;
    x86x_configure_window_override_redirect(1);
    x86x_configure_window_border_width(1);
    window = x86x_create_window(x, y, width, height, 0x40 | 0x20000); // PointerMotion |  StructureNotify
    pixmap = x86x_create_pixmap(window, width, height);
    x86x_map_window(window);

    x86x_grab_keyboard(1, window);
    x86x_process_queue(1);
    x86x_grab_pointer(1, window);
    x86x_process_queue(1);
    // TODO: verify grab success.

    gc = x86x_create_gc(window);
    for (int i = 0; i < 100; i++) {
        x86x_process_queue(0);
        x86x_change_gc(gc, ~0, ~0);
        x86x_fill_rect(pixmap, gc, 0, 0, width, height);
        x86x_change_gc(gc, 0, 0);
        x86x_draw_line(pixmap, gc, 0, 0, mouse_x, mouse_y);
        x86x_draw_text(pixmap, gc, HPADDING, VPADDING + text_extents_ascent, font, msg);
        x86x_copy_area(pixmap, window, gc, 0, 0, 0, 0, width, height);
        nanosleep(&ts, NULL);
    }
    x86x_ungrab_keyboard();
    x86x_ungrab_pointer();
    // TODO: Gracefull exit.
    return 0;
}
