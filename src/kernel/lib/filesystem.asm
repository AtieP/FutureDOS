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

    mov bx, keof
    call fs_get_root_dir

    jc .error

    ; Check if the file exists
    popf
    pop ds
    push ds
    pushf
    mov di, keof - 32

    cld

.check_if_file_exists:
    add di, 32
    mov al, [es:di]

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

    mov ax, [es:di+26]

.load_cluster:
    push cs
    pop ds

    mov [.cluster], ax

    add ax, __FS_BIOS_PARAMETER_BLOCK.firstDataSect - 2
    call _lba_to_chs

    mov ax, [.file_segment]
    mov es, ax
    mov ax, (2 << 8) | 1
    mov bx, [.file_offset]
    int 13h
    add [.file_offset], word 512

    jc .error

    test ah, ah
    jnz .error

    cmp al, 1
    jne .error

    ; Table offset
    mov ax, [.cluster]
    mov bx, ax
    shr bx, 1
    add ax, bx

    ; Sector offset
    xor dx, dx
    div word [__FS_BIOS_PARAMETER_BLOCK.bytesPerSect]
    add ax, __FS_BIOS_PARAMETER_BLOCK.firstFatSect

    mov [.sector_offset], dx

    push cs
    pop es

    ; Load FAT
    ; Load only if it wasn't loaded
    cmp ax, [.current_fat_sector]
    je .dont_read_fat

    mov [.current_fat_sector], ax

    call _lba_to_chs

    mov ax, (2 << 8) | 1
    mov bx, keof
    int 13h

    jc .error

    test ah, ah
    jnz .error

    cmp al, 1
    jne .error

.dont_read_fat:
    mov si, keof
    mov dx, [.sector_offset]
    add si, dx
    mov ax, [si]

    mov dx, [.cluster]

    and dl, 1
    jz .and_value
    mov cl, 4
    shr ax, cl
    jmp .end_decoding

.and_value:
    and ax, 0x0FFF

.end_decoding:
    cmp ax, 0x0FF8
    jnge .load_cluster

    jmp .finish

.error:
    popf
    stc
    jmp .return

.finish:
    popf
    clc

.return:
    push cs
    pop ds

    mov [.current_fat_sector], word -1

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

.cluster: dw 0x0000
.sector_offset: dw 0x0000

.current_fat_sector: dw -1

; Returns the BPB data.
; IN: ES:DI = Place to put the BPB data
; OUT: Nothing
fs_get_bpb:
    push cx
    push si
    push di
    push ds

    push cs
    pop ds

    mov si, __FS_BIOS_PARAMETER_BLOCK

    mov cx, 59
    rep movsb

    pop ds
    pop di
    pop si
    pop cx
    ret

; Returns the root dir entries.
; IN: ES = Segment to the destination
;     BX = Offset to the destination
; OUT: Carry flag set on error
fs_get_root_dir:
    push ax
    push dx

    mov ax, __FS_BIOS_PARAMETER_BLOCK.rootDirSect
    call _lba_to_chs

    mov ax, (2 << 8) | 1
    int 13h

    jc .error

    test ah, ah
    jnz .error

    cmp al, 1
    jne .error

    jmp .success

.error:
    stc
    jmp .end

.success:
    clc

.end:
    pop dx
    pop ax
    ret

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
