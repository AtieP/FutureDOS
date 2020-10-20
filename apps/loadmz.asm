org 0
bits 16
cpu 8086

EXE_START_SEGMENT equ ((LOADMZ_END - LOADMZ_START + 15) / 16)

LOADMZ_START:

; Primitive MZ loader. Does not handle EXE files larger than 64kb.
load_mz:
	mov dx, cs

	; Go forward until argument (first char after space).
.find_arg:
	lodsb
	cmp al, " "
	je .arg_found
	test al, al
	jz .errRead
	jmp .find_arg

.arg_found:
	mov bx, EXE_START_SEGMENT
	add bx, dx
	mov es, bx
	xor bx, bx
	mov ah, 0x07
	int 0xFD
	
	jc .errRead
	cmp word [es:bx], 0x5A4D
	jne .errMagic
	mov ax, [es:bx + 0x14]
	mov [cs:MZ_JUMP_IP], ax
	mov ax, [es:bx + 0x16]
	add ax, EXE_START_SEGMENT
	add ax, dx
	add ax, [es:bx + 0x08]
	mov [cs:MZ_JUMP_SG], ax
	mov sp, [es:bx + 0x10]
	mov ax, [es:bx + 0x0E]
	add ax, EXE_START_SEGMENT
	add ax, dx
	add ax, [es:bx + 0x08]
	mov ss, ax
	mov cx, [es:bx + 0x06]
	mov bp, [es:bx + 0x18]
.relocationLoop:
	mov ax, [es:bp + 2]
	add ax, EXE_START_SEGMENT
	add ax, dx
	add ax, [es:bx + 0x08]
	mov ds, ax
	mov ax, [es:bx + 0x08]
	mov si, [es:bp + 0]
	add word [ds:si], EXE_START_SEGMENT
	add word [ds:si], dx
	add word [ds:si], ax
	add bp, 4
	loop .relocationLoop
MZ_JUMP_IP equ ($ + 1)
MZ_JUMP_SG equ ($ + 3)
	jmp 0:0
.errMagic:
    push cs
    pop ds
	mov ah, 0x06
	mov si, MSG_INVALID_MAGIC
	mov bl, 0x04
	int 0xFD
	retf
.errRead:
    push cs
    pop ds
	mov ah, 0x06
	mov si, MSG_READ_FAIL
	mov bl, 0x04
	int 0xFD
	retf
	
MSG_INVALID_MAGIC: db "Invalid MZ signature.", 0
MSG_READ_FAIL: db "Failed to read file.", 0

LOADMZ_END:
