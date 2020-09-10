isr9:
    push ax
    push bx

    mov [__KEYBOARD_IRQ_CALLED], byte 1

    in al, 0x60
    mov [__KEYBOARD_LAST_KEY], al

    mov al, 0x20
    out 0x20, al

    pop bx
    pop ax
    sti
    iret
