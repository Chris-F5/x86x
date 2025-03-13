void x86x_open_display(char **environ);
unsigned int x86x_create_window(
    unsigned int width,
    unsigned int height,
    unsigned int background_pixel,
    unsigned int border_pixel
);
void x86x_map_window(unsigned int window_id);
