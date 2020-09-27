bits 16
cpu 8086

push cs
pop ds

mov si, _HELLO_FROM_TERMINAL_BIN
mov bl, 0x0E
mov ah, 0x06
int 22h

hang:
    hlt
    jmp hang

_HELLO_FROM_TERMINAL_BIN: db "Hello from TERMINAL.BIN!",0x00