bits 16
cpu 8086

; putc: src/kernel/lib/screen.asm
; puts: src/kernel/lib/screen.asm

; Prints a register dump. To be able to print CS and IP, push them
; (first CS and then IP).
; NOTE: CS and IP are NOT POPPED. You NEED TO POP THEM FROM THE STACK YOURSELF
; AFTER THIS FUNCTION.

%define _REGISTER_NAME_COLOR 0x0F
%define _REGISTER_VALUE_COLOR 0x07

%macro _PRINT_SPACE 0
    mov al, " "
    call putc
%endmacro

%macro _PRINT_NEW_LINE 0
    mov al, 0x0A
    call putc
    mov al, 0x0D
    call putc
%endmacro

print_register_dump:
    push ax
    push bx
    push dx
    push si
    push ds

    push ds
    push si
    push sp
    push dx
    push bx

    push cs
    pop ds

    ; ------------------
    ; DUMP AX

    ; Convert AX value to ASCII
    mov si, .HEX_BUFFER
    mov dx, ax
    call _itohex

    ; Print "AX: "
    mov si, .REGISTER_AX_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of AX
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP BX
    pop bx

    ; Convert BX value to ASCII
    mov dx, bx
    call _itohex

    ; Print "BX: "
    mov si, .REGISTER_BX_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of BX
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP CX

    ; Convert CX value to ASCII
    mov dx, cx
    call _itohex

    ; Print "CX: "
    mov si, .REGISTER_CX_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of CX
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP DX

    ; Convert DX value to ASCII
    pop dx
    call _itohex

    ; Print "DX: "
    mov si, .REGISTER_DX_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of DX
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP SP

    ; Convert SP value to ASCII
    pop dx
    ; Add 16 because:
    ; - SI on the stack
    ; - Altered registers on the stack
    ; - Return address on the stack
    ; - IP and CS on the stack
    add dx, 16
    call _itohex

    ; Print "SP: "
    mov si, .REGISTER_SP_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of SP
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP BP

    ; Convert BP value to ASCII
    mov dx, bp
    call _itohex

    ; Print "BP: "
    mov si, .REGISTER_BP_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of BP
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_NEW_LINE

    ; ------------------
    ; DUMP DI

    ; Convert DI value to ASCII
    mov dx, di
    call _itohex

    ; Print "DI: "
    mov si, .REGISTER_DI_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of DI
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP SI

    ; Convert SI value to ASCII
    pop dx
    mov si, .HEX_BUFFER
    call _itohex

    ; Print "SI: "
    mov si, .REGISTER_SI_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of SI
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP DS

    ; Convert DS value to ASCII
    pop dx
    call _itohex

    ; Print "DS: "
    mov si, .REGISTER_DS_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of DS
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP ES

    ; Convert ES value to ASCII
    mov dx, es
    call _itohex

    ; Print "ES: "
    mov si, .REGISTER_ES_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of ES
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP SS

    ; Convert SS value to ASCII
    mov dx, ss
    call _itohex

    ; Print "SS: "
    mov si, .REGISTER_SS_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of SS
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_NEW_LINE

    ; ------------------
    ; DUMP CS

    ; Convert CS value to ASCII
    push bp
    mov bp, sp
    mov dx, [bp + 16]
    call _itohex

    ; Print "CS: "
    mov si, .REGISTER_CS_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    ; Print the value of CS
    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    _PRINT_SPACE

    ; ------------------
    ; DUMP IP

    ; Convert IP value to ASCII
    mov dx, [bp + 14]
    call _itohex

    ; Print "IP: "
    mov si, .REGISTER_IP_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    pop bp

    pop ds
    pop si
    pop dx
    pop bx
    pop ax
    ret


.REGISTER_AX_STR: db "AX: ",0x00
.REGISTER_BX_STR: db "BX: ",0x00
.REGISTER_CX_STR: db "CX: ",0x00
.REGISTER_DX_STR: db "DX: ",0x00
.REGISTER_SP_STR: db "SP: ",0x00
.REGISTER_BP_STR: db "BP: ",0x00
.REGISTER_DI_STR: db "DI: ",0x00
.REGISTER_SI_STR: db "SI: ",0x00
.REGISTER_CS_STR: db "CS: ",0x00
.REGISTER_DS_STR: db "DS: ",0x00
.REGISTER_ES_STR: db "ES: ",0x00
.REGISTER_SS_STR: db "SS: ",0x00
.REGISTER_IP_STR: db "IP: ",0x00

.HEX_BUFFER: db "0x0000",0x00

%undef _REGISTER_NAME_COLOR
%undef _REGISTER_VALUE_COLOR
%unmacro _PRINT_SPACE 0
%unmacro _PRINT_NEW_LINE 0

; Converts a 16-bit integer to a string. In hexadecimal.
; IN: DX = 16-bit integer, SI = The place where the string will be put
; (note: 6 bytes required)
; OUT: Nothing
_itohex:
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