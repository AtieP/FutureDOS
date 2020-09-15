bits 16
cpu 8086

%include "kernel/lib/keycodes.inc"

; cga_get_cursor: src/kernel/drivers/cga.asm
; keyboard_raw_getkey: src/kernel/drivers/keyboard.asm
; putc: src/kernel/lib/screen.asm

; Waits for a keystroke. Only keypresses are allowed.
; Note: this doesn't print the pressed key.
; IN: Nothing
; OUT: AH = Keycode, AL = ASCII representation of the keycode
getchar:
    push si
    pushf
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

    popf
    pop si
    ret

; Waits for a keystroke. Only keypresses are allowed.
; Unlike getchar, this prints the ASCII representation of the char.
; IN: BL = Color of the ASCII char
; OUT: AH = Keycode, AL = ASCII representation of the keycode
getcharp:
    call getchar
    call putc
    ret

; Gets a null-terminated string from the keyboard. This is memory safe.
; Note: This doesn't print the pressed keys.
; IN: DI = Pointer to where the string will be written
;     CX = Number of chars to be readen (does not include the NULL byte at the end)
; OUT: Nothing
gets:
    push ax
    push cx
    push dx
    push di
    pushf

    cld
    xor dx, dx

.get_key_loop:
    call getchar

    cmp ah, KEY_BACKSPACE
    je .backspace

    cmp ah, KEY_ENTER
    je .done

    test cx, cx
    jz .get_key_loop

    stosb
    dec cx
    inc dx
    jmp .get_key_loop

.backspace:
    test dx, dx
    je .get_key_loop
    inc cx
    dec dx
    dec di
    jmp .get_key_loop

.done:
    xor al, al
    stosb

    popf
    pop di
    pop dx
    pop cx
    pop ax
    ret

; Gets a null-terminated string from the keyboard. This is memory safe.
; Unlike gets, the keys are printed.
; IN: DI = Pointer to where the string will be written
;     BL = Color of chars
;     CX = Number of chars to be readen (does not include the NULL byte at the end)
; OUT: Nothing
getsp:
    push ax
    push cx
    push dx
    push di
    pushf

    cld
    xor dx, dx

.get_key_loop:
    call getchar

    cmp ah, KEY_BACKSPACE
    je .backspace

    cmp ah, KEY_ENTER
    je .done

    test cx, cx
    jz .get_key_loop

    call putc

    stosb
    dec cx
    inc dx
    jmp .get_key_loop

.backspace:
    test dx, dx
    jz .get_key_loop
    mov al, 0x08
    call putc
    inc cx
    dec dx
    dec di
    jmp .get_key_loop

.done:
    xor al, al
    stosb

    mov al, 0x0A
    call putc
    mov al, 0x0D
    call putc

    popf
    pop di
    pop dx
    pop cx
    pop ax
    ret

en_us:
.lower:

    ; Pressed
		db 0xFF
    db 0xFF ; Escape
    db "1"  ; 1
    db "2"  ; 2
    db "3"  ; 3
    db "4"  ; 4
    db "5"  ; 5
    db "6"  ; 6
    db "7"  ; 7
    db "8"  ; 8
    db "9"  ; 9
    db "0"  ; 0
    db "-"  ; -
    db "="  ; =
    db 0x08 ; Backspace
    db 0xFF ; Tab
    db "q"  ; q
    db "w"  ; w
    db "e"  ; e
    db "r"  ; r
    db "t"  ; t
    db "y"  ; y
    db "u"  ; u
    db "i"  ; i
    db "o"  ; o
    db "p"  ; p
    db "["  ; [
    db "]"  ; ]
    db 0x0A ; Enter
    db 0xFF ; Left control
    db "a"  ; a
    db "s"  ; s
    db "d"  ; d
    db "f"  ; f
    db "g"  ; g
    db "h"  ; h
    db "j"  ; j
    db "k"  ; k
    db "l"  ; l
    db ";"  ; ;
    db "'"  ; '
    db "`"  ; `
    db 0xFF ; Left shift
    db 0x5C ; Backward slash
    db "z"  ; z
    db "x"  ; x
    db "c"  ; c
    db "v"  ; v
    db "b"  ; b
    db "n"  ; n
    db "m"  ; m
    db ","  ; ,
    db "."  ; .
    db "/"  ; /
    db 0xFF ; Right shift
    db "*"  ; Keypad *
    db 0xFF ; Left alt
    db " "  ; Space
    db 0xFF ; Capslock
    db 0xFF ; F1
    db 0xFF ; F2
    db 0xFF ; F3
    db 0xFF ; F4
    db 0xFF ; F5
    db 0xFF ; F6
    db 0xFF ; F7
    db 0xFF ; F8
    db 0xFF ; F9
    db 0xFF ; F10
    db 0xFF ; Number lock
    db 0xFF ; Scroll lock
    db "7"  ; Keypad 7
    db "8"  ; Keypad 8
    db "9"  ; Keypad 9
    db "-"  ; Keypad -
    db "4"  ; Keypad 4
    db "5"  ; Keypad 5
    db "6"  ; Keypad 6
    db "+"  ; Keypad +
    db "1"  ; Keypad 1
    db "2"  ; Keypad 2
    db "3"  ; Keypad 3
    db "0"  ; Keypad 0
    db "."  ; Keypad .
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; F11
    db 0xFF ; F12
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; Unused
