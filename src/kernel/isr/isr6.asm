bits 16
cpu 8086

; Invalid opcode handler
isr6:
    push si
    push bx
    push ds

    push cs
    pop ds

    mov si, .ERROR_MESSAGE_HEADER_STR
    mov bl, 0x04
    call puts

    mov si, .ERROR_MESSAGE_BODY_STR
    call puts

    pop ds
    pop bx
    pop si

    call print_register_dump

    push si
    push bx
    push ds

    mov si, .ERROR_MESSAGE_FOOTER_STR
    mov bl, 0x04
    call puts

    pop ds
    pop bx
    pop si

    jmp $


.ERROR_MESSAGE_HEADER_STR:
    db 0x0A,0x0D
    db "Unhandled invalid opcode exception (int 0x06)."
    db 0x00
.ERROR_MESSAGE_BODY_STR: db 0x0A,0x0D,"Register dump:",0x0A,0x0D,0x00
.ERROR_MESSAGE_FOOTER_STR: db 0x0A,0x0D,"Terminating application.",0x00
