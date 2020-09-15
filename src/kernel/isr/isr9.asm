bits 16
cpu 8086

; __KEYBOARD_IRQ_CALLED: src/kernel/drivers/keyboard.asm
; __KEYBOARD_LAST_KEY: src/kernel/drivers/keyboard.asm

%define _EXTENDED 0xE0
%define _NUMLOCK_PRESS 0x45
%define _CAPSLOCK_PRESS 0x3A
%define _SCROLLLOCK_PRESS 0x46
%define _ALT_PRESS 0x38
%define _ALT_RELEASE 0xB8
%define _LEFT_SHIFT_PRESS 0x2A
%define _LEFT_SHIFT_RELEASE 0xAA
%define _RIGHT_SHIFT_PRESS 0x36
%define _RIGHT_SHIFT_RELEASE 0xB6
%define _CONTROL_PRESS 0x1D
%define _CONTROL_RELEASE 0x9D

; Handler for keyboard key press/release IRQ
isr9:
    push ax
    pushf

    mov [__KEYBOARD_IRQ_CALLED], byte 1

.read_key:
    in al, 0x60
    mov [__KEYBOARD_LAST_KEY], al

    cmp al, _EXTENDED
    je .extended

    mov [__KEYBOARD_FLAGS.extended], byte 0

    cmp al, _ALT_PRESS
    je .alt

    cmp al, _ALT_RELEASE
    je .alt_set_to_false

    cmp al, _LEFT_SHIFT_PRESS
    je .left_shift

    cmp al, _LEFT_SHIFT_RELEASE
    je .left_shift_set_to_false

    cmp al, _RIGHT_SHIFT_PRESS
    je .right_shift

    cmp al, _RIGHT_SHIFT_RELEASE
    je .right_shift_set_to_false

    cmp al, _CONTROL_PRESS
    je .control

    cmp al, _CONTROL_RELEASE
    je .control_set_to_false

    cmp al, _NUMLOCK_PRESS
    je .numlock

    cmp al, _CAPSLOCK_PRESS
    je .capslock

    cmp al, _SCROLLLOCK_PRESS
    je .scrolllock

    jmp .end

.extended:
    mov [__KEYBOARD_FLAGS.extended], byte 1
    jmp .end

.numlock:
    cmp [__KEYBOARD_FLAGS.numlock], byte 1
    je .numlock_set_to_false

    mov [__KEYBOARD_FLAGS.numlock], byte 1
    jmp .end

.numlock_set_to_false:
    mov [__KEYBOARD_FLAGS.numlock], byte 0
    jmp .end

.capslock:
    cmp [__KEYBOARD_FLAGS.capslock], byte 1
    je .capslock_set_to_false

    mov [__KEYBOARD_FLAGS.capslock], byte 1
    jmp .end

.capslock_set_to_false:
    mov [__KEYBOARD_FLAGS.capslock], byte 0
    jmp .end

.scrolllock:
    cmp [__KEYBOARD_FLAGS.scrolllock], byte 1
    je .scrolllock_set_to_false

    mov [__KEYBOARD_FLAGS.scrolllock], byte 1
    jmp .end

.scrolllock_set_to_false:
    mov [__KEYBOARD_FLAGS.scrolllock], byte 0
    jmp .end

.alt:
    mov [__KEYBOARD_FLAGS.alt], byte 1
    jmp .end

.alt_set_to_false:
    mov [__KEYBOARD_FLAGS.alt], byte 0
    jmp .end

.left_shift:
    mov [__KEYBOARD_FLAGS.left_shift], byte 1
    jmp .end

.left_shift_set_to_false:
    mov [__KEYBOARD_FLAGS.left_shift], byte 0
    jmp .end

.right_shift:
    mov [__KEYBOARD_FLAGS.right_shift], byte 1
    jmp .end

.right_shift_set_to_false:
    mov [__KEYBOARD_FLAGS.right_shift], byte 0
    jmp .end

.control:
    mov [__KEYBOARD_FLAGS.control], byte 1
    jmp .end

.control_set_to_false:
    mov [__KEYBOARD_FLAGS.control], byte 0

.end:
    mov al, 0x20
    out 0x20, al

    popf
    pop ax
    sti
    iret

%undef _EXTENDED
%undef _NUMLOCK_PRESS
%undef _CAPSLOCK_PRESS
%undef _SCROLLLOCK_PRESS
%undef _ALT_PRESS
%undef _ALT_RELEASE
%undef _LEFT_SHIFT_PRESS
%undef _LEFT_SHIFT_RELEASE
%undef _RIGHT_SHIFT_PRESS
%undef _RIGHT_SHIFT_RELEASE
%undef _CONTROL_PRESS
%undef _CONTROL_RELEASE
