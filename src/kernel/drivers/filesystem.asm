bits 16
cpu 8086

; This macro creates a .val children with the default value, so you don't have to compute it at runtime
%macro __DEFINE_VALUE 3 ; defval <name>, <type>, <default value>
%1 %2 %3
%1.val equ %3
%endmacro

; The values are uninitialized
; They are initialized in init_fs
__FS_BIOS_PARAMETER_BLOCK:
          .oemID: db "FtrDOS  "
__DEFINE_VALUE .bytesPerSect, dw, 512
__DEFINE_VALUE .sectsPerCluster, db, 1
__DEFINE_VALUE .resvSects, dw, 1
__DEFINE_VALUE .numFats, db, 2
__DEFINE_VALUE .rootDirEnts, dw, 224
__DEFINE_VALUE .logSects, dw, 2880
__DEFINE_VALUE .mediaDescType, db, 0xF0
__DEFINE_VALUE .sectsPerFat, dw, 9
__DEFINE_VALUE .sectsPerTrack, dw, 18
__DEFINE_VALUE .sides, dw, 2
__DEFINE_VALUE .hiddenSects, dd, 0
__DEFINE_VALUE .largeSects, dd, 0
__DEFINE_VALUE .driveNo, db, 0
__DEFINE_VALUE .reservedFlags, db, 0
__DEFINE_VALUE .signature, db, 0x29
__DEFINE_VALUE .volID, dd, 0x1234ABCD
          .volLabel: db "FutureDOS  "
          .sysString: db "FAT12   "

%unmacro __DEFINE_VALUE 0

; Computed constants: it's possible to avoid calculating them at runtime
.firstFatSect equ __FS_BIOS_PARAMETER_BLOCK.resvSects.val
.rootDirSect equ .firstFatSect + (__FS_BIOS_PARAMETER_BLOCK.numFats.val * __FS_BIOS_PARAMETER_BLOCK.sectsPerFat.val)
.rootSecs equ (__FS_BIOS_PARAMETER_BLOCK.rootDirEnts.val * 32 + __FS_BIOS_PARAMETER_BLOCK.bytesPerSect.val - 1) / __FS_BIOS_PARAMETER_BLOCK.bytesPerSect.val
.firstDataSect equ .rootDirSect + .rootSecs


; Initializes the filesystem driver.
; IN/OUT: Nothing
init_fs:
    push cx
    push si
    push di
    push ds
    push es

    push cs
    pop es

    xor cx, cx
    mov ds, ax

    mov si, 0x7c00 + 3
    mov di, __FS_BIOS_PARAMETER_BLOCK

    mov cx, 59
    rep movsb

    pop es
    pop ds
    pop di
    pop si
    pop cx
    ret
