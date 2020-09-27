bits 16
cpu 8086

; __FS_BIOS_PARAMETER_BLOCK: src/kernel/drivers/filesystem.asm

; Loads a file from the FAT12 filesystem into memory.
; IN: SI = Pointer to filename (8 bytes name, 3 bytes extension)
;     ES = Segment to load the file to
;     BX = Segment to load the file to
; OUT: Carry set if there was an error loading the file (file not found, disk error...)
fs_load_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
    pushf

    push cs
    pop ds

    mov [.file_segment], word es
    mov [.file_offset], word bx

    ; Load root dir
    push cs
    pop es

    mov ax, __FS_BIOS_PARAMETER_BLOCK.rootDirSect
    call _lba_to_chs

    mov ax, (2 << 8) | 1
    mov bx, keof
    int 13h

    jc .error

    test ah, ah
    jnz .error

    cmp al, 1
    jne .error

    ; Check if the file exists
    popf
    pop ds
    push ds
    pushf
    mov di, keof - 32

    cld

.check_if_file_exists:
    add di, 32
    mov al, [di]

    ; End
    test al, al
    jz .error

    ; Deleted entry
    cmp al, 0xE5
    je .check_if_file_exists

    push di
    push si

    mov cx, 12
    rep cmpsb

    pop si
    pop di

    test cx, cx
    jnz .check_if_file_exists

    mov ax, [di+26]

.load_file:
    ; Load the file

    push cs
    pop ds

    add ax, __FS_BIOS_PARAMETER_BLOCK.firstDataSect - 2
    call _lba_to_chs

    mov ax, [.file_segment]
    mov es, ax
    mov ax, (2 << 8) | 1
    mov bx, [.file_offset]
    int 13h

    jc .error

    test ah, ah
    jnz .error

    cmp al, 1
    jne .error

    jmp .finish

.error:
    popf
    stc
    jmp .return

.finish:
    popf
    clc

.return:
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


.file_segment: dw 0x0000
.file_offset: dw 0x0000

; IN: AX = Logical sector
; OUT: Correct data for int 13h
_lba_to_chs:
    push ds

    push cs
    pop ds

    xor dx, dx ; Upper word of division
    div word [__FS_BIOS_PARAMETER_BLOCK.sectsPerTrack]
    inc dl ; CHS sectors are 1-indexed
    mov cl, dl ; Head = lba % sectsPerTrack

    ; AX = lba / sectsPerTrack
    xor dx, dx ; Upper word of division
    div word [__FS_BIOS_PARAMETER_BLOCK.sides]
    mov dh, dl ; Cluster = lba / sectsPerTrack % sides
    mov ch, al ; Head = lba / sectsPerTrack / sides

    mov dl, [__FS_BIOS_PARAMETER_BLOCK.driveNo]
    pop ds
    ret
