init_pic:
    push ax
    push ds
    pushf

    push cs
    pop ds

    cli

    ; Get current mask
    in al, 0x21
    mov [.MASTER_MASK], al

    ; Restart
    mov al, 0x11
    out 0x20, al

    xor al, al
    out 0x80, al

    ; Set master PIC offset (irq 0 = int 0x08)
    mov al, 0x08
    out 0x21, al

    xor al, al
    out 0x80, al

    ; Set cascading
    mov al, 0x04
    out 0x21, al

    xor al, al
    out 0x80, al

    ; Done
    mov al, 0x01
    out 0x21, al

    xor al, al
    out 0x80, al

    ; Recover mask
    mov al, [.MASTER_MASK]
    ; And also enable IRQ 0 and IRQ 1 (timer and keyboard)
    and al, -4
    out 0x21, al

    sti

    popf
    pop ds
    pop ax
    ret

.MASTER_MASK: db 0x00