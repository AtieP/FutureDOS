bits 16
cpu 8086

; Compares a string.
; IN: SI = First string to compare, DI = Second string to compare
; OUT: Carry clear if equal, else carry set
strcmp:
    push ax
    push bx
    xor bx, bx

.check_equal:
    mov al, [si + bx]
    cmp al, [di + bx]
    jne .mismatch

    test al, al
    jz .equal

    inc bx
    jmp .check_equal

.mismatch:
    stc
    jmp .end

.equal:
    clc

.end:
    pop bx
    pop ax
    ret

; Checks if a string starts with the specified prefix.
; IN: SI = Original string to compare, DI = Prefix, CX: Length of the prefix
; OUT: Carry clear if starts with, else set
strstartswith:
    push ax
    push bx
    pushf

    xor bx, bx

.check_chars:
    test cx, cx
    jz .match
    
    mov al, [si + bx]
    cmp al, [di + bx]
    jne .mismatch

    inc bx
    dec cx
    jmp .check_chars

.mismatch:
    popf
    stc
    jmp .end

.match:
    popf
    clc

.end:
    pop bx
    pop ax
    ret


.check_str:
; Converts a 16-bit integer to a string. In hexadecimal.
; IN: DX = 16-bit integer, SI = The place where the string will be put
; (note: 6 bytes required)
; OUT: Nothing
itohex:
    push ax
    push bx
    push cx
    push dx
    pushf

    xor cx, cx

.nibble_to_char:
    cmp cx, 4
    je .end

    mov ax, dx
    ; Mask first three 0s
    and ax, 0x000f
    ; Convert to ASCII
    add al, 0x30
    cmp al, 0x39
    jle .write_to_buffer
    ; Convert to A, B, C...
    add al, 7

.write_to_buffer:
    mov bx, si
    add bx, 5
    sub bx, cx
    mov [bx], al
    times 4 ror dx, 1

    inc cx
    jmp .nibble_to_char

.end:
    popf
    pop dx
    pop cx
    pop bx
    pop ax
    ret
