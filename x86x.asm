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
    .root_window_ud dd 0
    .root_depth_ub db 0

struct_pollfd:
    .fd_ud dd 0
    .events dw POLLIN ; events to monitor for.
    .revents dw 0 ; returned events.

struct_xevent_callbacks:
    .motion_notify dq 0

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
    .request_length dw 11 ; measured in 4 byte words
    .wid_ud dd 0
    .parent_window_ud dd 0
    .x_uw dw 0
    .y_uw dw 0
    .width_uw dw 0
    .height_uw dw 0
    .border_width_uw dw 0
    .class dw 0 ; CopyFromParent
    .visual dd 0 ; CopyFromParent
    .value_mask dd 0x02 | 0x08 | 0x800 ; background-pixel | border-pixel | event-mask
    .values_background_pixel_ud dd 0
    .values_border_pixel_ud dd 0
    .values_event_mask_ud dd  0x40 | 0x20000 ; PointerMotion |  StructureNotify
struct_xreq_create_window_len equ $ - struct_xreq_create_window

struct_xreq_map_window:
    .opcode db 8
    db 0 ; padding
    .request_length dw 2
    .window_ud dd 0
struct_xreq_map_window_len equ $ - struct_xreq_map_window

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

struct_xreq_line:
    .opcode db 65 ; poly line
    .coordinate_mode db 0 ; origin
    .request_length dw 3+2
    .drawable_ud dd 0
    .gc_ud dd 0
    .x0_uw dw 0
    .y0_uw dw 0
    .x1_uw dw 0
    .y1_uw dw 0
struct_xreq_line_len equ $ - struct_xreq_line

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
    global x86x_open_display
    global x86x_create_window
    global x86x_map_window
    global x86x_create_gc
    global x86x_change_gc
    global x86x_draw_line
    global x86x_handle_events
    global x86x_register_event_callback_motion_notify
    extern utils_getenv


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

    ; TODO: check length does not overflow buffer.

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

    ; TODO: check length does not overflow buffer.

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

    ; TODO: check length does not overflow buffer.

    mov rax, SYS_READ
    mov rdi, [rbp - 8] ; fd
    lea rsi, [rel read_buf]
    mov rdx, [rbp - 16] ; name length
    syscall
    cmp rax, [rbp - 16] ; name length
    jne .err_failed_to_read_xauth_file

    ; TODO: utils_strncmp name with MIT-MAGIC-COOKIE-1

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

    ; TODO: check length does not overflow buffer.

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


; Connect to struct_xsocket_addr; initialise and authenticate the connection
; with xauth_cookie_buf. Populates struct_xcon.
_x86x_connect:

    mov rax, SYS_SOCKET
    mov rdi, AF_UNIX
    mov rsi, SOCK_STREAM | SOCK_CLOEXEC
    mov rdx, 0
    syscall
    mov [rel struct_xcon.socket_dq], rax
    ; TODO: assert rax >= 0

    mov rax, SYS_CONNECT
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xsocket_addr]
    mov rdx, struct_xsocket_addr_len
    syscall
    ; TODO: assert rax >= 0

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_con_init]
    mov rdx, struct_xreq_con_init_len
    syscall
    ; TODO: assert rax >= 0

    mov rax, SYS_READ
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel read_buf]
    mov rdx, 8
    syscall
    ; TODO: assert rax == 8
    mov al, [rel read_buf] ; status.
    cmp al, 1 ; success.
    jne .err_xconnection_refused

    mov rax, 0
    mov ax, [rel read_buf + 6] ; Additional data length (4-byte units).
    mov rbx, 4
    mul rbx

    ; TODO: check additional data does not overflow buffer.

    mov rdx, rax
    mov rax, SYS_READ
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel read_buf]
    syscall
    ; TODO: assert rax == additional data length

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
    mov al, [rbx + 38] ; root depth.
    mov [rel struct_xcon.root_depth_ub], al

    ret
.err_xconnection_refused:
    DIE "x86x: X11 server refused connection."


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

; @param di Width.
; @param si Height.
; @param edx Background pixel color.
; @param ecx Border pixel color.
; @param r8d Event mask.
; @return Window resource id.
x86x_create_window:

    mov [rel struct_xreq_create_window.width_uw], di
    mov [rel struct_xreq_create_window.height_uw], si
    mov [rel struct_xreq_create_window.values_background_pixel_ud], edx
    mov [rel struct_xreq_create_window.values_border_pixel_ud], ecx
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
    ; TODO: assert rax >= 0

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
    ; TODO: assert rax >= 0

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
    ; TODO: assert rax >= 0

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
    ; TODO: assert rax >= 0

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
    mov word [rel struct_xreq_line.x0_uw], dx
    mov word [rel struct_xreq_line.y0_uw], cx
    mov word [rel struct_xreq_line.x1_uw], r8w
    mov word [rel struct_xreq_line.y1_uw], r9w

    mov rax, SYS_WRITE
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel struct_xreq_line]
    mov rdx, struct_xreq_line_len
    syscall
    ; TODO: assert rax >= 0

    ret


; Read all X11 events received from the server since the last time this function
; was called and invoke the appropriate event callbacks.
x86x_handle_events:
.next_event:

    mov rax, [rel struct_xcon.socket_dq]
    mov [rel struct_pollfd.fd_ud], eax

    mov rax, SYS_POLL
    lea rdi, [rel struct_pollfd]
    mov rsi, 1 ; number of fds.
    mov rdx, 0 ; timeout.
    syscall
    ; TODO: assert rax >= 0
    cmp rax, 0
    je .no_events_remain

    ; TODO: exit if POLLHUP in revents.

    mov rax, SYS_READ
    mov rdi, [rel struct_xcon.socket_dq]
    lea rsi, [rel read_buf]
    mov rdx, 32 ; XEvents are always 32 bytes long.
    syscall
    ; TODO: assert rax == 32.

    ; TODO: handle X11 errors (event code 0).

    mov al, [rel read_buf] ; event code.
    cmp al, 6 ; motion notify.
    jne .motion_notify_endif
    mov rax, [rel struct_xevent_callbacks.motion_notify]
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

    jmp .next_event
.no_events_remain:
    ret


; @param rdi void (*callback)(
;                unsigned int event_window,
;                unsigned short event_x,
;                unsigned short event_y).
x86x_register_event_callback_motion_notify:
    mov [rel struct_xevent_callbacks.motion_notify], rdi
    ret
