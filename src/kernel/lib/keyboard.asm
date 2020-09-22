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
    push ds
    pushf
    xor ax, ax

    push cs
    pop ds

.check_not_keyrelease:
    call keyboard_raw_getkey
    push ax
    and ah, 128
    cmp ah, 128
    pop ax
    je .check_not_keyrelease

    cmp [__KEYBOARD_FLAGS.left_shift], byte 1
    je .shift

    cmp [__KEYBOARD_FLAGS.right_shift], byte 1
    je .shift

    cmp [__KEYBOARD_FLAGS.capslock], byte 1
    je .capslock

    jmp .normal

.shift:
    cmp [__KEYBOARD_FLAGS.capslock], byte 1
    je .shift_and_capslock

    mov si, en_us.shift
    jmp .convert_to_ascii_and_return

.shift_and_capslock:
    mov si, en_us.shift_and_capslock
    jmp .convert_to_ascii_and_return

.capslock:
    mov si, en_us.capslock
    jmp .convert_to_ascii_and_return

.normal:
    mov si, en_us.normal

.convert_to_ascii_and_return:
    ; Convert it to ASCII
    mov al, ah
    xor ah, ah
    add si, ax
    mov ah, al
    lodsb

    popf
    pop ds
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
    push ds
    pushf

    push cs
    pop ds

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
    pop ds
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
    push ds
    pushf

    push cs
    pop ds

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
    pop ds
    pop di
    pop dx
    pop cx
    pop ax
    ret

en_us:
.normal:

    ; Pressed
		db 0xFF
    db 0xFF ; Escape
    db "1"
    db "2"
    db "3"
    db "4"
    db "5"
    db "6"
    db "7"
    db "8"
    db "9"
    db "0"
    db "-"
    db "="
    db 0x08 ; Backspace
    db 0xFF ; Tab
    db "q"
    db "w"
    db "e"
    db "r"
    db "t"
    db "y"
    db "u"
    db "i"
    db "o"
    db "p"
    db "["
    db "]"
    db 0x0A ; Enter
    db 0xFF ; Left control
    db "a"
    db "s"
    db "d"
    db "f"
    db "g"
    db "h"
    db "j"
    db "k"
    db "l"
    db ";"
    db "'"
    db "`"
    db 0xFF ; Left shift
    db 0x5C ; Backward slash
    db "z"
    db "x"
    db "c"
    db "v"
    db "b"
    db "n"
    db "m"
    db ","
    db "."
    db "/"
    db 0xFF ; Right shift
    db "*"  ; Keypad *
    db 0xFF ; Left alt
    db " "
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

.capslock:

    ; Pressed
    db 0xFF
    db 0xFF ; Escape
    db "1"
    db "2"
    db "3"
    db "4"
    db "5"
    db "6"
    db "7"
    db "8"
    db "9"
    db "0"
    db "-"
    db "="
    db 0x08 ; Backspace
    db 0xFF ; Tab
    db "Q"
    db "W"
    db "E"
    db "R"
    db "T"
    db "Y"
    db "U"
    db "I"
    db "O"
    db "P"
    db "["
    db "]"
    db 0x0A ; Enter
    db 0xFF ; Left control
    db "A"
    db "S"
    db "D"
    db "F"
    db "G"
    db "H"
    db "J"
    db "K"
    db "L"
    db ";"
    db "'"
    db "`"
    db 0xFF ; Left shift
    db 0x5C ; Backward slash
    db "Z"
    db "X"
    db "C"
    db "V"
    db "B"
    db "N"
    db "M"
    db ","
    db "."
    db "/"
    db 0xFF ; Right shift
    db "*"  ; Keypad *
    db 0xFF ; Left alt
    db " "
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

.shift:

    ; Pressed
    db 0xFF
    db 0xFF ; Escape
    db "!"
    db "@"
    db "#"
    db "$"
    db "%"
    db "^"
    db "&"
    db "*"
    db "("
    db ")"
    db "_"
    db "+"
    db 0x08 ; Backspace
    db 0xFF ; Tab
    db "Q"
    db "W"
    db "E"
    db "R"
    db "T"
    db "Y"
    db "U"
    db "I"
    db "O"
    db "P"
    db "{"
    db "}"
    db 0x0A ; Enter
    db 0xFF ; Left control
    db "A"
    db "S"
    db "D"
    db "F"
    db "G"
    db "H"
    db "J"
    db "K"
    db "L"
    db ":"
    db '"'
    db "~"
    db 0xFF ; Left shift
    db "|"
    db "Z"
    db "X"
    db "C"
    db "V"
    db "B"
    db "N"
    db "M"
    db "<"
    db ">"
    db "?"
    db 0xFF ; Right shift
    db "*"  ; Keypad *
    db 0xFF ; Left alt
    db " "
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

.shift_and_capslock:

    ; Pressed
    db 0xFF
    db 0xFF ; Escape
    db "!"
    db "@"
    db "#"
    db "$"
    db "%"
    db "^"
    db "&"
    db "*"
    db "("
    db ")"
    db "_"
    db "+"
    db 0x08 ; Backspace
    db 0xFF ; Tab
    db "q"
    db "w"
    db "e"
    db "r"
    db "t"
    db "y"
    db "u"
    db "i"
    db "o"
    db "p"
    db "{"
    db "}"
    db 0x0A ; Enter
    db 0xFF ; Left control
    db "a"
    db "s"
    db "d"
    db "f"
    db "g"
    db "h"
    db "j"
    db "k"
    db "l"
    db ":"
    db '"'
    db "~"
    db 0xFF ; Left shift
    db "|"
    db "z"
    db "x"
    db "c"
    db "v"
    db "b"
    db "n"
    db "m"
    db "<"
    db ">"
    db "?"
    db 0xFF ; Right shift
    db "*"  ; Keypad *
    db 0xFF ; Left alt
    db " "
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
