bits 16
cpu 8086

; keof: src/kernel/kernel.asm

; This macro creates a .val children with the default value, so you don't have to compute it at runtime
%macro __DEFINE_VALUE 3 ; defval <name>, <type>, <default value>
%1 %2 %3
%1.val equ %3
%endmacro

; The values are uninitialized
; They are initialized in init_fs
__FS_BIOS_PARAMETER_BLOCK:
          .oemID: db "FtrDOS  "
__DEFINE_VALUE .bytesPerSect, dw, 512
__DEFINE_VALUE .sectsPerCluster, db, 1
__DEFINE_VALUE .resvSects, dw, 1
__DEFINE_VALUE .numFats, db, 2
__DEFINE_VALUE .rootDirEnts, dw, 224
__DEFINE_VALUE .logSects, dw, 2880
__DEFINE_VALUE .mediaDescType, db, 0xF0
__DEFINE_VALUE .sectsPerFat, dw, 9
__DEFINE_VALUE .sectsPerTrack, dw, 18
__DEFINE_VALUE .sides, dw, 2
__DEFINE_VALUE .hiddenSects, dd, 0
__DEFINE_VALUE .largeSects, dd, 0
__DEFINE_VALUE .driveNo, db, 0
__DEFINE_VALUE .reservedFlags, db, 0
__DEFINE_VALUE .signature, db, 0x29
__DEFINE_VALUE .volID, dd, 0x1234ABCD
          .volLabel: db "FutureDOS  "
          .sysString: db "FAT12   "

%unmacro __DEFINE_VALUE 0

; Computed constants: it's possible to avoid calculating them at runtime
.firstFatSect equ __FS_BIOS_PARAMETER_BLOCK.resvSects.val
.rootDirSect equ .firstFatSect + (__FS_BIOS_PARAMETER_BLOCK.numFats.val * __FS_BIOS_PARAMETER_BLOCK.sectsPerFat.val)
.rootSecs equ (__FS_BIOS_PARAMETER_BLOCK.rootDirEnts.val * 32 + __FS_BIOS_PARAMETER_BLOCK.bytesPerSect.val - 1) / __FS_BIOS_PARAMETER_BLOCK.bytesPerSect.val
.firstDataSect equ .rootDirSect + .rootSecs


; Initializes the filesystem driver.
; IN/OUT: Nothing
init_fs:
    push cx
    push si
    push di
    push ds
    push es

    push cs
    pop es

    xor cx, cx
    mov ds, cx

    mov si, 0x7c00 + 3
    mov di, __FS_BIOS_PARAMETER_BLOCK

    mov cx, 59
    rep movsb

    pop es
    pop ds
    pop di
    pop si
    pop cx
    ret


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

    mov cx, 11
    rep cmpsb

    add di, cx
    sub di, 11

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
