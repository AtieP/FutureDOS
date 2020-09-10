%ifndef __STRING_ASM
%define __STRING_ASM

; Compares a string.
; IN: SI = First string to compare, DI = Second string to compare
; OUT: Carry if equal
strcmp:
    push ax
    push si
    push di


.cmp_char:
    lodsb
    cmp al, [di]
    jne .not_equal

    test al, al
    jz .equal

    inc di
    jmp .cmp_char

.not_equal:
    stc
    jmp .end

.equal:
    clc

.end:
    pop di
    pop si
    pop ax
    ret

; Converts a 16-bit integer to a string. In hexadecimal.
; IN: DX = 16-bit integer, SI = The place where the string will be put
; (note: 6 bytes required)
; OUT: Nothing
itohex:
    push ax
    push bx
    push cx
    push dx

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
    pop dx
    pop cx
    pop bx
    pop ax
    ret

%endif
