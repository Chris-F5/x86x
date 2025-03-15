void x86x_open_display(char **environ);
void x86x_configure_window_override_redirect(unsigned int enable);
void x86x_configure_window_colors(
    unsigned int background_color,
    unsigned int border_color);
void x86x_configure_window_border_width(unsigned int border_width);
unsigned int x86x_create_window(
    unsigned short x,
    unsigned short y,
    unsigned short width,
    unsigned short height,
    unsigned int event_mask);
void x86x_map_window(unsigned int window_id);
unsigned int x86x_create_pixmap(
    unsigned int drawable,
    unsigned short width,
    unsigned short height);
unsigned int x86x_create_gc(unsigned int drawable);
void x86x_change_gc(
    unsigned int gc,
    unsigned int foreground_pixel,
    unsigned int background_pixel);
void x86x_copy_area(
    unsigned int src_drawable,
    unsigned int dst_drawable,
    unsigned int gc,
    unsigned short src_x,
    unsigned short src_y,
    unsigned short dst_x,
    unsigned short dst_y,
    unsigned short width,
    unsigned short height);
void x86x_draw_line(
    unsigned int drawable,
    unsigned int gc,
    unsigned short x0,
    unsigned short y0,
    unsigned short x1,
    unsigned short y1);
void x86x_fill_rect(
    unsigned int drawable,
    unsigned int gc,
    unsigned short x,
    unsigned short y,
    unsigned short width,
    unsigned short height);
void x86x_handle_events(void);
void x86x_register_event_callback_motion_notify(
    void (*callback)(
        unsigned int event_window,
        unsigned short event_x,
        unsigned short event_y)
    );
