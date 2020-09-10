%ifndef __DEBUG_ASM
%define __DEBUG_ASM

; Prints a register dump. To be able to print CS and IP, push them
; (first CS and then IP).
; Please note that there is no support for DS, ES, and SS.

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

    push si
    push dx
    push bx

    ; ------------------
    ; DUMP AX

    ; Convert AX value to ASCII
    mov si, .HEX_BUFFER
    mov dx, ax
    call itohex

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
    call itohex

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
    call itohex

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
    call itohex

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
    mov dx, sp
    ; Add 4 because SI and the return address is on the stack
    add dx, 4
    call itohex

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
    call itohex

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
    call itohex

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
    pop si
    mov dx, si
    mov si, .HEX_BUFFER
    call itohex

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
    ; DUMP CS

    ; Convert CS value to ASCII
    push bp
    mov bp, sp
    mov dx, [bp + 14]
    call itohex

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
    mov dx, [bp + 12]
    call itohex

    ; Print "IP: "
    mov si, .REGISTER_IP_STR
    mov bl, _REGISTER_NAME_COLOR
    call puts

    mov si, .HEX_BUFFER
    mov bl, _REGISTER_VALUE_COLOR
    call puts

    pop bp

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
.REGISTER_IP_STR: db "IP: ",0x00

.HEX_BUFFER: db "0x0000",0x00

%endif
