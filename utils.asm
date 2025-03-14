%define UTSNAME_LENGTH 65
%define UTSDOMAIN_LENGTH 65

section .text
    global utils_strncmp
    global utils_getenv


; @param rdi s1
; @param rsi s2
; @param rdx n
; @return 0 if s1 and s2 are equal, otherwize 1.
utils_strncmp:

    cmp rdx, 0
    je .same
.next_char:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .differ
    cmp al, 0
    je .same

    sub rdx, 1
    cmp rdx, 0
    jg .next_char

.same:
    mov rax, 0
    ret
.differ:
    mov rax, 1
    ret

; Searches environment variable list to find the value associated with a name.
;
; @param rdi environ
; @param rsi Environment variable name.
; @return Pointer to the value in the environment or 0 if there is no match.
utils_getenv:
    cmp rdi, 0
    je .return_no_match
.next_entry:
    mov rax, [rdi] ; Environment variable string.
    mov r9, rsi ; Pointer to scan target environment variable name.
    cmp rax, 0
    je .return_no_match
    add rdi, 8
.next_char:
    mov r10b, [rax] ; Next environment variable character.
    mov r11b, [r9] ; Next environment variable name character.
    cmp r10b, 0
    je .next_entry
    cmp r10b, '='
    jne .compare_chars
    cmp r11b, 0
    je .return_match
.compare_chars:
    cmp r10b, r11b
    jne .next_entry
    add rax, 1
    add r9, 1
    jmp .next_char
.return_match:
    add rax, 1
    ret
.return_no_match:
    mov rax, 0
    ret
