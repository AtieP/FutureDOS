bits 16
cpu 8086

; CGA text mode driver

db "FV" ; Magic number
dw 0x0000 ; FutureDOS version
dw 0x0000 ; No interrupt for this driver at all
dw cga_init
dw cga_raw_putc
dw cga_putc
dw cga_set_color
dw cga_get_color
dw cga_cursor_move
dw cga_clear_screen
dw cga_scroll

; Do not touch these variables externally
_cga_cursor_x: dw 0x0000
_cga_cursor_y: dw 0x0000
_cga_color: db 0x00
_cga_framebuffer_segment: dw 0x0000

; Initializes the driver.
; IN:
;    BL = Screen color
; OUT:
;    Nothing
cga_init:
    push ax
    push ds
    pushf

    push cs
    pop ds

    ; Set textmode if it wasn't already
    mov ax, 0x03
    int 0x10

    mov [_cga_cursor_x], word 0x0000
    mov [_cga_cursor_y], word 0x0000
    mov [_cga_color], bl

    ; Get the monitor type (monochrome or color)
    push es
    xor ax, ax
    mov es, ax

    mov al, [es:0x410]
    pop es
    and al, 0x30

    cmp al, 0x20
    je .color_monitor

    cmp al, 0x30
    je .monochrome_monitor

    ; Impossible.
    jmp $

.color_monitor:
    mov [_cga_framebuffer_segment], word 0xb800
    jmp .clear_screen

.monochrome_monitor:
    mov [_cga_framebuffer_segment], word 0xb000

.clear_screen:
    call cga_clear_screen

    popf
    pop ds
    pop ax
    ret

; Prints a char, as it is.
; IN:
;    BL = Char
; OUT:
;    Nothing
cga_raw_putc:
    push ax
    push bx
    push cx
    push di
    push ds
    push es

    push cs
    pop ds

    mov ax, [_cga_framebuffer_segment]
    mov es, ax

    mov ax, [_cga_cursor_y]
    mov cx, 80
    mul cx
    add ax, [_cga_cursor_x]
    shl ax, 1
    mov di, ax ; Framebuffer location

    mov ah, [_cga_color]
    mov al, bl

    mov [es:di], ax

    mov bx, [_cga_cursor_x]
    mov cx, [_cga_cursor_y]
    inc bx
    cmp bx, 80
    je .new_line
    call cga_cursor_move
    jmp .check_if_scroll

.new_line:
    xor bx, bx
    inc cx
    call cga_cursor_move

.check_if_scroll:
    cmp cx, 24
    jne .end
    call cga_scroll

.end:
    pop es
    pop ds
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Prints a char.
;
; Unlike cga_raw_putc, there's the ability to print special bytes, like
; 0x0A, 0x0D, 0x08, etc
;
; IN:
;    BL = Char
; OUT:
;    Nothing
cga_putc:
    push bx
    push cx
    push ds
    pushf

    push cs
    pop ds

    cmp bl, 0x08
    je .backspace

    cmp bl, 0x0A
    je .linefeed

    cmp bl, 0x0D
    je .carriage_return

    jmp .print

.backspace:
    mov bx, [_cga_cursor_x]
    mov cx, [_cga_cursor_y]
    test cx, cx
    je .backspace.first_line

.backspace.check_line:
    test bx, bx
    je .backspace.go_line_up
    dec bx
    call cga_cursor_move
    jmp .end

.backspace.go_line_up:
    dec cx
    mov bx, 79
    call cga_cursor_move
    jmp .end

.backspace.first_line:
    test bx, bx
    je .end ; Cannot go back
    jmp .backspace.check_line

.linefeed:
    mov bx, [_cga_cursor_x]
    mov cx, [_cga_cursor_y]
    inc cx
    cmp cx, 24
    je .linefeed.scroll
    call cga_cursor_move
    jmp .end

.linefeed.scroll:
    call cga_cursor_move
    call cga_scroll
    jmp .end

.carriage_return:
    xor bx, bx
    mov cx, [_cga_cursor_y]
    call cga_cursor_move
    jmp .end

.print:
    call cga_raw_putc

.end:
    popf
    pop ds
    pop cx
    pop bx
    ret

; Sets the color.
;
; Every time you print a char, the color is picked from an internal buffer.
; By using this function, you change the value from that internal buffer.
;
; IN:
;    BL = 8-bit color
; OUT:
;    Nothing
cga_set_color:
    push ds

    push cs
    pop ds

    mov [_cga_color], bl

    pop ds
    ret

; Gets the current color.
;
; IN:
;    Nothing
; OUT:
;    8-bit color in AX
cga_get_color:
    push ds

    push cs
    pop ds

    mov al, [_cga_color]
    xor ah, ah

    pop ds
    ret

; Moves the cursor position.
; IN:
;    BX = X position
;    CX = Y position
; OUT:
;    AX = 0x00 on success
;         0x01 if X is out of range
;         0x02 if Y is out of range
cga_cursor_move:
    push bx
    push cx
    push dx
    push ds
    pushf

    ; Test the positions
    cmp bx, 79
    jg .x_out_of_range

    cmp cx, 24
    jg .y_out_of_range

    ; Save
    push cs
    pop ds

    mov [_cga_cursor_x], bx
    mov [_cga_cursor_y], cx

    mov ax, cx
    mov dl, 80 ; Width
    mul dl
    add bx, ax

    ; Save the index
    push ds

    push cs
    pop ds

    pop ds

    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al

    inc dx
    mov al, bl
    out dx, al

    dec dx
    mov al, 0x0E
    out dx, al

    inc dx
    mov al, bh
    out dx, al

    xor ax, ax
    jmp .return

.x_out_of_range:
    mov ax, 0x01
    jmp .return

.y_out_of_range:
    mov ax, 0x02

.return:
    popf
    pop ds
    pop dx
    pop cx
    pop bx
    ret

; Clears the screen.
; IN:
;    BL = 8-bit color
; OUT:
;    Nothing
cga_clear_screen:
    push ax
    push bx
    push cx
    push ds

    push bx
    xor bx, bx
    xor cx, cx
    call cga_cursor_move
    pop bx

    push cs
    pop ds

    mov ax, [_cga_framebuffer_segment]
    mov ds, ax

    mov ah, bl
    xor al, al

    xor bx, bx
    mov cx, 2000

.fill_screen:
    mov [bx], ax
    add bx, 2
    loop .fill_screen

    pop ds
    pop cx
    pop bx
    pop ax
    ret

; Scrolls.
; IN:
;    Nothing
; OUT:
;    Nothing
cga_scroll:
    ; The operation is really simple, just move all lines up and clear last line
    push ax
    push bx
    push cx
    push si
    push di
    push ds

    push cs
    pop ds

    mov ax, [_cga_framebuffer_segment]
    mov ds, ax

    mov cx, 80 * 24
    xor di, di
    mov si, 160

.scroll:
    mov ax, [si]
    mov [di], ax
    add di, 2
    add si, 2
    loop .scroll

    push cs
    pop ds

    ; Move cursor up
    xor bx, bx
    mov cx, [_cga_cursor_y]
    dec cx
    call cga_cursor_move

    pop ds
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
