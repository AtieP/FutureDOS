bits 16
cpu 8086
org 0x7c00


%macro defval 3 ; name, type, default val
%1 %2 %3
.val equ %3 
%endmacro

jmp short main
nop

oemID: db "FtrDOS  "
defval bytesPerSect, dw, 512
defval sectsPerCluster, db, 1
defval resvSects, dw, 1
defval numFats, db, 2
defval rootDirEnts, dw, 224
defval logSects, dw, 2880
defval mediaDescType, db, 0xF0 
defval sectsPerFat, dw, 9
defval sectsPerTrack, dw, 18
defval sides, dw, 2
defval hiddenSects, dd, 0
defval largeSects, dd, 0
defval driveNo, db, 0
defval reservedFlags, db, 0 ; Reserved
defval signature, db, 0x29
defval volID, dd, 0x1234ABCD
volLabel: db "FutureDOS  "
sysString: db "FAT12   "

firstFatSect equ resvSects.val
rootDirSect equ firstFatSect + (numFats.val * sectsPerFat.val)
rootSecs equ (rootDirEnts.val * 32 + bytesPerSect.val - 1) / bytesPerSect.val
firstDataSect equ rootDirSect + rootSecs
kernelSegment equ 0x800

main:
    ; set data segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    
    ; set up the stack
    cli
    mov ax, 0x9000
    mov ss, ax
    mov sp, 0xffff
    sti

    ; set data segment to be equal to code segment
    push cs
    pop ds

    ; save drive number
    mov [driveNo], dl
    
    ; int 0x13, ah=8: get drive information
    ; input dl = drive index
    ; dh = last head = num heads - 1
    ; cx[0:5] = sectors per track (starting from 1)
	mov ah, 8
	int 0x13
	and cx, 0b111111
	mov [sectsPerTrack], cx ; NOTE: starts from 1
	mov dl, dh
    xor dh, dh
	add dx, 1 ; it's the index of the last head (0-based), so add 1
	mov [sides], dx

    push ds
    pop es

    mov bx, eof 
    mov ax, rootDirSect
    call readsect

    mov si, eof-32 ; start before since the first operation is an increment

    cld ; clear direction flag since it might be set at startup

    dirloop:
        add si, 32 ; go to the next entry
        mov al, [si]
        or al, al ; if first byte is 0, there are no more entries
        jz exit

        cmp al, 0xE5 ; if it's E5, skip this entry
        je dirloop

        mov di, kernString ; string to compare with the entry
        mov cx, 11
        rep cmpsb ; compare the strings, quit if a character differs or if we've completed

        ; set si to the start of the entry again: cx stores the number of characters after the first non-match
        add si, cx
        sub si, 11

        or cx, cx ; all characters matched, quit the loop; otherwise, continue
        jnz dirloop
    
    mov ax, [si+26] ; load with first sector of the file 


    read_loop:
        cli

        ; save current sector number
        push ax

        ; int 0x13, ah=2 writes in es:bx
        mov cx, kernelSegment
        push cx
        pop es

        add ax, firstDataSect-2
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
        xor dx, dx ; upper word of division
        div word [bytesPerSect]
        add ax, firstFatSect

        push dx ; sectoroffset{dx}


        ; write FAT data to conventional memory (after bootsector)
        push ds
        pop es

        mov bx, eof 
        call readsect

        mov si, eof
        pop dx ; sectoroffset{dx}
        add si, dx
        mov ax, [si] ; get word from sector address

        ; decode sector
        ; ax = table_value, dx = cluster
        pop dx ; cluster{dx}
        
        ; each cluster is 3 bytes, but little endian
        ; ABC DEF is stored as BC FA DE little endian
        ; converted to BE: even = FA BC, odd = DE FA
        ; to get the actual index, even = AND 0x0FFF (remove last), odd = >> 4 (remove first)
        and dl, 1
        jz .andval
        mov cl, 4
        shr ax, cl
        jmp .decodeend
        .andval:
        and ax, 0x0FFF
        .decodeend:
        

        ; TODO: handle bad sectors (0xFF7)
        cmp ax, 0xFF8 ; 0xFF8 and above = end of clusterchain
        jnge read_loop
    
    ; finished reading: jump to kernel
    jmp kernelSegment:0
       

;
    exit:
    jmp $


; in: ax = lba
; out: ah = status, al = sectors read, cf set on error (see int 13h, ah=2)
; logic taken from mikeos
readsect:
    push bx

    xor dx, dx ; upper word of division
    div word [sectsPerTrack]
    add dl, 01 ; CHS sectors are 1-indexed
    mov cl, dl ; head = lba % sectsPerTrack

    ; ax = lba / sectsPerTrack
    xor dx, dx ; upper word of division
    div word [sides]
    mov dh, dl ; cluster = lba / sectsPerTrack % sides
    mov ch, al ; head = lba / sectsPerTrack / sides

    pop bx

    mov ax, (2 << 8) | 1 ; 2 = bios number, 1 = sectors to read 
    mov dl, byte [driveNo] 

    int 0x13
    ret

err:
    jmp $

kernString: db "KERNEL  BIN"

memOff: dw 0

times (510-($-$$)) db 0
dw 0xAA55

eof:
