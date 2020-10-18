org 0
bits 16
cpu 8086

EXE_START_SEGMENT equ 0x1923
PROGRAM_START_SEGMENT equ (EXE_START_SEGMENT + 3)

; Primitive MZ loader. Does not handle EXE files larger than 64kb.
load_mz:
	mov ax, cs
	add si, 12 ;ds:si at first points to the command buffer. We pass the argument which comes 12 chars later into the 0xFD syscall
	mov bx, EXE_START_SEGMENT
	mov es, bx
	xor bx, bx
	mov ah, 0x07
	int 0xFD
	cmp word [es:bx], 0x5A4D
	jne .errMagic
	mov ax, [es:bx + 0x14]
	mov [cs:MZ_JUMP_IP], ax
	mov ax, [es:bx + 0x16]
	add ax, PROGRAM_START_SEGMENT
	mov [cs:MZ_JUMP_SG], ax
	mov sp, [es:bx + 0x10]
	mov ax, [es:bx + 0x0E]
	add ax, PROGRAM_START_SEGMENT
	mov ss, ax
	mov cx, [es:bx + 0x06]
	mov bp, [es:bx + 0x18]
.relocationLoop:
	mov ax, [es:bp + 2]
	add ax, PROGRAM_START_SEGMENT
	mov ds, ax
	mov si, [es:bp + 0]
	add word [ds:si], PROGRAM_START_SEGMENT
	add bp, 4
	loop .relocationLoop
MZ_JUMP_IP equ ($ + 1)
MZ_JUMP_SG equ ($ + 3)
	jmp 0:0
.errMagic:
	mov ah, 0x06
	mov si, MSG_INVALID_MAGIC
	mov bl, 0x04
	int 0xFD
	retf
	
MSG_INVALID_MAGIC: db "Invalid MZ signature.", 0
