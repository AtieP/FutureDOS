bits 16
cpu 8086

; Handler for the PIT's interrupt (IRQ 0)
isr8:
    push ax
    mov al, 0x20
    out 0x20, al
    pop ax
    sti
    iret
