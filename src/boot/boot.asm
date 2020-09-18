bits 16
cpu 8086
org 0x7c00

%define _SECTORS_TO_READ 5
%define _KERNEL_SEGMENT 0x0800
%define _KERNEL_OFFSET 0x0000

jmp short main
nop

OEMID: db "mkdosfs "
BYTES_PER_SECTOR: dw 512
SECTORS_PER_CLUSTER: db 1
RESERVED_SECTORS: dw 6
NUMBER_OF_FATS: db 2
ROOT_DIR_ENTRIES: dw 224
LOGICAL_SECTORS: dw 2880
MEDIA_DESCRIPTOR_TYPE: dw 0xF0 ; https://infogalactic.com/info/Design_of_the_FAT_file_system#media
SECTORS_PER_FAT: dw 9
SECTORS_PER_TRACK: dw 18
SIDES: dw 2
HIDDEN_SECTORS: dd 0
LARGE_SECTORS: dd 0
DRIVE_NUMBER: db 0
FLAGS: db 0 ; Reserved
SIGNATURE: db 0x29
VOLUME_ID: dd 0x00001412
VOLUME_LABEL: db "FUTUREDOS  "
SYSTEM_ID_STRING: db "FAT12   "

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
