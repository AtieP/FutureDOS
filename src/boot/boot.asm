org 0x7c00
bits 16
cpu 8086

jmp short main
nop

%define kernel_segment 0x0800
%define kernel_offset 0x0000

%macro DefineValue 3
%1 %2 %3
%1.value: equ %3
%endmacro

bios_parameter_block:
.oem_id: db "FtrDOS  "
DefineValue .bytes_per_sector, dw, 512
DefineValue .sectors_per_cluster, db, 1
DefineValue .reserved_sectors, dw, 1
DefineValue .number_of_fats, db, 2
DefineValue .root_dir_entries, dw, 224
DefineValue .logical_sectors, dw, 2880
DefineValue .media_descriptor_type, db, 0xF0
DefineValue .sectors_per_fat, dw, 9
DefineValue .sectors_per_track, dw, 18
DefineValue .sides, dw, 2
DefineValue .hidden_sectors, dd, 0
DefineValue .large_sectors, dd, 0
DefineValue .drive_number, db, 0 ; Uninitialized
DefineValue .reserved, db, 0
DefineValue .signature, db, 0x29
DefineValue .volume_id, dd, 0x14031412
.volume_label: db "FutureDOS  "
.system_string: db "FAT12   "

first_fat_sector: equ bios_parameter_block.reserved_sectors.value
root_dir_sector: equ first_fat_sector + (bios_parameter_block.number_of_fats.value * bios_parameter_block.sectors_per_fat.value)
root_sectors: equ (bios_parameter_block.root_dir_entries.value * 32 + bios_parameter_block.bytes_per_sector.value - 1) / bios_parameter_block.bytes_per_sector.value
first_data_sector: equ root_dir_sector + root_sectors

main:
	xor ax, ax
	mov ds, ax
	mov es, ax

	mov [bios_parameter_block.drive_number], dl

	test dl, dl
	jz .load_kernel

	; Not a floppy, get drive information
	mov ah, 0x08
	int 0x13
	and cx, 0b111111
	mov [bios_parameter_block.sectors_per_track], cx
	mov dl, dh
	xor dh, dh
	inc dx
	mov [bios_parameter_block.sides], dx

.load_kernel:
	; First, load the root dir, and search for the kernel entry
	mov ax, root_dir_sector
	mov bx, eof
	call load_sector

	mov si, eof - 32
	mov di, kernel_filename
	cld
	cli ; Intentional

.find_kernel:
	add si, 32
	mov al, [si]

	test al, al
	jz .kernel_not_found

	cmp al, 0xE5
	je .find_kernel

	push si
	push di
	mov cx, 12
	rep cmpsb
	pop di
	pop si

	test cx, cx
	jnz .find_kernel

	mov ax, [si+26]

.load_cluster:
	push ax

	add ax, first_data_sector - 2
	mov cx, kernel_segment
	mov es, cx
	mov bx, [.memory_offset]
	call load_sector
	add [.memory_offset], word 512

	pop ax ; Cluster
	push ax

	; Get table offset{ax} (cluster * 1.5)
	mov bx, ax
	shr bx, 1
	add ax, bx

	; Sector{ax} (first_fat_sector + table offset{ax} / 512)
	; Sector offset{dx} (table offset{dx} % 512)
	xor dx, dx
	div word [bios_parameter_block.bytes_per_sector]
	add ax, first_fat_sector

	push dx ; Sector offset

	cmp ax, [.current_fat_sector]
	je .do_not_load_fat

	mov [.current_fat_sector], ax
	mov bx, eof
	push cs
	pop es
	call load_sector

.do_not_load_fat:
	mov si, eof
	pop dx ; Sector offset
	add si, dx
	mov ax, [si]

	pop dx ; Cluster

	; Decode sector
	; Each cluster is 3 bytes, but little endian
	; ABC DEF is stored as BC FA DE in memory
	; converted to BE (how it's stored in registers):
	;   even = FA BC, odd = DE FA
	; to get the actual index, even = remove nybble (AND 0x0FFF), odd = remove first nybble (>> 4)
	and dl, 1
	jz .and_value
	mov cl, 4
	shr ax, cl
	jmp .end_decoding

.and_value:
	and ax, 0x0FFF

.end_decoding:
	cmp ax, 0xFF8
	jnge .load_cluster

	jmp kernel_segment:kernel_offset

.kernel_not_found:
	mov si, .kernel_not_found_string
	call print_string
	call restart

.kernel_not_found_string: db "KERNEL.BIN not found!",0x00

.memory_offset: dw kernel_offset
.current_fat_sector: dw 0x0000

; Functions

; Prints a string
; IN: DS:SI = String
; OUT: Nothing
print_string:
	mov ah, 0x0E

.print_char_loop:
	lodsb
	test al, al
	jz .end
	int 0x10
	jmp .print_char_loop

.end:
	ret

; Waits for user input and restarts the computer (never returns)
; IN: Nothing
; OUT: Nothing
restart:
	cli
	mov si, .restart_string
	call print_string

	xor ah, ah
	int 0x16

	mov al, 0x02

.check_empty_buffer:
	and al, 0x20
	jz .send_reset_byte
	in al, 0x64
	jmp .check_empty_buffer

.send_reset_byte:
	mov al, 0xFE
	out 0x64, al

	; Should not happen
.halt_loop:
	hlt
	jmp .halt_loop ; In case of a NMI

.restart_string: db 0x0A,0x0D,"Press any key to restart...",0x00

; Loads a sector.
; IN: AX = LBA Sector, ES:BX = Place to put the data
; OUT: int 0x13, ah 0x02 return data (doesn't return if carry set, or other error)
load_sector:
	; LBA to CHS
	xor dx, dx
	div word [bios_parameter_block.sectors_per_track]
	inc dl
	mov cl, dl

	xor dx, dx
	div word [bios_parameter_block.sides]
	mov dh, dl
	mov ch, al

	mov ax, (2 << 8) | 1 ; 2: int 13h service number, 1: sectors to read
	mov dl, [bios_parameter_block.drive_number]
	int 0x13

	jc .disk_error

	test ah, ah
	jnz .disk_error

	cmp al, 1
	jne .disk_error

	ret

.disk_error:
	mov si, .disk_error_string
	call print_string
	call restart

.disk_error_string: db "Disk error",0x00

; Other data
kernel_filename: db "KERNEL  BIN"

times 510 - ($ - $$) db 0x00
dw 0xAA55

eof:
