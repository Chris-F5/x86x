#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <stdlib.h>
#include "./x86x.h"

extern char **environ;

char *msg = "Hello World!";
int quit = 0;
unsigned int window, gc, font;


void key_press_callback(
    unsigned int event_window,
    unsigned char key_code,
    unsigned short state,
    unsigned int time)
{
    if (event_window != window)
        return;

    /* If 'q' pressed. */
    if (key_code == 24)
        quit = 1;
}

void expose_callback(
    unsigned int event_window,
    unsigned short x,
    unsigned short y,
    unsigned short width,
    unsigned short height)
{
    if (event_window != window)
        return;
    x86x_change_gc(gc, ~0, ~0);
    x86x_fill_rect(window, gc, 0, 0, width, height);
    x86x_change_gc(gc, 0, 0);
    x86x_draw_text(window, gc, 50, 50, font, msg);
}


int
main(int argc, char *argv[])
{
    x86x_open_display(environ);
    x86x_register_callback_key_press_event(key_press_callback);
    x86x_register_callback_expose_event(expose_callback);

    font = x86x_open_font();
    window = x86x_create_window(0, 0, 100, 100, X86X_KEY_PRESS_MASK | X86X_EXPOSURE_MASK);
    gc = x86x_create_gc(window);

    x86x_map_window(window);

    while (!quit) {
        // TODO: Blocking dequeue.
        // TODO: Close display on window manager exit.
        x86x_process_queue(0);
    }
    x86x_destroy_window(window);
    x86x_close_display();
    return 0;
}
