org 0
bits 16
cpu 8086

%macro Hang 0
%%1:
    hlt
    jmp %%1
%endmacro

kmain:

    push cs
    pop ds

.video_init:
    mov bl, 0x07
    call cga_init

.pic_init:
    mov si, pic_init_str
    call kputs

    call pic_init

    mov si, done_str
    call kputs

.ps2_init:
    mov si, ps2_init_str
    call kputs

    call ps2_init

    cmp ax, 1
    je .ps2_error

    cmp ax, 2
    je .ps2_no_mouse

    mov si, done_str
    call kputs

.keyb_init:
    mov si, ps2keybpc_init_str
    call kputs

    call ps2keybpc_init

    cmp ax, 1
    je .ps2_error

    mov si, done_str
    call kputs

    Hang

.ps2_error:
    ; Just restart
    mov al, 0xFE
    out 0x64, al
    jmp .ps2_error ; If it didn't work

.ps2_no_mouse:
    mov si, ps2_init_str.no_mouse
    call kputs

    jmp .keyb_init

kputs:
    push bx
    push si

.loop:
    mov bl, [si]
    test bl, bl
    jz .end
    call cga_putc
    inc si
    jmp .loop

.end:
    pop si
    pop bx
    ret

pic_init_str: db "Initializing the Programmable Interrupt Controller...",0x00
ps2_init_str: db "Initializing the PS/2 Controller...",0x00
ps2_init_str.no_mouse: db "Done!",0x0A,0x0D,"Warning: no mouse available",0x00
ps2keybpc_init_str: db "Initializing the PC Keyboard... ",0x00
done_str: db " Done!",0x0A,0x0D,0x00

%include "src/kernel/devices/cga.asm"
%include "src/kernel/devices/ps2.asm"
%include "src/kernel/devices/ps2keybpc.asm"
%include "src/kernel/sys/pic.asm"

times 4096 - ($ - $$) db 0x00