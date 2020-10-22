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

; Returns the file size.
; IN: DS:SI = Filename
; OUT: AX = Lower word of file size
;      DX = Higher word of file size
;      Carry set on error (file not found, disk error, ...)
fs_get_file_size:
    push di
    push es
    pushf

    push cs
    pop es

    mov di, __FS_TEMP_FILE_BUFFER
    call fs_get_file_info
    jc .error

    mov ax, [es:di+28]
    mov dx, [es:di+30]

.error:
    popf
    stc
    jmp .end

.success:
    popf
    clc
    jmp .end

.end:
    pop es
    pop di
    ret

; Returns the file's info.
; IN: DS:SI = Filename, ES:DI = 32 bytes for saving the file's info
; OUT: Carry set on error (file not found, disk error, ...)
; Relevant info: https://wiki.osdev.org/FAT12#Directories
fs_get_file_info:
    push ax
    push bx
    push cx
    push di
    push es
    pushf

    push cs
    pop es
    mov bx, keof
    call fs_get_root_dir
    jc .error

    mov di, keof - 32
    cld

.read_root_dir:
    add di, 32
    mov al, [es:di]

    test al, al
    jz .error

    cmp al, 0xE5
    je .read_root_dir

    push si
    push di

    mov cx, 12
    rep cmpsb

    pop di
    pop si

    test cx, cx
    jnz .read_root_dir

    mov si, di

    popf
    pop es
    pop di
    push di
    push es
    pushf
    push ds

    push cs
    pop ds

    mov cx, 32
    rep movsb

    pop ds

    jmp .success

.error:
    popf
    stc
    jmp .end

.success:
    popf
    clc
    jmp .end

.end:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Converts a filename into a valid FAT filename.
; IN: DS:SI = Filename, ES:DI = Destination (11 bytes, padded with spaces) (NULL or a space count as an end marker)
; OUT: Carry flag set on error (invalid char, too long, ...), clear on success
fs_filename_to_fat_filename:
    push ax
    push cx
    push dx
    push si
    push di
    pushf

    mov cx, 13
    xor dl, dl ; Set to 1 when extension is found

.read_loop:
    dec cx
    jz .success

    lodsb

    test al, al
    jz .success

    ; Check for forbidden characters
    ; Control characters
    cmp al, 0x1F
    jbe .error

    cmp al, 0x7F
    je .error

    ; Other
    cmp al, '"'
    je .error

    cmp al, "*"
    je .error

    cmp al, "+"
    je .error

    cmp al, ","
    je .error

    cmp al, "/"
    je .error

    cmp al, ":"
    je .error

    cmp al, 0x3B ; ;
    je .error

    cmp al, "<"
    je .error

    cmp al, "="
    je .error

    cmp al, ">"
    je .error

    cmp al, 0x5C ; Backslash
    je .error

    cmp al, "["
    je .error

    cmp al, "]"
    je .error

    cmp al, "|"
    je .error

    cmp al, " "
    je .success

    cmp al, "."
    je .extension

    cmp al, "a"
    jb .already_uppercase

    cmp al, "z"
    ja .already_uppercase

    sub al, 20h

.already_uppercase:
    stosb
    jmp .read_loop

.extension:
    cmp cx, 12
    je .error

    cmp dl, 1
    je .error

    mov dl, 1
    cmp cx, 4
    je .read_loop
    jl .error ; Something's wrong, there can't be an extension extension

    mov al, " "

.pad_with_spaces:
    stosb
    dec cx
    cmp cx, 4
    je .read_loop
    jmp .pad_with_spaces

.error:
    popf
    stc
    jmp .end

.success:
    popf
    clc
    jmp .end

.end:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

__FS_TEMP_FILE_BUFFER: times 32 db 0x00
