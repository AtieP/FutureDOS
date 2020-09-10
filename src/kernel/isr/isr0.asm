%include "kernel/lib/debug.asm"
%include "kernel/lib/screen.asm"


isr0:
    push si
    push bx

    mov si, .ERROR_MESSAGE_HEADER_STR
    mov bl, 0x04
    call puts

    pop ax
    pop cx
    push cx
    push ax
    mov si, .ERROR_MESSAGE_BODY_STR
    call puts

    pop bx
    pop si

    mov ax, 1
    mov bx, 2
    mov cx, 3
    mov dx, 4
    mov bp, 5
    mov di, 1
    mov si, 1
    call print_register_dump

    mov si, .ERROR_MESSAGE_FOOTER_STR
    mov bl, 0x04
    call puts

    jmp $


.ERROR_MESSAGE_HEADER_STR:
    db 0x0A,0x0D
    db "Unhandled division by zero exception."
    db 0x00
.ERROR_MESSAGE_BODY_STR: db 0x0A,0x0D,"Register dump:",0x0A,0x0D,0x00
.ERROR_MESSAGE_FOOTER_STR: db 0x0A,0x0D,"Terminating application.",0x00

.HEX_BUFFER: db "0x0000",0x00
