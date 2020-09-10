__KEYBOARD_IRQ_CALLED: db 0
__KEYBOARD_LAST_KEY: db 0

; Waits for a keystroke doesn't matter if it was a keypress or a keyrelease.
; IN: Nothing
; OUT: AH = Keycode
keyboard_raw_getkey:
    mov [__KEYBOARD_IRQ_CALLED], byte 0

.check_if_irq_was_triggered:
    mov ah, [__KEYBOARD_IRQ_CALLED]
    test ah, ah
    jnz .irq_was_triggered
    jmp .check_if_irq_was_triggered

.irq_was_triggered:
    mov ah, [__KEYBOARD_LAST_KEY]

.end:
    ret

; Waits for a keystroke. Only keypresses are allowed.
; IN: Nothing
; OUT: AH = Keycode, AL = ASCII representation of the keycode
keyboard_getkey:
    push ax
    push bx
    push si
    xor ax, ax

.check_not_keyrelease:
    call keyboard_raw_getkey
    push ax
    and ah, 128
    cmp ah, 128
    pop ax
    je .check_not_keyrelease

.keypress:
    ; Convert it to ASCII
    mov si, en_us.lower
    mov al, ah
    xor ah, ah
    add si, ax
    mov ah, al
    lodsb

    mov bl, 0x0E
    call putc

    pop si
    pop bx
    pop ax
    ret


en_us:
.lower:
		db '?',01h,"1234567890-=",08h,03h,
		db "qwertyuiop[]",04h,05h,"asdfghjkl;'`",06h,
		db "\zxcvbnm,./",07h,'*',08h,' ',09h,0Ah,0Bh,
		db 0Ch,0Dh,0Eh,0Fh,81h,82h,83h,84h,85h,86h,
		db "789-456+1230.",'?','?','?',87h,88h,'?'
		db '?','?','?',128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,'?',
		db '?','?',128,128,'?','?','?','?','?','?',
		db '?','?','?','?','?','?','?','?','?','?',
		db '?','?','?','?','?','?','?','?','?','?',
		db '?','?','?','?','?','?',128,'?','?',89h,
		db '?','?','?'
