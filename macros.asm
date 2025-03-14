; SYSTEM CALLS

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_FSTAT 5
%define SYS_POLL 7
%define SYS_MMAP 9
%define SYS_NANOSLEEP 35
%define SYS_SOCKET 41
%define SYS_CONNECT 42
%define SYS_ACCEPT 43
%define SYS_BIND 49
%define SYS_LISTEN 50
%define SYS_SETSOCKOPT 54
%define SYS_EXIT 60
%define SYS_UNAME 63


; SYSTEM CONSTANTS

%define FD_STDIN 0
%define FD_STDOUT 1
%define FD_STDERR 2

%define O_RDONLY 0
%define O_WRONLY 1

%define PROT_READ 1
%define PROT_WRITE 2
%define PROT_EXEC 4

%define MAP_SHARED 1
%define MAP_PRIVATE 2
%define MAP_SHARED_VALIDATE 3

%define UTSNAME_LENGTH 65
%define UTSDOMAIN_LENGTH 65

%define AF_UNIX 1
%define SOCK_STREAM 1
%define SOCK_CLOEXEC 0x80000

%define POLLIN 1


; MACROS

%macro WRITE_KSTR 2+
    [section .data]
%%str: db %2
%%endstr:
    __SECT__
    mov rax, SYS_WRITE
    mov rdi, %1
    lea rsi, [rel %%str]
    mov rdx, %%endstr-%%str
    syscall
%endmacro

%macro DIE 1+
    WRITE_KSTR FD_STDERR, %1, 0x0a
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
%endmacro
