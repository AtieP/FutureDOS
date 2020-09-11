bits 16
cpu 8086

; keyboard_raw_getkey: src/kernel/drivers/keyboard.asm
; putc: src/kernel/lib/screen.asm

; Waits for a keystroke. Only keypresses are allowed.
; IN: Nothing
; OUT: AH = Keycode, AL = ASCII representation of the keycode
getchar:
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

    pop si
    ret

; Waits for a keystroke. Only keypresses are allowed.
; Unlike getchar, this prints the ASCII representation of the char.
; IN: BL = Color of the ASCII char
; OUT: AH = Keycode, AL = ASCII representation of the keycode
getcharp:
    push bx
    call getchar
    call putc
    pop bx
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
