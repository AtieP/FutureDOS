; All the calls here are from src/kernel/lib

; Handler for FutureDOS' library call interrupt (int FDh)
; print_register_dump is not included because it will be useless, AX is overwritten when
; specifying the service number; Use int3 instead
isrFD:
    pushf
    push ax

    dec ah
    jz .ah_1

    dec ah
    jz .ah_2

    dec ah
    jz .ah_3

    dec ah
    jz .ah_4

    dec ah
    jz .ah_5

    dec ah
    jz .ah_6

    dec ah
    jz .ah_7

    dec ah
    jz .ah_8

    dec ah
    jz .ah_9

    jmp .error

.ah_1:
    pop ax
    popf
    call getchar
    jmp .end

.ah_2:
    pop ax
    popf
    call getcharp
    jmp .end

.ah_3:
    pop ax
    popf
    call gets
    jmp .end

.ah_4:
    pop ax
    popf
    call getsp
    jmp .end

.ah_5:
    pop ax
    popf
    call putc
    jmp .end

.ah_6:
    pop ax
    popf
    call puts
    jmp .end

.ah_7:
    pop ax
    popf
    call fs_load_file
    jmp .set_or_clear_carry

.ah_8:
    pop ax
    popf
    call fs_get_bpb
    jmp .end

.ah_9:
    pop ax
    popf
    call fs_get_root_dir
    jmp .set_or_clear_carry

.error:
    pop ax
    popf

.set_or_clear_carry:
    ; Some functions set flags at the end. But when an interrupt is called,
    ; the flags from the caller are pushed into the stack and then, when iret is executed,
    ; they are popped. This will update the flags.

    push ax
    push bp

    mov bp, sp

    lahf
    ; Check if the carry flag not is set. (Carry flag is the most used flag for output register)
    jnc .set_or_clear_carry.clear

    or ah, 1
    jmp .set_or_clear_carry.set_flags

.set_or_clear_carry.clear:
    and ah, 1
    
.set_or_clear_carry.set_flags:
    mov [bp+8], ah

    pop bp
    pop ax

.end:
    iret