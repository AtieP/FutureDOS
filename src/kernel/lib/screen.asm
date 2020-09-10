%ifndef __SCREEN_ASM
%define __SCREEN_ASM

; Prints a char into the screen. Unlike cga_putc, escaping is allowed.
; IN: AL = Char, BL = Color
; OUT: None
putc:
    push bx
    push cx
    pushf

    ; Check for special bytes
    cmp al, 0x08
    je .backspace

    cmp al, 0x0A
    je .linefeed

    cmp al, 0x0D
    je .carriage_return

    call cga_putc
    jmp .end

.backspace:
    call cga_get_cursor
    ; If the cursor is at the top left, it's not possible to go back
    test cx, cx
    jz .backspace_first_line

    test bx, bx
    jz .backspace_go_up

    dec bx
    call cga_move_cursor
    jmp .end

.backspace_first_line:
    test bx, bx
    jz .end
    dec bx
    call cga_move_cursor
    jmp .end

.backspace_go_up:
    dec cx
    mov bx, 79
    call cga_move_cursor
    jmp .end

.linefeed:
    call cga_get_cursor
    inc cx
    call cga_move_cursor
    cmp cx, 24
    jne .end
    call cga_scroll
    jmp .end

.carriage_return:
    call cga_get_cursor
    xor bx, bx
    call cga_move_cursor

.end:
    popf
    pop cx
    pop bx
    ret


; Prints a null-terminated string into the screen.
; IN: DS:SI = Pointer to string, BL: String color
; OUT: Nothing
puts:
    push ax
    push si

.print_each_char:
    lodsb
    test al, al
    jz .end
    call putc
    jmp .print_each_char

.end:
    pop si
    pop ax
    ret

%endif
