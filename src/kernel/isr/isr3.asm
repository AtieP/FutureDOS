bits 16
cpu 8086

; puts: src/kernel/lib/screen.asm
; print_register_dump: src/kernel/lib/debug.asm

; Handler for breakpoint
; This will just show a register dump and then wait for a keystroke to execute
; the next instruction.
isr3:
    push si
    push bx
    push ds

    push cs
    pop ds

    sti

    mov si, .BREAKPOINT_HEADER_STR
    mov bl, 0x04
    call puts

    mov si, .BREAKPOINT_BODY_STR
    call puts

    pop ds
    pop bx
    pop si

    call print_register_dump

    push si
    push bx
    push ax
    push ds

    push cs
    pop ds

    mov si, .BREAKPOINT_FOOTER_STR
    mov bl, 0x04
    call puts

    xor bl, bl
    mov si, ._NEWLINE
    call puts

    call getchar

    pop ds
    pop ax
    pop bx
    pop si
    iret


.BREAKPOINT_HEADER_STR: db 0x0A,0x0D,"Breakpoint",0x00
.BREAKPOINT_BODY_STR: db 0x0A,0x0D,"Register dump:",0x0A,0x0D,0x00
.BREAKPOINT_FOOTER_STR: db 0x0A,0x0D,"Press any key to continue...",0x00
._NEWLINE: db 0x0A,0x0D,0x00
