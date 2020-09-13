bits 16
cpu 8086

; Handler for the PIT's interrupt (IRQ 0)
isr8:
    sti
    iret
