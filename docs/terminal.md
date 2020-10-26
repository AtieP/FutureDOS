FutureDOS Terminal Reference
====

**What is TERMINAL.BIN?**  
TERMINAL.BIN is the default FutureDOS shell. It is currently maintained by [AtieP](https://github.com/AtieP).

**How does TERMINAL.BIN work?**  
You simply type a command (or filename that ends with `.bin`) and then it's executed.  

**How do I execute a file?**  
Simply put the filename that has `BIN` extension in the terminal. For example, say you have a file named `HELLO.BIN`. To execute it, you just type `hello.bin` or `hello`.

**If I want to develop apps, what should I know?**  
  - The command line buffer (the input) is passed on `DS:SI`. The end of the input is a NULL (`0x00`) byte.
  - The data and extra segments are **not** set for you. You must set them manually.
  - To return to the terminal, simply use `retf`. Make sure to pop elements from the stack that were previously pushed, otherwise FutureDOS will hang.
  - Your program is loaded at offset `0x0000`. The code segment (`CS`) is undefined.

Terminal Commands
====

**`echo`**  
Prints the string right passed after it. Example usage: `echo Hello, World!`

**`ls` (or `dir`)**  
Shows all files of the current directory. Parameters (all of them are optional):  
  - `--all`: Shows all files in the current directory, doesn't matter if they're hidden, they're system files, or they're volume IDs.

**`reboot` (or `reset` or `restart`)**  
Boots from the next default drive.

**`poweroff` (or `shutdown` or `exit`)**
Shutdowns computer using BIOS.