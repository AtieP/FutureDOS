bits 16
cpu 8086
org 0

%define _KERNEL_SEGMENT 0x0800
%define _KERNEL_OFFSET 0x0000

%define _DEFAULT_FILE_NAME "TERMINALBIN"
%define _DEFAULT_FILE_SEGMENT 0x1000
%define _DEFAULT_FILE_OFFSET 0x0000

%macro _PRINT_DONE 0
    mov bl, 0x02
    mov si, _DONE_STR
    call puts
%endmacro

%macro _PRINT_FAIL 0
    mov bl, 0x04
    mov si, _FAIL_STR
    call puts
%endmacro

%macro _PRINT_TRACE 1
    mov bl, 0x0F
    mov si, %1
    call puts
%endmacro

kmain:

    mov ax, _KERNEL_SEGMENT
    mov ds, ax
    mov es, ax

    call init_cga

    _PRINT_TRACE .REMAPING_INTERRUPTS_STR
    call init_ivt
    _PRINT_DONE

    _PRINT_TRACE .INITIALIZING_DRIVERS_STR
    call init_fs
    _PRINT_DONE

    ; Load splash screen
    mov dx, 0x3D4   ; CGA CRTC Index Register
    mov al, 0x09    ; Maximum Scan Line Reigster
    out dx, al
    inc dx          ; CGA CRTC Data Port
    mov al, 0x03    ; 4 scan lines
    out dx, al

    push es
    mov ax, 0xb800
    mov es, ax
    xor bx, bx
    mov si, .SPLASH_SCREEN_FILE
    call fs_load_file
    pop es
    jc .load_default_file

    call getchar

.load_default_file:
    call init_cga

    _PRINT_TRACE .LOADING_DEFAULT_FILE_STR
    mov ax, _DEFAULT_FILE_SEGMENT
    mov es, ax
    mov bx, _DEFAULT_FILE_OFFSET
    mov si, .DEFAULT_FILE
    call fs_load_file
    jc .file_load_error

    _PRINT_DONE

    mov si, .LOADED_SUCCESSFULLY_STR
    mov bl, 0x0F
    call puts

    ; Call the program, if it returns then hang
    call _DEFAULT_FILE_SEGMENT:_DEFAULT_FILE_OFFSET
    jmp hang

.file_load_error:
    _PRINT_FAIL
    mov si, .file_load_error.FILE_NOT_FOUND_STR
    mov bl, 0x0F
    call puts
    jmp hang

; Note: please change this string if _DEFAULT_FILE_NAME is changed too
.file_load_error.FILE_NOT_FOUND_STR: db "File TERMINAL.BIN not found",0x00

.INITIALIZING_DRIVERS_STR: db "Initializing drivers...",0x00
.REMAPING_INTERRUPTS_STR: db "Remapping interrupts...",0x00
.LOADING_DEFAULT_FILE_STR: db "Loading default file...",0x00
.LOADED_SUCCESSFULLY_STR: db "FutureDOS started successfully.",0x0A,0x0A,0x0D,0x00

.DEFAULT_FILE: db _DEFAULT_FILE_NAME
.SPLASH_SCREEN_FILE: db "SPLASH  CGA"

hang:
    hlt
    jmp hang


init_ivt:
    push ax
    push ds

    xor ax, ax
    mov ds, ax

    cli

    mov [0x00], word isr0
    mov [0x02], word cs

    mov [0x0C], word isr3
    mov [0x0E], word cs

    mov [0x18], word isr6
    mov [0x1A], word cs

    mov [0x20], word isr8
    mov [0x22], word cs

    mov [0x24], word isr9
    mov [0x26], word cs

    mov [0x3F4], word isrFD
    mov [0x3F6], word cs

    sti

    pop ds
    pop ax
    ret


%include "kernel/drivers/cga.asm"
%include "kernel/drivers/filesystem.asm"
%include "kernel/drivers/keyboard.asm"

%include "kernel/lib/debug.asm"
%include "kernel/lib/filesystem.asm"
%include "kernel/lib/keyboard.asm"
%include "kernel/lib/screen.asm"

%include "kernel/isr/isr0.asm"
%include "kernel/isr/isr3.asm"
%include "kernel/isr/isr6.asm"
%include "kernel/isr/isr8.asm"
%include "kernel/isr/isr9.asm"
%include "kernel/isr/isrFD.asm"

_DONE_STR: db " DONE",0x0A,0x0D,0x00
_FAIL_STR: db " FAIL",0x0A,0x0D,0x00

times 4096 - ($ - $$) db 0

keof:
