db "FV"
dw 0x0000
dw ps2keybxt_irq
dw ps2keybxt_init

; TODO: When filesystem driver is implemented, create
; out own versions of ps2_wait_read and ps2_wait_write

; Initializes the PS/2 PC/XT keyboard.
; IN:
;    Nothing
; OUT:
;    AX = 0x00 (Success)
;    AX = 0x01 (Error)
ps2keybxt_init:
    push cx
    pushf

    cli

    ; Disable keyboard
    call ps2_wait_write
    mov al, 0xAD
    out 0x64, al

    mov cx, 3

.self_test:
    call ps2_wait_write
    mov al, 0xFF
    out 0x60, al

    call ps2_wait_read
    in al, 0x60

    cmp al, 0xFA
    je .self_test.ack

    cmp al, 0xAA
    je .enable_scanning

    cmp al, 0xFC
    je .error

    cmp al, 0xFD
    je .error

    cmp al, 0xFE
    jne .error

    loop .self_test
    jmp .error

.self_test.ack:
    call ps2_wait_read
    in al, 0x60

    cmp al, 0xAA
    jne .error

.enable_scanning:
    call ps2_wait_write
    mov al, 0xF4
    out 0x60, al

    mov cx, 3

.set_scancode_set:
    call ps2_wait_write
    mov al, 0xF0
    out 0x60, al

    call ps2_wait_read
    in al, 0x60

    cmp al, 0xFE
    je .set_scancode_set.decrease_cx

    cmp al, 0xFA
    jne .error

    call ps2_wait_write
    mov al, 2 ; First set
    out 0x60, al

    jmp .enable_keyboard

.set_scancode_set.decrease_cx:
    loop .set_scancode_set
    jmp .error

.enable_keyboard:
    call ps2_wait_write
    mov al, 0xAE
    out 0x64, al

.success:
    popf
    pop cx
    xor ax, ax
    ret

.error:
    popf
    pop cx
    mov ax, 1
    ret

ps2keybxt_irq:
    iret
