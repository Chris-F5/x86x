#define X86X_KEY_PRESS_MASK      0x00000001
#define X86X_POINTER_MOTION_MASK 0x00000040
#define X86X_EXPOSURE_MASK       0x00008000

void x86x_open_display(char **environ);
unsigned short x86x_root_width(void);
unsigned short x86x_root_height(void);
unsigned int x86x_white_pixel(void);
unsigned int x86x_black_pixel(void);
void x86x_configure_window_override_redirect(unsigned int enable);
void x86x_configure_window_colors(
    unsigned int background_color,
    unsigned int border_color);
void x86x_configure_window_border_width(unsigned short border_width);
unsigned int x86x_create_window(
    unsigned short x,
    unsigned short y,
    unsigned short width,
    unsigned short height,
    unsigned int event_mask);
void x86x_map_window(unsigned int window_id);
void x86x_grab_pointer(unsigned char owner_events, unsigned int window_id);
void x86x_ungrab_pointer();
void x86x_grab_keyboard(unsigned char owner_events, unsigned int window_id);
void x86x_ungrab_keyboard();
unsigned int x86x_open_font(void);
void x86x_query_text_extents(unsigned int fontable, char *text);
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
void x86x_draw_text(
    unsigned int drawable,
    unsigned int gc,
    unsigned short x,
    unsigned short y,
    unsigned int font,
    char *text);
void x86x_process_queue(unsigned int block_until_reply);
void x86x_register_callback_grab_pointer_reply(
    void (*callback)(unsigned char status)
    );
void x86x_register_callback_grab_keyboard_reply(
    void (*callback)(unsigned char status)
    );
void x86x_register_callback_text_extents_reply(
    void (*callback)(
        unsigned short ascent,
        unsigned short descent,
        unsigned int width)
    );
void x86x_register_callback_key_press_event(
    void (*callback)(
        unsigned int event_window,
        unsigned char key_code,
        unsigned short state,
        unsigned int time)
    );
void x86x_register_callback_motion_notify_event(
    void (*callback)(
        unsigned int event_window,
        unsigned short event_x,
        unsigned short event_y)
    );
void x86x_register_callback_focus_in_event(
    void (*callback)(
        unsigned int event_window,
        unsigned char detail,
        unsigned char mode)
    );
void x86x_register_callback_expose_event(
    void (*callback)(
        unsigned int event_window,
        unsigned short x,
        unsigned short y,
        unsigned short width,
        unsigned short height)
    );
