bits 16
cpu 8086
org 0x7c00

%define _SECTORS_TO_READ 2
%define _KERNEL_SEGMENT 0x0800
%define _KERNEL_OFFSET 0x0000

jmp short main
nop

SECTORS_PER_TRACK: dw 18
SIDES: dw 2
DRIVE_NUMBER: db 0

main:

    cli
    mov ax, eof + 40
    mov sp, ax
    mov bp, ax
    sti

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov [DRIVE_NUMBER], byte dl

    ; Reset
    xor ax, ax
    int 13h

    ; Read sectors
    mov ax, 1
    call lba_to_chs

    push es
    mov ax, _KERNEL_SEGMENT
    mov es, ax

    mov ax, 2 * 256 + _SECTORS_TO_READ
    mov bx, _KERNEL_OFFSET
    int 13h

    pop es

    ; Test if everything went okay
    jc disk_error

    test ah, ah
    jnz disk_error

    cmp al, _SECTORS_TO_READ
    jne disk_error

    jmp _KERNEL_SEGMENT:_KERNEL_OFFSET

lba_to_chs:

    push bx
    push ax

    mov bx, ax

    ; Sector
    xor dx, dx
    div word [SECTORS_PER_TRACK]
    inc dl
    mov cl, dl

    ; Head
    mov ax, bx
    xor dx, dx
    div word [SECTORS_PER_TRACK]
    xor dx, dx
    div word [SIDES]
    mov dh, dl
    mov ch, al

    pop ax
    pop bx

    mov dl, [DRIVE_NUMBER]
    ret

; Error routines
disk_error:
    mov ax, 0e0eh
    int 10h
    jmp $

times 510 - ($ - $$) db 0x00
dw 0xAA55

eof:
