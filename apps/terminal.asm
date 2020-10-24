bits 16
cpu 8086

main:
    push cs
    pop ds
    push cs
    pop es

.read_loop:
    call clear_buffers

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

    ; If the first byte is 0 == the user just pressed ENTER
    mov al, [di]
    test al, al
    jz .read_loop

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

    mov si, DATA.COMMANDS.DIR
    mov cx, DATA.COMMANDS.DIR.LEN
    call str_startswith
    jnc .ls

    ; Check if the input is a file
    ; Convert a "dot-file" into a "FAT file"
    ; Example:
    ; file.bin -> FILE    BIN
    mov di, DATA.FILENAME_BUFFER
    mov si, DATA.BUFFER
    mov ah, 0x0C
    int 0xFD
    jc .error

.load_file:
    cld
    ; Make sure it ends on .BIN
    mov si, DATA.FILENAME_BUFFER + 8
    mov di, DATA.BIN_EXT_STR
    mov cx, 4
    rep cmpsb

    test cx, cx
    jnz .test_executable_without_ext

    push es
    mov si, DATA.FILENAME_BUFFER
    mov ax, 0x2000 ; 64 KB after the current segment (0x2000)
    mov es, ax
    xor bx, bx
    mov ah, 0x07
    int 0xFD
    pop es
    jnc .jump_to_app
    jmp .error

.test_executable_without_ext:
    ; Add BIN at the end of the filename buffer, perhaps the input is an executable without extension
    ; First check if the last 3 bytes are empty
    mov di, DATA.FILENAME_BUFFER + 8
    mov cx, 4
    mov al, " "
    rep scasb

    test cx, cx
    jnz .error

    ; If they're empty, put BIN at the end
    mov si, DATA.FILENAME_BUFFER + 8
    mov [si], word "BI"
    mov [si+2], byte "N"

    push es
    mov si, DATA.FILENAME_BUFFER
    mov ax, 0x2000 ; 64 KB after the current segment (0x2000)
    mov es, ax
    xor bx, bx
    mov ah, 0x07
    int 0xFD
    pop es
    jnc .jump_to_app
    jmp .error

.jump_to_app:

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

.ls:
    mov ah, 0x09
    mov bx, eof
    int 0xFD
    jc .ls.error

    mov ah, 0x06
    mov si, .ls.HEADER_STR
    mov bl, [DATA.NORMAL_COLOR]
    int 0xFD

    mov ah, 0x05

    mov si, eof - 32
    cld

.ls.parse_root_dir:
    add si, 32
    mov al, [si]

    test al, al
    jz .ls.end

    cmp al, 0xE5
    je .ls.parse_root_dir

    push si
    
    ; Print name
    mov cx, 8

.ls.print_name:
    lodsb
    int 0xFD
    loop .ls.print_name

    ; Print 3 spaces
    mov al, " "
    mov cx, 3

.ls.print_spaces_1:
    int 0xFD
    loop .ls.print_spaces_1

    ; Print extension
    mov cx, 3

.ls.print_extension:
    lodsb
    int 0xFD
    loop .ls.print_extension

    ; Print 3 spaces
    mov al, " "
    mov cx, 3

.ls.print_spaces_2:
    int 0xFD
    loop .ls.print_spaces_2

    sub si, 11

    ; Print the attribute, depending of the type
    ; 0x01 = Read only
    ; 0x02 = Hidden
    ; 0x04 = System
    ; 0x08 = Volume ID
    ; 0x10 = Directory
    ; 0x20 = Archive
    mov al, [si+11]

    cmp al, 0x01
    je .ls.read_only

    cmp al, 0x02
    je .ls.hidden

    cmp al, 0x04
    je .ls.system

    cmp al, 0x08
    je .ls.volume_id

    cmp al, 0x10
    je .ls.directory

    cmp al, 0x20
    je .ls.archive

    ; Print ???
    mov al, "?"
    int 0xFD
    int 0xFD
    int 0xFD

    jmp .ls.print_size

.ls.read_only:
    mov al, "R"
    int 0xFD
    jmp .ls.print_size

.ls.hidden:
    mov al, "H"
    int 0xFD
    mov al, "I"
    int 0xFD
    mov al, "D"
    int 0xFD
    jmp .ls.print_size

.ls.system:
    mov al, "S"
    int 0xFD
    mov al, "Y"
    int 0xFD
    mov al, "S"
    int 0xFD
    jmp .ls.print_size

.ls.volume_id:
    mov al, "V"
    int 0xFD
    mov al, "I"
    int 0xFD
    mov al, "D"
    int 0xFD
    jmp .ls.print_size

.ls.directory:
    mov al, "D"
    int 0xFD
    mov al, "I"
    int 0xFD
    mov al, "R"
    int 0xFD
    jmp .ls.print_size

.ls.archive:
    mov al, "F"
    int 0xFD
    mov al, "I"
    int 0xFD
    mov al, "L"
    int 0xFD

    ; Print 9 spaces
    mov cx, 9
    mov al, " "
.ls.print_spaces_3:
    int 0xFD
    loop .ls.print_spaces_3

.ls.print_size:
    ; The whole operation:
    ; 1. ascii_number = (number % 10) + 0x30

    ; First convert to base 10 the lower part
    mov ax, [si+28]
    mov cx, 5
    mov di, .ls.SIZE_BUFFER + 9
    std
    push ax

.ls.print_size.loop_lower:
    pop ax
    push cx

    xor dx, dx
    mov cx, 10
    div cx

    pop cx
    push ax

    mov al, dl
    add al, 0x30
    stosb

    loop .ls.print_size.loop_lower
    
    pop dx ; Unused (popping previously pushed ax)

    ; And now the higher part
    mov ax, [si+30]
    mov cx, 5
    push ax

.ls.print_size.loop_higher:
    pop ax
    push cx

    xor dx, dx
    mov cx, 10
    div cx

    pop cx
    push ax

    mov al, dl
    add al, 0x30
    stosb

    loop .ls.print_size.loop_higher

    pop dx ; Unused (popping previously pushed ax)

    cld
    push si
    mov ah, 0x06
    mov si, .ls.SIZE_BUFFER
    int 0xFD
    pop si

    mov ah, 0x05

.ls.continue:
    pop si

    ; Print new line
    mov al, 0x0A
    int 0xFD
    mov al, 0x0D
    int 0xFD

    jmp .ls.parse_root_dir

.ls.end:
    jmp .read_loop

.ls.error:
    mov ah, 0x06
    mov bl, [DATA.ERROR_COLOR]
    mov si, .ls.error.STRING
    int 0xFD
    jmp .read_loop

.ls.error.STRING: db "Error while loading disk data",0x00

.ls.HEADER_STR:
    db "Name       Ext   Attribute   Size",0x0a,0x0d
    times 40 db 0xC4
    db 0x0A,0x0D,0x00

.ls.SIZE_BUFFER:
    times 10 db "0"
    db "B",0x00

DATA:
.PROMPT_STR: db "</> ",0x00
.NORMAL_COLOR: db 0x0F
.ERROR_COLOR: db 0x04
.BIN_EXT_STR: db "BIN",0x00
.BUFFER: times 127 db 0x00
.BUFFER.LEN: equ $ - .BUFFER - 1 ; Substract the NULL end byte
.FILENAME_BUFFER: times 11 db " "
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

; Clears the command buffer.
; IN/OUT: Nothing
clear_buffers:
    xor al, al
    mov cx, DATA.BUFFER.LEN
    mov di, DATA.BUFFER
    rep stosb
    mov al, " "
    mov di, DATA.FILENAME_BUFFER
    mov cx, 11
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
