**Important: If you're experiencing weird behaviour while using a syscall, don't hesitate to open an issue.**

FutureDOS Syscall Reference
====

You trigger the FutureDOS' library call syscall by using `int 0xFD`.

Available syscalls:

`getchar`  
`getcharp`  
`gets`  
`getsp`  
`putc`  
`puts`  
`fs_load_file`  
`fs_get_pbp`  
`fs_get_root_dir`  
`fs_get_file_size`  
`fs_get_file_info`  
`fs_filename_to_filename`


`getchar`
====
`AH` = 0x01

**Description**  
Gets a key from the keyboard. Note: it is not printed. If you want it to be printed, see `getcharp`.

**Parameters**  
Nothing

**Output registers**  
`AH` = Scancode of the pressed key  
`AL` = Representation of the pressed key as a letter

`getcharp`
====
`AH` = 0x02

**Description**  
Gets a key from the keyboard. Unlike `getchar`, it is printed.

**Parameters**  
`BL` = Color of the pressed letter  

**Output registers**
`AH` = Scancode of the pressed key  
`AL` = Representation of the pressed key as a letter

`gets`
====
`AH` = 0x03

**Description**  
Gets a string from the keyboard. Note: the string is not printed. If you want it to be printed, see `getsp`.

**Parameters**  
`ES:DI` = Destination of the string  
`CX` = Amount of chars to be read

**Output registers**
Nothing

`getsp`
====
`AH` = 0x04

**Description**  
Gets a string from the keyboard. Unlike `gets`, it is printed.

**Parameters**  
`ES:DI` = Destination of the string
`CX` = Amount of chars to be read  
`BL` = Color of the string

**Output registers**  
Nothing

`putc`
====
`AH` = 0x05

**Description**  
Prints a char into the screen.

**Parameters**  
`AL` = Char  
`BL` = Color

**Output registers**  
Nothing

`puts`
====
`AH` = 0x06

**Description**  
Prints a string into the screen. The end of the string is a null-byte (0x00).

**Parameters**  
`DS:SI` = Location of the string  
`BL` = Color

**Output registers**
Nothing

`fs_load_file`
====
`AH` = 0x07

**Description**  
Loads a file into memory. Note: you need to allocate a multiple of 512 bytes.

**Parameters**  
`DS:SI` = Location of the filename. The format must be:
- 8 bytes name (padded by spaces, if the filename is less than 8 bytes)
- 3 bytes extension
- Examples: TEST&nbsp;&nbsp;&nbsp;&nbsp;BIN, FILENAMEBIN

`ES` = Segment where the file will be loaded  
`BX` = Offset where the file will be loaded

**Output registers**  
Carry flag set if there was an error (file not found, disk error, other fatal error)

`fs_get_bpb`
====
`AH` = 0x08

**Description**  
Returns you the BIOS Parameter Block.

**Parameters**  
`ES:DI` = Where the BPB will be returned. You should allocate 59 bytes.

**Output registers**  
Nothing

`fs_get_root_dir`
====
`AH` = 0x09

**Description**  
Returns you the root directory.

**Parameters**  
`ES:DI` = Where the root directory wiill be returned. For now, it's required to you to allocate
512 bytes.

**Output registers**  
Carry flag if there was an error (disk error)

`fs_get_file_size`
====
`AH` = 0x0A

**Description**  
Returns the specified file's size.

**Parameters**  
`DS:SI` = Location of the filename. The format must be:
- 8 bytes name (padded by spaces, if the filename is less than 8 bytes)
- 3 bytes extension
- Examples: TEST&nbsp;&nbsp;&nbsp;&nbsp;BIN, FILENAMEBIN

**Output registers**  
`DX` = Upper word of file size  
`AX` = Lower word of file size  
Carry flag set on error (file not found, disk error, ...)

`fs_get_file_info`
====
`AH` = 0x0B

**Description**  
Returns the specified file's information. (See https://wiki.osdev.org/FAT12#Directories for more info.)

**Parameters**  
`DS:SI` = Location of the filename. The format must be:
- 8 bytes name (padded by spaces, if the filename is less than 8 bytes)
- 3 bytes extension
- Examples: TEST&nbsp;&nbsp;&nbsp;&nbsp;BIN, FILENAMEBIN  

`ES:DI` = 32 bytes for the file info's data.

**Output registers**  
Carry flag set on error (file not found, disk error, ...)

`fs_filename_to_fat_filename`
====
`AH` = 0x0C

**Description**  
Converts a filename into a valid FAT filename.

**Parameters**. 
`DS:SI` = Filename (example: file.bin)  (11 bytes, padded with spaces) (NULL or a space count as an end marker)  
`ES:DI` = Destination (11 bytes, padded with spaces)

**Output registers**    
Carry flag set on error (invalid symbol, ...), otherwise clear
