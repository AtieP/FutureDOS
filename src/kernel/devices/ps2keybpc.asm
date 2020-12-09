db "FV"
dw 0x0000
dw ps2keybpc_irq
dw ps2keybpc_init

; -----------------------------------------------------
; TODO: When filesystem driver is implemented, create
; out own versions of ps2_wait_read and ps2_wait_write
; -----------------------------------------------------

; Key buffers
ps2keybpc_keyboard_buffer_ascii: db 0x00
ps2keybpc_keyboard_buffer_scancode: db 0x00

; Bit 0 set = Capslock
; Bit 1 set = Left shift
; Bit 2 set = Right shift
; Bit 3 set = Control
; Bit 4 set = Alt
; Bit 5 set = IRQ called
; All other bits undefined
ps2keybpc_keyboard_flags: db 0x00

; Initializes the PS/2 PC/XT keyboard.
; IN:
;    Nothing
; OUT:
;    AX = 0x00 (Success)
;    AX = 0x01 (Error)
ps2keybpc_init:
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

ps2keybpc_irq:
    push ax
    push bx
    push si
    push ds

    push cs
    pop ds

    in al, 0x60

    mov [ps2keybpc_keyboard_buffer_scancode], al
    mov bl, [ps2keybpc_keyboard_flags]

    mov [ps2keybpc_keyboard_buffer_ascii], byte 0xFF

.ascii.check_modifiers:
    xor ah, ah

    cmp al, 0x38
    je .ascii.alt.pressed

    cmp al, 0xB8
    je .ascii.alt.released

    cmp al, 0x2A
    je .ascii.left_shift.pressed

    cmp al, 0xAA
    je .ascii.left_shift.released

    cmp al, 0x36
    je .ascii.right_shift.pressed

    cmp al, 0xB6
    je .ascii.right_shift.released

    cmp al, 0x1D
    je .ascii.control.pressed

    cmp al, 0x9D
    je .ascii.control.released

    cmp al, 0x3A
    je .ascii.capslock.pressed

    test al, 128
    jnz .ascii.apply_modifiers

    ; Now, convert to ascii
.ascii.convert_to_ascii:
    test bl, 1
    jnz .ascii.convert_to_ascii.capslock

    test bl, 1 << 1
    jnz .ascii.convert_to_ascii.shift

    test bl, 1 << 2
    jnz .ascii.convert_to_ascii.shift

    test bl, 1 << 3
    jnz .ascii.convert_to_ascii.control

    test bl, 1 << 4
    jnz .ascii.convert_to_ascii.alt

    mov si, ps2keybpc_layout
    add si, ax
    mov al, [si]
    mov [ps2keybpc_keyboard_buffer_ascii], al
    jmp .ascii.apply_modifiers

.ascii.convert_to_ascii.capslock:
    test bl, 1 << 1
    jnz .ascii.convert_to_ascii.capslock.shift

    test bl, 1 << 2
    jnz .ascii.convert_to_ascii.capslock.shift

    mov si, ps2keybpc_layout.capslock
    add si, ax
    mov al, [si]
    mov [ps2keybpc_keyboard_buffer_ascii], al
    jmp .ascii.apply_modifiers

.ascii.convert_to_ascii.capslock.shift:
    mov si, ps2keybpc_layout.shift_and_capslock
    add si, ax
    mov al, [si]
    mov [ps2keybpc_keyboard_buffer_ascii], al
    jmp .ascii.apply_modifiers

.ascii.convert_to_ascii.shift:
    mov si, ps2keybpc_layout.shift
    add si, ax
    mov al, [si]
    mov [ps2keybpc_keyboard_buffer_ascii], al
    jmp .ascii.apply_modifiers

.ascii.convert_to_ascii.control:
.ascii.convert_to_ascii.alt:
    mov [ps2keybpc_keyboard_buffer_ascii], byte 0xFF
    jmp .ascii.apply_modifiers

.ascii.alt.pressed:
    or bl, 1 << 4
    jmp .ascii.apply_modifiers

.ascii.alt.released:
    xor bl, 1 << 4
    jmp .ascii.apply_modifiers

.ascii.left_shift.pressed:
    or bl, 1 << 1
    jmp .ascii.apply_modifiers

.ascii.left_shift.released:
    xor bl, 1 << 1
    jmp .ascii.apply_modifiers

.ascii.right_shift.pressed:
    or bl, 1 << 2
    jmp .ascii.apply_modifiers

.ascii.right_shift.released:
    xor bl, 1 << 2
    jmp .ascii.apply_modifiers

.ascii.control.pressed:
    or bl, 1 << 3
    jmp .ascii.apply_modifiers

.ascii.control.released:
    xor bl, 1 << 3
    jmp .ascii.apply_modifiers

.ascii.capslock.pressed:
    test bl, 1
    jnz .ascii.capslock.disable

    or bl, 1
    jmp .ascii.apply_modifiers

.ascii.capslock.disable:
    xor bl, 1

.ascii.apply_modifiers:
    ; Also set IRQ called
    or bl, 1 << 5
    mov [ps2keybpc_keyboard_flags], bl

.end:
    mov al, 0x20
    out 0x20, al

    pop ds
    pop si
    pop bx
    pop ax
    iret

; en-us layout
ps2keybpc_layout:
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