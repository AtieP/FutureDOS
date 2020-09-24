bits 16
cpu 8086
org 0

%define _KERNEL_SEGMENT 0x0800
%define _KERNEL_OFFSET 0x0000

%macro PRINT_DONE 0
    mov bl, 0x02
    mov si, DONE_STR
    call puts
%endmacro

%macro PRINT_FAIL 0
    mov bl, 0x04
    mov si, FAIL_STR
    call puts
%endmacro

%macro PRINT_TRACE 1
    mov bl, 0x0F
    mov si, %1
    call puts
%endmacro

kmain:

    mov ax, _KERNEL_SEGMENT
    mov ds, ax
    mov es, ax

    call init_cga

    PRINT_TRACE REMAPING_INTERRUPTS_STR
    call init_ivt
    PRINT_DONE

    PRINT_TRACE INITIALIZING_DRIVERS_STR
    call init_fs
    PRINT_DONE

    PRINT_TRACE LOADED_SUCCESSFULLY_STR


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

    sti

    pop ds
    pop ax
    ret


%include "kernel/drivers/cga.asm"
%include "kernel/drivers/filesystem.asm"
%include "kernel/drivers/keyboard.asm"

%include "kernel/lib/debug.asm"
%include "kernel/lib/keyboard.asm"
%include "kernel/lib/screen.asm"
%include "kernel/lib/string.asm"

%include "kernel/isr/isr0.asm"
%include "kernel/isr/isr3.asm"
%include "kernel/isr/isr6.asm"
%include "kernel/isr/isr8.asm"
%include "kernel/isr/isr9.asm"

DONE_STR: db " DONE",0x0A,0x0D,0x00
FAIL_STR: db " FAIL",0x0A,0x0D,0x00

INITIALIZING_DRIVERS_STR: db "Initializing drivers...",0x00
REMAPING_INTERRUPTS_STR: db "Remapping interrupts...",0x00
LOADED_SUCCESSFULLY_STR: db "FutureDOS started successfully.",0x00

times 2560 - ($ - $$) db 0
