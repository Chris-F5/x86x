#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <stdlib.h>
#include "./x86x.h"

extern char **environ;

#define VPADDING 4
#define HPADDING 16

char *msg = "Locked";
int quit = 0;
unsigned int wrong_key_press_time;
unsigned int window, gc, pixmap, font;
unsigned short text_extents_ascent, text_extents_descent, text_extents_width;
unsigned char grab_status;

void grab_reply(unsigned char status)
{
    grab_status = status;
}

void key_press_callback(
    unsigned int event_window,
    unsigned char key_code,
    unsigned short state,
    unsigned int time)
{
    if (key_code == 46 && (state & 0x40)) {
        if (time > wrong_key_press_time + 1000 || time < wrong_key_press_time)
            quit = 1;
    } else if (key_code != 133) {
        wrong_key_press_time = time;
    }
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
    x86x_register_callback_key_press_event(key_press_callback);
    x86x_register_callback_text_extents_reply(text_extents_callback);
    x86x_register_callback_grab_keyboard_reply(grab_reply);
    x86x_register_callback_grab_pointer_reply(grab_reply);
    font = x86x_open_font();
    x86x_query_text_extents(font, msg);
    x86x_process_queue(1);

    width = text_extents_width + 2 * HPADDING;
    height = text_extents_descent + text_extents_ascent + 2 * VPADDING;

    x = (x86x_root_width() - width - 2) / 2;
    y = (x86x_root_height() - height - 2) / 2;
    x86x_configure_window_override_redirect(1);
    x86x_configure_window_border_width(1);
     // KeyPress | PointerMotion |  StructureNotify
    window = x86x_create_window(x, y, width, height, 0x01 | 0x40 | 0x20000);
    pixmap = x86x_create_pixmap(window, width, height);
    x86x_map_window(window);

    grab_status = 1;
    for (int i = 0; i < 100 && grab_status; i++) {
        x86x_grab_keyboard(0, window);
        x86x_process_queue(1);
        nanosleep(&ts, NULL);
    }
    if (grab_status) {
        fprintf(stderr, "Failed to grab keyboard.");
        exit(1);
    }

    grab_status = 1;
    for (int i = 0; i < 100 && grab_status; i++) {
        x86x_grab_pointer(0, window);
        x86x_process_queue(1);
        nanosleep(&ts, NULL);
    }
    if (grab_status) {
        fprintf(stderr, "Failed to grab pointer.");
        exit(1);
    }

    gc = x86x_create_gc(window);
    while (!quit) {
        x86x_process_queue(0);
        x86x_change_gc(gc, ~0, ~0);
        x86x_fill_rect(pixmap, gc, 0, 0, width, height);
        x86x_change_gc(gc, 0, 0);
        x86x_draw_text(pixmap, gc, HPADDING, VPADDING + text_extents_ascent, font, msg);
        x86x_copy_area(pixmap, window, gc, 0, 0, 0, 0, width, height);
        nanosleep(&ts, NULL);
    }
    x86x_ungrab_keyboard();
    x86x_ungrab_pointer();
    // TODO: Gracefull exit.
    return 0;
}
