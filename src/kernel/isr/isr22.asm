; All the calls here are from src/kernel/lib

; Handler for FutureDOS' library call interrupt (int 22h)
; print_register_dump is not included because it will be useless, AX is overwritten when
; specifying the service number; Use int3 instead
isr22:
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

.error:
    pop ax
    popf

.end:
    iret