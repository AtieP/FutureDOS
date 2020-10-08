bits 16
cpu 8086

main:
    push cs
    pop ds
    push cs
    pop es

.read_loop:
    call clear_buffer

    ; Print a new line
    mov ax, (0x05 << 8) | 0x0A
    mov bl, [DATA.NORMAL_COLOR]
    int 22h

    mov al, 0x0D
    int 22h

    ; Print prompt
    mov ah, 0x06
    mov si, DATA.PROMPT_STR
    int 22h

    ; Read input
    mov ah, 0x04
    mov di, DATA.BUFFER
    mov cx, DATA.BUFFER.LEN
    int 22h

    ; Check if the input is internal commands
    mov si, DATA.COMMANDS.ECHO
    mov cx, DATA.COMMANDS.ECHO.LEN
    call str_startswith
    jnc .echo

    mov si, DATA.COMMANDS.RESET
    mov cx, DATA.COMMANDS.RESET.LEN
    call str_startswith
    jnc .reset

    ; Display error message
    mov ah, 0x06
    mov si, DATA.ERROR_MESSAGE
    mov bl, [DATA.ERROR_COLOR]
    int 22h

    jmp .read_loop

.echo:
    mov si, DATA.BUFFER
    add si, DATA.COMMANDS.ECHO.LEN
    inc si

    mov ah, 0x06
    int 22h
    jmp .read_loop

.reset:
    int 19h

DATA:
.PROMPT_STR: db "</> ",0x00
.NORMAL_COLOR: db 0x0F
.ERROR_COLOR: db 0x04
.BUFFER: times 127 db 0x00
.BUFFER.LEN: equ $ - .BUFFER - 1 ; Substract the NULL end byte
.ERROR_MESSAGE: db "Invalid command provided",0x00

.COMMANDS:
.COMMANDS.ECHO: db "echo"
.COMMANDS.ECHO.LEN: equ $ - .COMMANDS.ECHO
.COMMANDS.RESET: db "reset"
.COMMANDS.RESET.LEN: equ $ - .COMMANDS.RESET

.FILE: db "TERMINALBIN"

; Clears the command buffer.
; IN/OUT: Nothing
clear_buffer:
    xor al, al
    mov cx, DATA.BUFFER.LEN
    mov di, DATA.BUFFER
    rep stosb
    ret

; Check if the string has the prefix.
; IN: DI = Original string, SI = Prefix, CX = Length of prefix
; OUT: Carry set if not
str_startswith:
    push ax
    push cx
    push si
    push di
    pushf

.check:
    mov al, [di]
    cmp al, [si]
    jne .mismatch

    dec cx
    jz .match

    inc si
    inc di
    jmp .check

.mismatch:
    popf
    stc
    jmp .end

.match:
    popf
    clc

.end:
    pop di
    pop si
    pop cx
    pop ax
    ret