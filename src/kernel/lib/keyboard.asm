bits 16
cpu 8086

%define KEY_A 0x1E
%define KEY_B 0x30
%define KEY_C 0x2E
%define KEY_D 0x20
%define KEY_E 0x12
%define KEY_F 0x21
%define KEY_G 0x22
%define KEY_H 0x23
%define KEY_I 0x17
%define KEY_J 0x24
%define KEY_K 0x25
%define KEY_L 0x26
%define KEY_M 0x32
%define KEY_N 0x31
%define KEY_O 0x18
%define KEY_P 0x19
%define KEY_Q 0x10
%define KEY_R 0x13
%define KEY_S 0x1F
%define KEY_T 0x14
%define KEY_U 0x16
%define KEY_V 0x2F
%define KEY_W 0x11
%define KEY_X 0x2D
%define KEY_Y 0x15
%define KEY_Z 0x2C
%define KEY_1 0x02
%define KEY_2 0x03
%define KEY_3 0x04
%define KEY_4 0x05
%define KEY_5 0x06
%define KEY_6 0x07
%define KEY_7 0x08
%define KEY_8 0x09
%define KEY_9 0x0A
%define KEY_0 0x0B
%define KEY_MINUS 0x0C
%define KEY_EQUAL 0x0D
%define KEY_SQUARE_OPEN_BRACKET 0x1A
%define KEY_SQUARE_CLOSE_BRACKET 0x1B
%define KEY_SEMICOLON 0x27
%define KEY_BACKSLASH 0x2B
%define KEY_COMMA 0x33
%define KEY_DOT 0x34
%define KEY_FORESLHASH 0x35
%define KEY_F1 0x3B
%define KEY_F2 0x3C
%define KEY_F3 0x3D
%define KEY_F4 0x3E
%define KEY_F5 0x3F
%define KEY_F6 0x40
%define KEY_F7 0x41
%define KEY_F8 0x42
%define KEY_F9 0x43
%define KEY_F10 0x44
%define KEY_F11 0x85
%define KEY_F12 0x86
%define KEY_BACKSPACE 0x0E
%define KEY_DELETE 0x53
%define KEY_DOWN 0x50
%define KEY_END 0x4F
%define KEY_ENTER 0x1C
%define KEY_ESC 0x01
%define KEY_HOME 0x47
%define KEY_INSERT 0x52
%define KEY_KEYPAD_5 0x4C
%define KEY_KEYPAD_MUL 0x37
%define KEY_KEYPAD_Minus 0x4A
%define KEY_KEYPAD_PLUS 0x4E
%define KEY_KEYPAD_DIV 0x35
%define KEY_LEFT 0x4B
%define KEY_PAGE_DOWN 0x51
%define KEY_PAGE_UP 0x49
%define KEY_PRINT_SCREEN 0x37
%define KEY_RIGHT 0x4D
%define KEY_SPACE 0x39
%define KEY_TAB 0x0F
%define KEY_UP 0x48

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
    ; Released
		db 0xFF
    db 0xFF ; Escape
    db 0xFF ; 1
    db 0xFF ; 2
    db 0xFF ; 3
    db 0xFF ; 4
    db 0xFF ; 5
    db 0xFF ; 6
    db 0xFF ; 7
    db 0xFF ; 8
    db 0xFF ; 9
    db 0xFF ; 0
    db 0xFF ; -
    db 0xFF  ; =
    db 0xFF ; Backspace
    db 0xFF ; Tab
    db 0xFF ; q
    db 0xFF ; w
    db 0xFF ; e
    db 0xFF ; r
    db 0xFF ; t
    db 0xFF ; y
    db 0xFF ; u
    db 0xFF ; i
    db 0xFF ; o
    db 0xFF ; p
    db 0xFF ; [
    db 0xFF ; ]
    db 0xFF ; Enter
    db 0xFF ; Left control
    db 0xFF ; a
    db 0xFF ; s
    db 0xFF ; d
    db 0xFF ; f
    db 0xFF ; g
    db 0xFF ; h
    db 0xFF ; j
    db 0xFF ; k
    db 0xFF ; l
    db 0xFF ; ;
    db 0xFF ; '
    db 0xFF ; `
    db 0xFF ; Left shift
    db 0xFF ; Backward slash
    db 0xFF ; z
    db 0xFF ; x
    db 0xFF ; c
    db 0xFF ; v
    db 0xFF ; b
    db 0xFF ; n
    db 0xFF ; m
    db 0xFF ; ,
    db 0xFF ; .
    db 0xFF ; /
    db 0xFF ; Right shift
    db 0xFF ; Keypad *
    db 0xFF ; Left alt
    db 0xFF ; Space
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
    db 0xFF ; Keypad 7
    db 0xFF ; Keypad 8
    db 0xFF ; Keypad 9
    db 0xFF ; Keypad -
    db 0xFF ; Keypad 4
    db 0xFF ; Keypad 5
    db 0xFF ; Keypad 6
    db 0xFF ; Keypad +
    db 0xFF ; Keypad 1
    db 0xFF ; Keypad 2
    db 0xFF ; Keypad 3
    db 0xFF ; Keypad 0
    db 0xFF ; Keypad .
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; F11
    db 0xFF ; F12
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; Unused
    db 0xFF ; Unused
