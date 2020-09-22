bits 16
cpu 8086

__KEYBOARD_IRQ_CALLED: db 0
__KEYBOARD_LAST_KEY: db 0
__KEYBOARD_FLAGS:
    .extended: db 0
    .numlock: db 0
    .capslock: db 0
    .scrolllock: db 0
    .alt: db 0
    .left_shift: db 0
    .right_shift: db 0
    .control: db 0

; Waits for a keystroke doesn't matter if it was a keypress or a keyrelease.
; IN: Nothing
; OUT: AH = Keycode
keyboard_raw_getkey:
    pushf
    push ds

    push cs
    pop ds

    mov [__KEYBOARD_IRQ_CALLED], byte 0

.check_if_irq_was_triggered:
    mov ah, [__KEYBOARD_IRQ_CALLED]
    test ah, ah
    jnz .irq_was_triggered
    jmp .check_if_irq_was_triggered

.irq_was_triggered:
    mov ah, [__KEYBOARD_LAST_KEY]

.end:
    pop ds
    popf
    ret
