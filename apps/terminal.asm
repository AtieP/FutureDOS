bits 16
cpu 8086

main:
    push cs
    pop ds
    push cs
    pop es

.read_loop:
    call clear_buffer

    ; Print a new line
    mov ax, (0x05 << 8) | 0x0A
    mov bl, [DATA.NORMAL_COLOR]
    int 0xFD

    mov al, 0x0D
    int 0xFD

    ; Print prompt
    mov ah, 0x06
    mov si, DATA.PROMPT_STR
    int 0xFD

    ; Read input
    mov ah, 0x04
    mov di, DATA.BUFFER
    mov cx, DATA.BUFFER.LEN
    int 0xFD

    ; Check if the input is internal commands
    mov si, DATA.COMMANDS.ECHO
    mov cx, DATA.COMMANDS.ECHO.LEN
    call str_startswith
    jnc .echo

    mov si, DATA.COMMANDS.RESET
    mov cx, DATA.COMMANDS.RESET.LEN
    call str_startswith
    jnc .reset

    mov si, DATA.COMMANDS.LS
    mov cx, DATA.COMMANDS.LS.LEN
    call str_startswith
    jnc .ls

    mov si, DATA.COMMANDS.FETCH
    mov cx, DATA.COMMANDS.FETCH.LEN
    call str_startswith
    jnc .sysfetch

    mov si, DATA.COMMANDS.DIR
    mov cx, DATA.COMMANDS.DIR.LEN
    call str_startswith
    jnc .ls

    ; Check if the input is a file
    ; Convert a "dot-file" into a "FAT file"
    ; Example:
    ; file.bin -> FILE    BIN
    mov si, DATA.BUFFER
    mov di, DATA.FILENAME_BUFFER
    mov cx, -1
    cld

.to_fat_file:
    inc cx
    lodsb
    cmp cx, 12
    je .load_file
    cmp al, "."
    je .extension
    cmp al, " " ; Assume it's a bin
    je .bin
    test al, al ; Same thing
    jz .bin
    ; Convert to uppercase
    cmp al, "a"
    jb .already_uppercase
    cmp al, "z"
    ja .already_uppercase
    sub al, 20h
.already_uppercase:
    stosb
    jmp .to_fat_file

.extension:
    mov bx, 8
    mov dx, cx
    mov cx, 8
    sub bx, dx
    test bx, bx
    jz .to_fat_file
    mov al, " "

.pad_with_spaces:
    stosb
    dec bx
    jz .to_fat_file
    jmp .pad_with_spaces

.bin:
    cmp cx, 8
    je .put_bin_in_buffer
    mov al, " "
    stosb
    inc cx
    jmp .bin

.put_bin_in_buffer:
    mov ax, "BI"
    stosw
    mov al, "N"
    stosb
    jmp .load_file

.load_file:
    ; Make sure it ends on .BIN
    mov si, DATA.FILENAME_BUFFER + 8
    mov di, DATA.BIN_EXT_STR
    mov cx, 4
    rep cmpsb

    test cx, cx
    jnz .error

    push es
    mov si, DATA.FILENAME_BUFFER
    mov ax, 0x2000 ; 64 KB after the current segment (0x2000)
    mov es, ax
    xor bx, bx
    mov ah, 0x07
    int 0xFD
    pop es
    jc .error

    mov si, DATA.BUFFER

    call 0x2000:0x0000
    push cs
    pop ds
    push cs
    pop es

    jmp .read_loop

.error:
    ; Display error message
    mov ah, 0x06
    mov si, DATA.ERROR_MESSAGE
    mov bl, [DATA.ERROR_COLOR]
    int 0xFD

    jmp .read_loop

.echo:
    mov si, DATA.BUFFER
    add si, DATA.COMMANDS.ECHO.LEN
    inc si

    mov ah, 0x06
    int 0xFD
    jmp .read_loop

.reset:
    int 19h

.sysfetch:


.ls:
    mov ah, 0x09
    mov bx, eof
    int 0xFD
    jc .ls.error

    mov si, eof - 32
    mov di, .ls.BUFFER
    mov bl, [DATA.NORMAL_COLOR]
    mov ah, 0x06
    cld

.ls.parse_root_dir:
    add si, 32
    mov al, [si]

    test al, al
    jz .read_loop

    cmp al, 0xE5
    je .ls.parse_root_dir

    push si
    push di

    mov cx, 13
    rep movsb

    pop di

    ; Print filename
    mov si, di
    int 0xFD

    pop si

    ; Print a new line
    push ax
    push bx

    mov ax, (0x05 << 8) | 0x0A
    mov bl, [DATA.NORMAL_COLOR]
    int 0xFD

    mov al, 0x0D
    int 0xFD

    pop bx
    pop ax

    jmp .ls.parse_root_dir


.ls.BUFFER: times 14 db 0

.ls.error:
    mov ah, 0x06
    mov bl, [DATA.ERROR_COLOR]
    mov si, .ls.error.STRING
    int 0xFD
    jmp .read_loop

.ls.error.STRING: db "Error while loading disk data",0x00

DATA:
.PROMPT_STR: db "C:/> ",0x00
.NORMAL_COLOR: db 0x0F
.ERROR_COLOR: db 0x04
.BIN_EXT_STR: db "BIN",0x00
.BUFFER: times 127 db 0x00
.BUFFER.LEN: equ $ - .BUFFER - 1 ; Substract the NULL end byte
.FILENAME_BUFFER: times 13 db 0
.ERROR_MESSAGE: db "Invalid command or filename provided",0x00

.COMMANDS:
.COMMANDS.ECHO: db "echo"
.COMMANDS.ECHO.LEN: equ $ - .COMMANDS.ECHO
.COMMANDS.RESET: db "reset"
.COMMANDS.RESET.LEN: equ $ - .COMMANDS.RESET
.COMMANDS.LS: db "ls"
.COMMANDS.LS.LEN: equ $ - .COMMANDS.LS
.COMMANDS.DIR: db "dir"
.COMMANDS.DIR.LEN: equ $ - .COMMANDS.DIR
.COMMANDS.FETCH: db "sysfetch"
.COMMANDS.FETCH.LEN: equ $ - .COMMANDS.FETCH

; Clears the command buffer.
; IN/OUT: Nothing
clear_buffer:
    xor al, al
    mov cx, DATA.BUFFER.LEN
    mov di, DATA.BUFFER
    rep stosb
    ret

; Check if the string has the prefix.
; IN: DI = Original string, SI = Prefix, CX = Length of prefix
; OUT: Carry set if not
str_startswith:
    push ax
    push cx
    push si
    push di
    pushf

.check:
    mov al, [di]
    cmp al, [si]
    jne .mismatch

    dec cx
    jz .match

    inc si
    inc di
    jmp .check

.mismatch:
    popf
    stc
    jmp .end

.match:
    ; Also check if the last char is 0 or " "
    inc di
    mov al, [di]
    cmp al, " "
    je .success
    test al, al
    jne .mismatch

.success:
    popf
    clc

.end:
    pop di
    pop si
    pop cx
    pop ax
    ret

eof:
