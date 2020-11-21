db "FV"
dw 0x0000
dw 0x0000
dw ps2_init

ps2_wait_read:
    push ax

.test:
    in al, 0x64
    test al, 1
    jz .test
    pop ax
    ret

ps2_wait_write:
    push ax

.test:
    in al, 0x64
    test al, 1 << 1
    jnz .test
    pop ax
    ret

; Initializes the 8042 PS/2 controller.
; IN:
;    Nothing
; OUT:
;    AX = 0x00 (Success, two PS/2 ports exist)
;    AX = 0x01 (Error)
;    AX = 0x02 (Success, only first PS/2 port exists)
;
; Note: on error, the PS/2 devices and controller statuses are
; undefined. It's recommendable to reset the system to avoid
; major problems
ps2_init:
    push ds
    pushf

    push cs
    pop ds

    cli

    ; Disable the first and second PS/2 device
    call ps2_wait_write
    mov al, 0xAD
    out 0x64, al

    call ps2_wait_write
    mov al, 0xA7
    out 0x64, al

    ; Load configuration byte
    call ps2_wait_write
    mov al, 0x20
    out 0x64, al
    call ps2_wait_read
    in al, 0x60
    mov [.cfg_byte], al

.self_test:
    call ps2_wait_write
    mov al, 0xAA
    out 0x64, al

    call ps2_wait_read
    in al, 0x60

    cmp al, 0xFC
    je .error

    cmp al, 0xFE
    je .self_test

    cmp al, 0x55
    jne .error

.load_configuration:
    ; Now, load back the default PS/2 configuration
    ; (with some changes, of course)
    mov al, [.cfg_byte]

    ; Enable first and second PS/2 devices IRQs
    ; Also enable translation, because it's important for us
    ; to support Scan Code set 1, since we also want to support
    ; the original IBM PC
    or al, 01000011b
    push ax
    call ps2_wait_write
    mov al, 0x60
    out 0x64, al
    pop ax
    call ps2_wait_write
    out 0x60, al

.check_if_mouse_exists:
    mov [.second_ps2_port_available], byte 0x02

    ; Checking if a second PS/2 device (mouse) exists
    ; is important for us
    ; To do that, check if bit 5 from the configuration byte
    ; is set
    test al, 1 << 5
    jz .check_if_mouse_exists.no ; Doesn't exist

.check_if_mouse_exists.yes:
    mov [.second_ps2_port_available], byte 0x00
    ; Enable the mouse
    call ps2_wait_write
    mov al, 0xA8
    out 0x64, al
    jmp .test_devices

.check_if_mouse_exists.no:
    ; Then disable the mouse IRQ
    xor al, 00000010b
    ; And reload configuration
    call ps2_wait_write
    push ax
    mov al, 0x60
    out 0x64, al
    pop ax
    call ps2_wait_write
    out 0x60, al

.test_devices:
    ; Test the keyboard and the mouse
    ; First goes the keyboard
.test_devices.keyboard:
    call ps2_wait_write
    mov al, 0xAB
    out 0x64, al

    call ps2_wait_read
    in al, 0x60

    cmp al, 0xFE
    je .test_devices.keyboard

    test al, al
    jnz .error

    mov al, [.second_ps2_port_available]
    cmp al, 0x02
    je .enable_devices ; No mouse

.test_devices.mouse:
    call ps2_wait_write
    mov al, 0xA9
    out 0x64, al

    call ps2_wait_read
    in al, 0x60

    cmp al, 0xFE
    je .test_devices.mouse

    test al, al
    jnz .error

    ; Enable mouse
    call ps2_wait_write
    mov al, 0xA8
    out 0x64, al

.enable_devices:
    ; The mouse is already enabled, if it existed
    call ps2_wait_write
    mov al, 0xAE
    out 0x64, al

    ; Now, it's up for the PS/2 keyboard and PS/2 mouse
    ; device drivers to reset themselves
.success:
    xor ah, ah
    mov al, [.second_ps2_port_available]
    popf
    pop ds
    ret

.error:
    popf
    pop ds
    mov ax, 1
    ret

.cfg_byte: db 0x00
.second_ps2_port_available: db 0x00 ; 0 if yes, 2 if not
