# FutureDOS
[![Build Status](https://travis-ci.com/AtieP/dpyjs-bot.svg?branch=master)](https://travis-ci.com/AtieP/dpyjs-bot)  
A Disk Operating System from the Future

![FutureDOS](https://i.imgur.com/YvTQu9z.png)

Discord Server: https://discord.gg/F2QMxa5

# Status
Pre-alpha

# Features
- Custom CGA driver
- Custom keyboard driver
- Custom error handlers
- Made to be run on any IBM PC compatible computer

# Build instructions
You need to install [NASM](https://nasm.us/). Then, run `make build`; the build process uses Linux's loopback mounting facilities, so you might need to insert your `sudo` password.
**There is currently no known way on how to build this on Windows without WSL2.**

# Run instructions
There are two ways:  
- **Recommended:** Using [QEMU](https://qemu.org/). Install it and then run `make run`.
- **Not recommended:** Running the OS in a real PC-compatible computer.

# Disclaimer
I am not responsible for any damages caused by this OS, but it should be safe.
