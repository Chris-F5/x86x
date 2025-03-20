; System Call Number: rax
; arg1              : rdi
; arg2              : rsi
; arg3              : rdx
; arg4              : r10
; arg5              : r8
; arg6              : r9
; arg7              : -
;
; Ret val           : rax
; Ret val2          : rdx

; x86x.asm
;
; Label naming conventions
; *_p           Pointer.
; *_c           Character.
; *_cstr        Null terminated string.
; *_buf         Buffer that is not null terminated.
; *_len         Length associated with *_buf.
; *_u{b,w,d,q}  Unsigned {byte,word,double,quad} integer.
; *_d{b,w,d,q}  Signed {byte,word,double,quad} integer.
; k_*           Constant data.
; struct_*      Static structure.
; struct_*_len  Length associated with struct_*.
; x86x_*        Global function in x86x.
; _x86x_*        Local function in x86x.
; utils_*       Global function in utils.

%include "macros.asm"

%define READ_BUFFER_SIZE 1024*4

section .data
    k_env_name_display_cstr db "DISPLAY", 0x00
    k_env_name_xauthority_cstr db "XAUTHORITY", 0x00

    k_mit_magic_cookie_name_buf db "MIT-MAGIC-COOKIE-1"
    k_mit_magic_cookie_name_len equ $ - k_mit_magic_cookie_name_buf

struct_xsocket_addr:
    .sa_family_uw dw AF_UNIX
    .sun_path_cstr db "/tmp/.X11-unix/X"
    .display_number_c db "0", 0
struct_xsocket_addr_len equ $ - struct_xsocket_addr

    xauth_cookie_buf dq 0, 0

struct_xcon:
    .socket_dq dq -1
    .resource_id_current_ud dd 0
    .resource_id_base_ud dd 0
    .resource_id_mask_ud dd 0
    .white_pixel_ud dd 0
    .black_pixel_ud dd 0
    .root_window_ud dd 0
    .root_width_uw dw 0
    .root_height_uw dw 0
    .root_depth_ub db 0

struct_pollfd:
    .fd_ud dd 0
    .events dw POLLIN ; events to monitor for.
    .revents dw 0 ; returned events.

query_in_flight_uq dq 0
struct_callbacks:
    .grab_pointer_reply dq 0
    .grab_keyboard_reply dq 0
    .text_extents_reply dq 0
    .key_press_event dq 0
    .motion_notify_event dq 0
    .focus_in_event dq 0

struct_xreq_con_init:
    .byte_order db 0x6c
    db 0x00 ; padding
    .protocol_major_ver db 0x0b, 0x00
    .protocol_minor_ver db 0x00, 0x00
    .auth_protocol_name_len dw 18
    .auth_protocol_data_len dw 16
    db 0x00, 0x00 ; padding
    .auth_protocol_name_cstr db "MIT-MAGIC-COOKIE-1", 0x00, 0x00
    .auth_protocol_data_buf dq 0, 0
struct_xreq_con_init_len equ $ - struct_xreq_con_init

struct_xreq_create_window:
    .opcode db 1
    .depth_ub db 0
    .request_length dw 12 ; measured in 4 byte words
    .wid_ud dd 0
    .parent_window_ud dd 0
    .x_uw dw 0
    .y_uw dw 0
    .width_uw dw 0
    .height_uw dw 0
    .border_width_uw dw 0
    .class dw 0 ; CopyFromParent
    .visual dd 0 ; CopyFromParent
     ; background-pixel | border-pixel | override-redirect | event-mask
     .value_mask dd 0x02 | 0x08 | 0x200 | 0x800
    .values_background_pixel_ud dd 0
    .values_border_pixel_ud dd 0
    .values_override_redirect_ud dd 0
    .values_event_mask_ud dd  0x40 | 0x20000 ; PointerMotion |  StructureNotify
struct_xreq_create_window_len equ $ - struct_xreq_create_window

struct_xreq_map_window:
    .opcode db 8
    db 0 ; padding
    .request_length dw 2
    .window_ud dd 0
struct_xreq_map_window_len equ $ - struct_xreq_map_window

struct_xreq_grab_pointer:
    .opcode db 26
    .owner_events_ub db 0
    .request_length dw 6
    .grab_window_ud dd 0
    .event_mask_uw dw 0x00007ffc ; All mouse events.
    .pointer_mode_ub db 1 ; Asynchronous.
    .keyboard_mode_ub db 1 ; Asynchronous.
    .confine_to_ud dd 0 ; None (window resource id).
    .cursor_ud dd 0 ; None
    .time dd 0 ; CurrentTime.
struct_xreq_grab_pointer_len equ $ - struct_xreq_grab_pointer

struct_xreq_ungrab_pointer:
    .opcode db 27
    db 0
    .request_length dw 2
    .time dd 0 ; CurrentTime.
struct_xreq_ungrab_pointer_len equ $ - struct_xreq_ungrab_pointer

struct_xreq_grab_keyboard:
    .opcode db 31
    .owner_events_ub db 0
    .request_length dw 4
    .grab_window_ud dd 0
    .time dd 0 ; CurrentTime.
    .pointer_mode_ub db 1 ; Asynchronous.
    .keyboard_mode_ub db 1 ; Asynchronous.
    db 0, 0
struct_xreq_grab_keyboard_len equ $ - struct_xreq_grab_keyboard

struct_xreq_ungrab_keyboard:
    .opcode db 32
    db 0
    .request_length dw 2
    .time dd 0 ; CurrentTime.
struct_xreq_ungrab_keyboard_len equ $ - struct_xreq_ungrab_keyboard

struct_xreq_open_font:
    .opcode db 45
    db 0
    .request_length dw 3+2
    .fid_ud dd 0
    .name_length dw 5
    dw 0
    .name db "10x20", 0, 0, 0
struct_xreq_open_font_len equ $ - struct_xreq_open_font

struct_xreq_query_text_extents:
    .opcode db 48
    .odd_length_ub db 0
    .request_length_uw dw 2
    .font_ud dd 0
    .string_buf times 512 db 0

struct_xreq_create_pixmap:
    .opcode db 53
    .depth_ub db 0
    .request_length dw 4
    .pid_ud dd 0 ; New resource id.
    .drawable_ud dd 0
    .width_uw dw 0
    .height_uw dw 0
struct_xreq_create_pixmap_len equ $ - struct_xreq_create_pixmap


struct_xreq_create_gc:
    .opcode db 55
    db 0 ; padding
    .request_length dw 4+2
    .cid_ud dd 0 ; New resource id.
    .drawable_ud dd 0 ; Resource id of drawable (e.g. window, pixmap).
    .value_mask dd 0x4 | 0x8 ; foreground, background
    .values_foreground_ud dd 0
    .values_background_ud dd 0
struct_xreq_create_gc_len equ $ - struct_xreq_create_gc

struct_xreq_change_gc:
    .opcode db 56
    db 0 ; padding
    .request_length dw 3+2
    .gc_ud dd 0 ; set at runtime
    .value_mask dd 0x4 | 0x8 ; foreground, background
    .values_foreground_ud dd 0 ; foreground color
    .values_background_ud dd 0 ; background color
struct_xreq_change_gc_len equ $ - struct_xreq_change_gc

struct_xreq_copy_area:
    .opcode db 62
    db 0
    .request_length dw 7
    .src_drawable_ud dd 0
    .dst_drawable_ud dd 0
    .gc_ud dd 0
    .src_x_uw dw 0
    .src_y_uw dw 0
    .dst_x_uw dw 0
    .dst_y_uw dw 0
    .width_uw dw 0
    .height_uw dw 0
struct_xreq_copy_area_len equ $ - struct_xreq_copy_area

struct_xreq_line:
    .opcode db 65 ; poly line
    .coordinate_mode db 0 ; origin
    .request_length dw 3 + 2
    .drawable_ud dd 0
    .gc_ud dd 0
    .x0_uw dw 0
    .y0_uw dw 0
    .x1_uw dw 0
    .y1_uw dw 0
struct_xreq_line_len equ $ - struct_xreq_line

struct_xreq_fill_rect:
    .opcode db 70 ; Poly fill rect.
    db 0
    .request_length dw 3 + 2
    .drawable_ud dd 0
    .gc_ud dd 0
    .x_uw dw 0
    .y_uw dw 0
    .width_uw dw 0
    .height_uw dw 0
struct_xreq_fill_rect_len equ $ - struct_xreq_fill_rect

struct_xreq_text:
    .opcode db 74 ; PolyText8.
    db 0
    .request_length_uw dw 4
    .drawable_ud dd 0
    .gc_ud dd 0
    .x_uw dw 0
    .y_uw dw 0
    .font_shift_indicator db 255
    .font_bytes db 0, 0, 0, 0
    .string_length_ub db 0
    .delta_ub db 0
    .string_buf times 256 db 0

section .bss
    read_buf resb READ_BUFFER_SIZE

    environ_ptr resq 1

struct_utsname:
    .sysname_cstr resb UTSNAME_LENGTH
    .nodename_cstr resb UTSNAME_LENGTH
    .release_cstr resb UTSNAME_LENGTH
    .version_cstr resb UTSNAME_LENGTH
    .machine_cstr resb UTSNAME_LENGTH
    .domainname_cstr resb UTSDOMAIN_LENGTH

section .text
    extern utils_getenv
    extern utils_strncmp

    global x86x_open_display
    global x86x_root_width
    global x86x_root_height
    global x86x_white_pixel
    global x86x_black_pixel
    global x86x_configure_window_override_redirect
    global x86x_configure_window_colors
    global x86x_configure_window_border_width
    global x86x_create_window
    global x86x_map_window
    global x86x_grab_pointer
    global x86x_ungrab_pointer
    global x86x_grab_keyboard
    global x86x_ungrab_keyboard
    global x86x_open_font
    global x86x_query_text_extents
    global x86x_create_pixmap
    global x86x_create_gc
    global x86x_change_gc
    global x86x_copy_area
    global x86x_draw_line
    global x86x_fill_rect
    global x86x_draw_text
    global x86x_process_queue
    global x86x_register_callback_grab_keyboard_reply
    global x86x_register_callback_grab_pointer_reply
    global x86x_register_callback_text_extents_reply
    global x86x_register_callback_key_press_event
    global x86x_register_callback_motion_notify_event
    global x86x_register_callback_focus_in_event


; Populates struct_xsocket_addr with path to X11 socket associated with DISPLAY
; environment variable.
_x86x_find_xsocket_addr:

    mov rdi, [rel environ_ptr]
    lea rsi, [rel k_env_name_display_cstr]
    call utils_getenv
    cmp rax, 0
    je .err_no_display_environment_variable

    mov r10b, [rax]
    cmp r10b, ':'
    jne .err_unsupported_display
    mov r10b, [rax+1]
    cmp r10b, '0'
    jb .err_unsupported_display
    cmp r10b, '9'
    ja .err_unsupported_display
    mov r10b, [rax+2]
    cmp r10b, 0x00
    jne .err_unsupported_display

    mov r10b, [rax+1]
    mov [rel struct_xsocket_addr.display_number_c], r10b

    ret
.err_no_display_environment_variable:
    DIE "x86x: No DISPLAY environment variable found."
.err_unsupported_display:
    DIE "x86x: Unsupported DISPLAY string."


; Populates struct_xreq_con_init with Xauthority cookie associated with
; struct_xsocket_addr.
_x86x_find_xcookie:
    push rbp
    mov rbp, rsp
    sub rsp, 24

    mov rdi, [rel environ_ptr]
    lea rsi, [rel k_env_name_xauthority_cstr]
    call utils_getenv
    cmp rax, 0
    je .err_no_xauthority_environment_variable

    mov rdi, rax ; Path to Xauthority file.
    mov rax, SYS_OPEN
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .err_failed_to_open_xauth_file
    mov [rbp - 8], rax ; fd

.next_entry:

    mov qword [rbp - 24], 0 ; is entry invalid

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, 4
    syscall
    cmp rax, 0
    je .err_no_matching_xauth_entry
    cmp rax, 4
    jne .err_failed_to_read_xauth_file

    mov rax, 0
    mov ax, [rel read_buf] ; family
    mov ax, [rel read_buf+2] ; address length
    rol ax, 8
    mov [rbp - 16], rax ; address length

    cmp rax, READ_BUFFER_SIZE
    ja .err_read_buffer_overflow

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, [rbp - 16] ; address length
    syscall
    cmp rax, [rbp - 16] ; address length
    jne .err_failed_to_read_xauth_file

    ; TODO: check if the address is local host

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, 2
    syscall
    cmp rax, 2
    jne .err_failed_to_read_xauth_file

    mov rax, 0
    mov ax, [rel read_buf] ; display number length
    rol ax, 8
    mov [rbp - 16], rax ; display number length

    cmp rax, READ_BUFFER_SIZE
    ja .err_read_buffer_overflow

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, [rbp - 16] ; display number length
    syscall
    cmp rax, [rbp - 16] ; display number length
    jne .err_failed_to_read_xauth_file

    mov rax, [rbp - 16] ; display number length
    cmp rax, 1
    je .valid_display_number_length
    mov qword [rbp - 24], 1 ; is entry invalid
.valid_display_number_length:

    mov al, [rel read_buf] ; display number character
    cmp al, [rel struct_xsocket_addr.display_number_c]
    je .correct_display_number
    mov qword [rbp - 24], 1 ; is entry invalid
.correct_display_number:

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, 2
    syscall
    cmp rax, 2
    jne .err_failed_to_read_xauth_file

    mov rax, 0
    mov ax, [rel read_buf] ; name length
    rol ax, 8
    mov [rbp - 16], rax ; name length

    cmp rax, READ_BUFFER_SIZE
    ja .err_read_buffer_overflow

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, [rbp - 16] ; name length
    syscall
    cmp rax, [rbp - 16] ; name length
    jne .err_failed_to_read_xauth_file

    lea rdi, [rel read_buf]
    lea rsi, [rel k_mit_magic_cookie_name_buf]
    mov rdx, k_mit_magic_cookie_name_len
    call utils_strncmp
    cmp rax, 0
    je .correct_name
    mov qword [rbp - 24], 1 ; is entry invalid
.correct_name:

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, 2
    syscall
    cmp rax, 2
    jne .err_failed_to_read_xauth_file

    mov rax, 0
    mov ax, [rel read_buf] ; data length
    rol ax, 8
    mov [rbp - 16], rax ; data length

    cmp rax, READ_BUFFER_SIZE
    ja .err_read_buffer_overflow

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, [rbp - 16] ; data length
    syscall
    cmp rax, [rbp - 16] ; data length
    jne .err_failed_to_read_xauth_file

    mov rax, [rbp - 16] ; data length
    cmp rax, 16
    jne .cookie_length_valid_else
    ; Copy cookie.
    mov rax, [rel read_buf]
    mov [rel struct_xreq_con_init.auth_protocol_data_buf], rax
    mov rax, [rel read_buf + 8]
    mov [rel struct_xreq_con_init.auth_protocol_data_buf + 8], rax
jmp .cookie_length_valid_endif
.cookie_length_valid_else:
    mov qword [rbp - 24], 1 ; is entry invalid
.cookie_length_valid_endif:

    mov rax, [rbp - 24] ; is entry invalid
    cmp rax, 0
    jne .next_entry

    mov rax, SYS_CLOSE
    mov rdi, [rbp - 8] ; fd
    syscall

; Xauth file format: https://gitlab.freedesktop.org/xorg/lib/libxau

    mov rsp, rbp
    pop rbp
    ret
.err_no_xauthority_environment_variable:
    DIE "x86x: No XAUTHORITY environment variable found."
.err_failed_to_open_xauth_file:
    DIE "x86x: Failed to open XAUTHORITY file."
.err_no_matching_xauth_entry:
    DIE "x86x: No matching entry found in XAUTHORITY file."
.err_failed_to_read_xauth_file:
    DIE "x86x: Failed to read XAUTHORITY file."
.err_read_buffer_overflow:
    DIE "x86x: Overflowed read buffer while parsing XAUTHORITY file."


; Connect to struct_xsocket_addr; initialise and authenticate the connection
; with xauth_cookie_buf. Populates struct_xcon.
_x86x_connect:

    mov rax, SYS_SOCKET
    mov rdi, AF_UNIX
    mov rsi, SOCK_STREAM | SOCK_CLOEXEC
    mov rdx, 0
    syscall
    mov [rel struct_xcon.socket_dq], rax

    mov rax, SYS_CONNECT
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xsocket_addr]
    mov rdx, struct_xsocket_addr_len
    syscall

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_con_init]
    mov rdx, struct_xreq_con_init_len
    syscall

    mov rax, SYS_READ
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel read_buf]
    mov rdx, 8
    syscall
    cmp rax, 8
    jne .err_read_failed
    mov al, [rel read_buf] ; status.
    cmp al, 1 ; success.
    jne .err_xconnection_refused

    mov rax, 0
    mov ax, [rel read_buf + 6] ; Additional data length (4-byte units).
    mov rbx, 4
    mul rbx

    cmp rax, READ_BUFFER_SIZE
    ja .err_read_buffer_overflow

    mov rdx, rax
    push rdx ; additional data length
    mov rax, SYS_READ
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel read_buf]
    syscall
    pop rdx ; additional data length
    cmp rax, rdx
    jne .err_read_failed

    mov eax, [rel read_buf + 4] ; resource-id-base.
    mov [rel struct_xcon.resource_id_base_ud], eax
    mov [rel struct_xcon.resource_id_current_ud], eax

    mov eax, [rel read_buf + 8] ; resource-id mask.
    mov [rel struct_xcon.resource_id_mask_ud], eax

    mov rbx, 0
    mov bx, [rel read_buf + 16] ; length of vendor
    ; round up vendor length to multiple of 4 (for alignment)
    add bx, 3
    and bx, 0xfffc
    add bx, 32 ; bx = offset to FORMAT list

    mov ax, 0
    mov al, [rel read_buf + 21] ; number of formats.
    mov cx, 8
    mul cx ; ax = xcon_format_count * 8
    add bx, ax ; bx = offset to SCREEN list
    lea rax, [rel read_buf]
    add rbx, rax ; rbx = address of SCREEN list

    mov eax, [rbx] ; root window.
    mov [rel struct_xcon.root_window_ud], eax
    mov eax, [rbx + 8] ; white pixel.
    mov [rel struct_xcon.white_pixel_ud], eax
    mov [rel struct_xreq_create_window.values_background_pixel_ud], eax
    mov eax, [rbx + 12] ; black pixel.
    mov [rel struct_xcon.black_pixel_ud], eax
    mov [rel struct_xreq_create_window.values_border_pixel_ud], eax
    mov ax, [rbx + 20] ; root width
    mov [rel struct_xcon.root_width_uw], ax
    mov ax, [rbx + 22] ; root height
    mov [rel struct_xcon.root_height_uw], ax
    mov al, [rbx + 38] ; root depth.
    mov [rel struct_xcon.root_depth_ub], al

    ret
.err_xconnection_refused:
    DIE "x86x: X11 server refused connection."
.err_read_failed:
    DIE "x86x: Read failed while connecting to X11 server."
.err_read_buffer_overflow:
    DIE "x86x: Overflowed read buffer while connecting to X11 server."

; @return Fresh resource id.
_x86x_allocate_resource_id:

    mov rax, 0
    mov eax, [rel struct_xcon.resource_id_current_ud]
    add eax, 1
    mov [rel struct_xcon.resource_id_current_ud], eax

    ret


; @param rdi Environment environ pointer. Found on stack when process starts.
x86x_open_display:

    mov [rel environ_ptr], rdi

    call _x86x_find_xsocket_addr
    call _x86x_find_xcookie
    call _x86x_connect

    ret

; @return Root window width in pixels.
x86x_root_width:
    mov rax, 0
    mov ax, [rel struct_xcon.root_width_uw]
    ret


; @return Root window height in pixels.
x86x_root_height:
    mov rax, 0
    mov ax, [rel struct_xcon.root_height_uw]
    ret


; @return White pixel color.
x86x_white_pixel:
    mov rax, 0
    mov eax, [rel struct_xcon.white_pixel_ud]
    ret


; @return Black pixel color.
x86x_black_pixel:
    mov rax, 0
    mov eax, [rel struct_xcon.black_pixel_ud]
    ret


; @param edi Override redirect (boolean).
x86x_configure_window_override_redirect:
    mov [rel struct_xreq_create_window.values_override_redirect_ud], edi
    ret


; @param edi Background pixel color.
; @param esi Border pixel color.
x86x_configure_window_colors:
    mov [rel struct_xreq_create_window.values_background_pixel_ud], edi
    mov [rel struct_xreq_create_window.values_border_pixel_ud], esi
    ret

; @param di Border width.
x86x_configure_window_border_width:
    mov [rel struct_xreq_create_window.border_width_uw], di
    ret

; @param di X.
; @param si Y.
; @param dx Width.
; @param cx Height.
; @param r8d Event mask
; @return Window resource id.
x86x_create_window:

    mov [rel struct_xreq_create_window.x_uw], di
    mov [rel struct_xreq_create_window.y_uw], si
    mov [rel struct_xreq_create_window.width_uw], dx
    mov [rel struct_xreq_create_window.height_uw], cx
    mov [rel struct_xreq_create_window.values_event_mask_ud], r8d

    call _x86x_allocate_resource_id
    mov [rel struct_xreq_create_window.wid_ud], eax
    push rax
    mov eax, [rel struct_xcon.root_window_ud]
    mov [rel struct_xreq_create_window.parent_window_ud], eax

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_create_window]
    mov rdx, struct_xreq_create_window_len
    syscall

    pop rax
    ret


; @param edi Window id.
x86x_map_window:

    mov [rel struct_xreq_map_window.window_ud], edi

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_map_window]
    mov rdx, struct_xreq_map_window_len
    syscall

    ret


; @param dil Owner events (boolean).
; @param esi Window resource id.
x86x_grab_pointer:

    mov rax, [rel query_in_flight_uq]
    cmp rax, 0
    jne .err_query_already_in_flight
    mov rax, 26 ; Query grab pointer.
    mov [rel query_in_flight_uq], rax

    mov [rel struct_xreq_grab_pointer.owner_events_ub], dil
    mov [rel struct_xreq_grab_pointer.grab_window_ud], esi

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_grab_pointer]
    mov rdx, struct_xreq_grab_pointer_len
    syscall

    ret
.err_query_already_in_flight:
    DIE "x86x: Can't have multiple queries in-flight."


x86x_ungrab_pointer:

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_ungrab_pointer]
    mov rdx, struct_xreq_ungrab_pointer_len
    syscall

    ret


; @param dil Owner events (boolean).
; @param esi Window resource id.
x86x_grab_keyboard:

    mov rax, [rel query_in_flight_uq]
    cmp rax, 0
    jne .err_query_already_in_flight
    mov rax, 31 ; Query grab keyboard.
    mov [rel query_in_flight_uq], rax

    mov [rel struct_xreq_grab_keyboard.owner_events_ub], dil
    mov [rel struct_xreq_grab_keyboard.grab_window_ud], esi

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_grab_keyboard]
    mov rdx, struct_xreq_grab_keyboard_len
    syscall

    ret
.err_query_already_in_flight:
    DIE "x86x: Can't have multiple queries in-flight."


x86x_ungrab_keyboard:

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_ungrab_keyboard]
    mov rdx, struct_xreq_ungrab_keyboard_len
    syscall

    ret


; @return Font resource id.
x86x_open_font:

    call _x86x_allocate_resource_id
    mov [rel struct_xreq_open_font.fid_ud],  eax
    push rax

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_open_font]
    mov rdx, struct_xreq_open_font_len
    syscall

    pop rax
    ret


; @param edi Fontable resource id.
; @param rsi ASCII cstring pointer (256 max length).
x86x_query_text_extents:

    mov rax, [rel query_in_flight_uq]
    cmp rax, 0
    jne .err_query_already_in_flight
    mov rax, 48 ; Query text extents.
    mov [rel query_in_flight_uq], rax

    mov [rel struct_xreq_query_text_extents.font_ud], edi

    lea rbx, [rel struct_xreq_query_text_extents.string_buf]
    mov rcx, 0
.char_loop:
    mov al, [rsi]
    cmp al, 0
    je .char_loop_break

    cmp rcx, 256
    jae .err_string_too_long

    mov byte [rbx], 0
    mov [rbx+1], al

    add rsi, 1
    add rbx, 2
    add rcx, 1
    jmp .char_loop
.char_loop_break:

    mov rbx, rcx
    and rbx, 1
    mov [rel struct_xreq_query_text_extents.odd_length_ub], bl

    add rcx, 1
    shr rcx, 1
    add rcx, 2
    mov [rel struct_xreq_query_text_extents.request_length_uw], cx
    shl rcx, 2

    mov rdx, rcx
    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_query_text_extents]
    syscall

    ret
.err_query_already_in_flight:
    DIE "x86x: Can't have multiple queries in-flight."
.err_string_too_long:
    DIE "x86x: String too long in query text extents call."


; @param edi Drawable resource id.
; @param si Width.
; @param dx Height.
; @return New pixmap resource id.
x86x_create_pixmap:

    mov [rel struct_xreq_create_pixmap.drawable_ud], edi
    mov [rel struct_xreq_create_pixmap.width_uw], si
    mov [rel struct_xreq_create_pixmap.height_uw], dx

    mov al, [rel struct_xcon.root_depth_ub]
    mov [rel struct_xreq_create_pixmap.depth_ub], al

    call _x86x_allocate_resource_id
    mov [rel struct_xreq_create_pixmap.pid_ud], eax
    push rax

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_create_pixmap]
    mov rdx, struct_xreq_create_pixmap_len
    syscall

    pop rax
    ret


; @param edi Drawable resource id.
; @return Graphics context resource id.
x86x_create_gc:

    mov [rel struct_xreq_create_gc.drawable_ud], edi

    call _x86x_allocate_resource_id
    mov [rel struct_xreq_create_gc.cid_ud], eax
    push rax

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_create_gc]
    mov rdx, struct_xreq_create_gc_len
    syscall

    pop rax
    ret

; @param edi Graphics context resource id.
; @param esi Foreground color.
; @param edx Background color.
x86x_change_gc:

    mov [rel struct_xreq_change_gc.gc_ud], edi
    mov [rel struct_xreq_change_gc.values_foreground_ud], esi
    mov [rel struct_xreq_change_gc.values_background_ud], edi

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_change_gc]
    mov rdx, struct_xreq_change_gc_len
    syscall

    ret


; @param edi Source drawable resource id.
; @param esi Destination drawable resource id.
; @param edx Graphics context resource id.
; @param cx Source x.
; @param r8w Source y.
; @param r9w Destination x.
; @param [rsp + 8] word Destination y.
; @param [rsp + 16] word Width.
; @param [rsp + 24] word Height.
x86x_copy_area:

    mov [rel struct_xreq_copy_area.src_drawable_ud], edi
    mov [rel struct_xreq_copy_area.dst_drawable_ud], esi
    mov [rel struct_xreq_copy_area.gc_ud], edx
    mov [rel struct_xreq_copy_area.src_x_uw], cx
    mov [rel struct_xreq_copy_area.src_y_uw], r8w
    mov [rel struct_xreq_copy_area.dst_x_uw], r9w
    mov ax, [rsp + 8]
    mov [rel struct_xreq_copy_area.dst_y_uw], ax
    mov ax, [rsp + 16]
    mov [rel struct_xreq_copy_area.width_uw], ax
    mov ax, [rsp + 24]
    mov [rel struct_xreq_copy_area.height_uw], ax


    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_copy_area]
    mov rdx, struct_xreq_copy_area_len
    syscall

    ret


; @param edi Drawable resource id.
; @param esi Graphics context resource id.
; @param dx x0.
; @param cx y0.
; @param r8w x1.
; @param r9w y1.
x86x_draw_line:

    mov [rel struct_xreq_line.drawable_ud], edi
    mov [rel struct_xreq_line.gc_ud], esi
    mov [rel struct_xreq_line.x0_uw], dx
    mov [rel struct_xreq_line.y0_uw], cx
    mov [rel struct_xreq_line.x1_uw], r8w
    mov [rel struct_xreq_line.y1_uw], r9w

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_line]
    mov rdx, struct_xreq_line_len
    syscall

    ret


; @param edi Drawable resource id.
; @param esi Graphics context resource id.
; @param dx x.
; @param cx y.
; @param r8w width.
; @param r9w height.
x86x_fill_rect:

    mov [rel struct_xreq_fill_rect.drawable_ud], edi
    mov [rel struct_xreq_fill_rect.gc_ud], esi
    mov [rel struct_xreq_fill_rect.x_uw], dx
    mov [rel struct_xreq_fill_rect.y_uw], cx
    mov [rel struct_xreq_fill_rect.width_uw], r8w
    mov [rel struct_xreq_fill_rect.height_uw], r9w

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_fill_rect]
    mov rdx, struct_xreq_fill_rect_len
    syscall

    ret

; @param edi Drawable resource id.
; @param esi Graphics context resource id.
; @param dx x.
; @param cx y.
; @param r8d Font resource id.
; @param r9 Text cstring.
x86x_draw_text:

    mov [rel struct_xreq_text.drawable_ud], edi
    mov [rel struct_xreq_text.gc_ud], esi
    mov [rel struct_xreq_text.x_uw], dx
    mov [rel struct_xreq_text.y_uw], cx
    mov [rel struct_xreq_text.font_bytes+3], r8b
    shr r8d, 8
    mov [rel struct_xreq_text.font_bytes+2], r8b
    shr r8d, 8
    mov [rel struct_xreq_text.font_bytes+1], r8b
    shr r8d, 8
    mov [rel struct_xreq_text.font_bytes+0], r8b

    lea rbx, [rel struct_xreq_text.string_buf]
    mov rcx, 0
.char_loop:
    mov al, [r9]
    cmp al, 0
    je .char_loop_break

    cmp rcx, 255
    jae .err_string_too_long

    mov [rbx], al

    add r9, 1
    add rbx, 1
    add rcx, 1
    jmp .char_loop
.char_loop_break:

    mov [rel struct_xreq_text.string_length_ub], cl
    add rcx, 16 ; Packet header size.
    add rcx, 5 ; Font entry.
    add rcx, 2 ; Text entry header.
    add rcx, 3 ; Padding.
    shr rcx, 2
    mov [rel struct_xreq_text.request_length_uw], cx
    shl rcx, 2

    mov rdx, rcx
    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_text]
    syscall

    ret
.err_string_too_long:
    DIE "x86x: String too long in draw text call."


; Read all X11 events and replies received from the server since the last
; time this function was called and invoke the appropriate callbacks. If block
; until reply is non-zero then dont return until the queue is empty and at
; least one reply was processed.
;
; @param rdi Block until reply (boolean).
x86x_process_queue:
    push rbp
    mov rbp, rsp

    cmp rdi, 0
    je .timeout_else
    mov rax, 1000
    jmp .timeout_endif
.timeout_else:
    mov rax, 0
.timeout_endif:
    push rax ; Poll timeout milliseconds.

    mov rax, [rel struct_xcon.socket_dq]
    mov [rel struct_pollfd.fd_ud], eax


.loop:
    mov rax, SYS_POLL
    lea rdi, [rel struct_pollfd]
    mov rsi, 1 ; number of fds.
    mov rdx, [rbp - 8] ; timeout.
    syscall
    ; TODO: assert rax >= 0
    mov rbx, rax
    or rbx, [rbp - 8] ; timeout
    cmp rbx, 0
    je .break ; Break if queue is empty and we are not blocking.
    cmp rax, 0
    je .loop  ; Repoll if the queue is empty and we are blocking.

    ; TODO: exit if POLLHUP in revents.

    mov rax, SYS_READ
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel read_buf]
    mov rdx, 32 ; XEvents are always 32 bytes long.
    syscall
    cmp rax, 32
    jne .err_read_failed

    ; TODO: handle X11 errors (event code 0).

    mov al, [rel read_buf] ; Error/Reply/Event code.
    cmp al, 1 ; Reply.
    jne .reply_endif

    mov rax, 0
    mov [rbp - 8], rax ; timeout. Stop blocking now we have found a reply.

    mov rdx, 0
    mov edx, [rel read_buf + 4] ; Reply additional bytes.
    cmp rdx, 0
    je .no_additional_bytes
    mov rax, SYS_READ
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel read_buf]
    add rsi, 32
    syscall
    cmp eax, [rel read_buf + 4] ; Reply additional bytes.
    jne .err_read_failed
.no_additional_bytes:

    mov rax, [rel query_in_flight_uq]
    mov rbx, 31 ; Grab keyboard.
    cmp rax, rbx
    jne .grab_keyboard_reply_endif
    mov rdi, 0
    mov dil, [rel read_buf + 1] ; Status.
    mov rax, [rel struct_callbacks.grab_keyboard_reply]
    cmp rax, 0
    je .reply_parsed
    call rax
    jmp .reply_parsed
.grab_keyboard_reply_endif:

    mov rax, [rel query_in_flight_uq]
    mov rbx, 26 ; Grab pointer.
    cmp rax, rbx
    jne .grab_pointer_reply_endif
    mov rdi, 0
    mov dil, [rel read_buf + 1] ; Status.
    mov rax, [rel struct_callbacks.grab_pointer_reply]
    cmp rax, 0
    je .reply_parsed
    call rax
    jmp .reply_parsed
.grab_pointer_reply_endif:

    mov rax, [rel query_in_flight_uq]
    mov rbx, 48 ; Query text extents.
    cmp rax, rbx
    jne .text_extents_reply_endif
    mov rdi, 0
    mov di, [rel read_buf + 8] ; Font ascent.
    mov rsi, 0
    mov si, [rel read_buf + 10] ; Font descet.
    mov rdx, 0
    mov edx, [rel read_buf + 16] ; Width.
    mov rax, [rel struct_callbacks.text_extents_reply]
    cmp rax, 0
    je .reply_parsed
    call rax
    jmp .reply_parsed
.text_extents_reply_endif:

    jmp .err_unexpected_reply
.reply_parsed:
    mov rax, 0
    mov [rel query_in_flight_uq], rax
.reply_endif:

    mov al, [rel read_buf] ; Error/Reply/Event code.
    cmp al, 2 ; KeyPress.
    jne .key_press_endif
    mov rax, [rel struct_callbacks.key_press_event]
    cmp rax, 0
    je .key_press_endif
    mov rdi, 0
    mov rsi, 0
    mov rdx, 0
    mov rcx, 0
    mov edi, [rel read_buf + 12] ; event window.
    mov sil, [rel read_buf + 1] ; key code.
    mov dx, [rel read_buf + 28] ; state.
    mov ecx, [rel read_buf + 4] ; time.
    call rax
.key_press_endif:

    mov al, [rel read_buf] ; Error/Reply/Event code.
    cmp al, 6 ; motion notify.
    jne .motion_notify_endif
    mov rax, [rel struct_callbacks.motion_notify_event]
    cmp rax, 0
    je .motion_notify_endif
    mov rdi, 0
    mov rsi, 0
    mov rdx, 0
    mov edi, [rel read_buf + 12] ; event window.
    mov si, [rel read_buf + 24] ; event x.
    mov dx, [rel read_buf + 26] ; event y.
    call rax
.motion_notify_endif:

    mov al, [rel read_buf] ; Error/Reply/Event code.
    cmp al, 9 ; FocusIn.
    jne .focus_in_endif
    mov rax, [rel struct_callbacks.focus_in_event]
    cmp rax, 0
    je .focus_in_endif
    mov rdi, 0
    mov rsi, 0
    mov rdx, 0
    mov edi, [rel read_buf + 4] ; event window.
    mov sil, [rel read_buf + 1] ; detail.
    mov dl, [rel read_buf + 8] ; mode.
    call rax
.focus_in_endif:

    jmp .loop
.break:

    mov rsp, rbp
    pop rbp
    ret
.err_unexpected_reply:
    DIE "x86x: Unexpected reply while processing queue."
.err_read_failed:
    DIE "x86x: X11 socket read failed while processing queue."


; @param rdi void (*callback)(unsigned char status);
x86x_register_callback_grab_pointer_reply:
    mov [rel struct_callbacks.grab_pointer_reply], rdi
    ret


; @param rdi void (*callback)(unsigned char status);
x86x_register_callback_grab_keyboard_reply:
    mov [rel struct_callbacks.grab_keyboard_reply], rdi
    ret


; @param rdi void (*callback)(
;                unsigned short ascent,
;                unsigned short descent,
;                unsigned int width).
x86x_register_callback_text_extents_reply:
    mov [rel struct_callbacks.text_extents_reply], rdi
    ret

; @param rdi void (*callback)(
;                unsigned int event_window,
;                unsigned byte keycode,
;                unsigned short state,
;                unsigned int time).
x86x_register_callback_key_press_event:
    mov [rel struct_callbacks.key_press_event], rdi
    ret

; @param rdi void (*callback)(
;                unsigned int event_window,
;                unsigned short event_x,
;                unsigned short event_y).
x86x_register_callback_motion_notify_event:
    mov [rel struct_callbacks.motion_notify_event], rdi
    ret

    mov edi, [rel read_buf + 4] ; event window.
    mov sil, [rel read_buf + 1] ; detail.
    mov dl, [rel read_buf + 8] ; mode.

; @param rdi void (*callback)(
;                unsigned int event_window,
;                unsigned char detail,
;                unsigned char mode).
x86x_register_callback_focus_in_event:
    mov [rel struct_callbacks.focus_in_event], rdi
    ret
