; 8259 Programmable Interrupt Controller related functions

; Remaps the 8259 Programmable Interrupt Controller.
; IN: Nothing
; OUT: Nothing
pic_init:
	push ax
	pushf

	cli

	; Get current mask
	in al, 0x21
	mov [.master_mask], al

	; Restart
	mov al, 0x11
	out 0x20, al

	xor al, al
	out 0x80, al

	; Set master PIC offset to 0x08
	mov al, 0x08
	out 0x21, al

	xor al, al
	out 0x80, al

	; Set cascading
	mov al, 0x04
	out 0x21, al

	xor al, al
	out 0x80, al

	; Done
	mov al, 0x01
	out 0x21, al

	xor al, al
	out 0x80, al

	; Recover mask
	mov al, [.master_mask]
	; And enable IRQ 0 and IRQ 1
	and al, -4
	out 0x21, al

	xor al, al
	out 0x80, al

	sti
	popf
	pop ax
	ret

.master_mask: db 0x00 ; Temporary buffer
