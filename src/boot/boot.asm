bits 16
cpu 8086
org 0x7c00

; This macro creates a .val children with the default value, so you don't have to compute it at runtime
%macro DefineVal 3 ; defval <name>, <type>, <default value>
%1 %2 %3
%1.val equ %3
%endmacro

jmp short main
nop

BPB:
          .oemID: db "FtrDOS  "
DefineVal .bytesPerSect, dw, 512
DefineVal .sectsPerCluster, db, 1
DefineVal .resvSects, dw, 1
DefineVal .numFats, db, 2
DefineVal .rootDirEnts, dw, 224
DefineVal .logSects, dw, 2880
DefineVal .mediaDescType, db, 0xF0
DefineVal .sectsPerFat, dw, 9
DefineVal .sectsPerTrack, dw, 18
DefineVal .sides, dw, 2
DefineVal .hiddenSects, dd, 0
DefineVal .largeSects, dd, 0
DefineVal .driveNo, db, 0
DefineVal .reservedFlags, db, 0
DefineVal .signature, db, 0x29
DefineVal .volID, dd, 0x1234ABCD
          .volLabel: db "FutureDOS  "
          .sysString: db "FAT12   "

; Computed constants: it's possible to avoid calculating them at runtime
.firstFatSect equ BPB.resvSects.val
.rootDirSect equ .firstFatSect + (BPB.numFats.val * BPB.sectsPerFat.val)
.rootSecs equ (BPB.rootDirEnts.val * 32 + BPB.bytesPerSect.val - 1) / BPB.bytesPerSect.val
.firstDataSect equ .rootDirSect + .rootSecs

; Kernel load segment
kernelSegment equ 0x800

main:
    ; Set data segments
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Set stack
    cli
    mov ax, 0x9000
    mov ss, ax
    mov sp, 0xffff
    sti

    ; Save drive number
    mov [BPB.driveNo], dl

    ; Detect drive geometry if on hard drive
    or dl, dl
    jz .skipHdd

    ; INT 0x13, AH=8: Get drive information
    ; Input: DL = drive index
    ; Output:
    ;   DH = last head = num heads - 1
    ;   CX[0:5] = sectors per track (starting from 1)
	  mov ah, 8
	  int 0x13
	  and cx, 0b111111
	  mov [BPB.sectsPerTrack], cx ; NOTE: starts from 1
	  mov dl, dh
    xor dh, dh
	  inc dx ; It's the index of the last head (0-based), so add 1
	  mov [BPB.sides], dx

.skipHdd:

    mov bx, eof
    mov ax, BPB.rootDirSect
    call readsect

    mov si, eof-32 ; Start before since the first operation is an increment

    cld ; Clear direction flag since it might be set at startup

dirloop:
    add si, 32 ; Go to the next entry
    mov al, [si]
    or al, al ; If first byte is 0, there are no more entries
    jz file_not_found

    cmp al, 0xE5 ; If it's E5, skip this entry
    je dirloop

    mov di, kernString ; String to compare with the entry
    mov cx, 11
    rep cmpsb ; Compare the strings, quit if a character differs or if we've completed (similar to memcmp)

    ; Set SI to the start of the entry again: cx stores the number of characters after the first non-match
    add si, cx
    sub si, 11

    or cx, cx ; If all characters matched, quit the loop; otherwise, continue
    jnz dirloop

    mov ax, [si+26] ; First sector of the file

read_loop:
    cli

    ; Save current sector number
    push ax

    ; INT 0x13, AH=2 writes in ES:BX
    mov cx, kernelSegment
    push cx
    pop es

    add ax, BPB.firstDataSect-2
    mov bx, [memOff]
    call readsect
    add word [memOff], 512

        ; cluster{ax}
    pop ax
    push ax

    ; tableoffset{ax} = cluster{ax} * 1.5
    mov bx, ax
    shr bx, 1
    add ax, bx

    ; sector{ax} = firstFatSect + tableoffset{ax} / 512
    ; sectoroffset{dx} = tableoffset{ax} % 512
    xor dx, dx ; Upper word of division
    div word [BPB.bytesPerSect]
    add ax, BPB.firstFatSect

    push dx ; sectoroffset{dx}


    ; Write FAT data after bootsector
    push ds
    pop es

    ; AX = LBA sector
    ; Optimization: load only if not already in memory
    cmp ax, [currFatSector]
    je .skipread
    mov [currFatSector], ax
    mov bx, eof
    call readsect

.skipread:
    mov si, eof
    pop dx ; sectoroffset{dx}
    add si, dx
    mov ax, [si] ; Get raw word from sector address

    ; Decode sector
    ; AX = table_value, DX = cluster
    pop dx ; cluster{dx}

    ; Each cluster is 3 bytes, but little endian
    ; ABC DEF is stored as BC FA DE in memory
    ; converted to BE (how it's stored in registers):
    ;   even = FA BC, odd = DE FA
    ; to get the actual index, even = remove nybble (AND 0x0FFF), odd = remove first nybble (>> 4)
    and dl, 1
    jz .andval
    mov cl, 4
    shr ax, cl
    jmp .decodeend

.andval:
    and ax, 0x0FFF

.decodeend:

    ; TODO: Handle bad sectors (0xFF7)
    cmp ax, 0xFF8 ; 0xFF8 and above = End of clusterchain
    jnge read_loop

    ; Finished reading: jump to kernel
    sti
    jmp kernelSegment:0

; Input: AX = LBA sector
; Output: AH = status, AL = sectors read, CF set on error (see INT 0x13, AH=2)
readsect:
    xor dx, dx ; Upper word of division
    div word [BPB.sectsPerTrack]
    inc dl ; CHS sectors are 1-indexed
    mov cl, dl ; head = lba % sectsPerTrack

    ; ax = lba / sectsPerTrack
    xor dx, dx ; Upper word of division
    div word [BPB.sides]
    mov dh, dl ; cluster = lba / sectsPerTrack % sides
    mov ch, al ; head = lba / sectsPerTrack / sides

    mov ax, (2 << 8) | 1 ; 2 = BIOS call number, 1 = sectors to read
    mov dl, byte [BPB.driveNo]

    int 0x13

    jc disk_error

    test ah, ah
    jnz disk_error

    cmp al, 1
    jne disk_error

    ret

disk_error:
    mov si, .DISK_ERROR_STR
    call puts
    jmp $

.DISK_ERROR_STR: db "Disk error",0x00

file_not_found:
    mov si, .FILE_NOT_FOUND_STR
    call puts
    jmp $

.FILE_NOT_FOUND_STR: db "Kernel file not found (KERNEL.BIN)",0x00

; Prints a null-terminated string
; IN: Pointer to string in SI
; OUT: Nothing
puts:
    push cs
    pop ds

    mov ah, 0x0e

.print_each_char:
    lodsb
    test al, al
    jz .end
    int 10h
    jmp .print_each_char

.end:
    ret

kernString: db "KERNEL  BIN"

memOff: dw 0 ; Current kernel loading offset
currFatSector: dw -1 ; Last FAT sector which was read

times (510-($-$$)) db 0
dw 0xAA55

eof:
