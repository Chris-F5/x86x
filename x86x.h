void x86x_open_display(char **environ);
unsigned int x86x_create_window(
    unsigned short width,
    unsigned short height,
    unsigned int background_pixel,
    unsigned int border_pixel,
    unsigned int event_mask);
void x86x_map_window(unsigned int window_id);
unsigned int x86x_create_gc(unsigned int drawable);
void x86x_change_gc(
    unsigned int gc,
    unsigned int foreground_pixel,
    unsigned int background_pixel);
void x86x_draw_line(
    unsigned int drawable,
    unsigned int gc,
    unsigned short x0,
    unsigned short y0,
    unsigned short x1,
    unsigned short y1);
void x86x_handle_events(void);
void x86x_register_event_callback_motion_notify(
    void (*callback)(
        unsigned int event_window,
        unsigned short event_x,
        unsigned short event_y)
    );
