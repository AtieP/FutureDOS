build:
	mkdir -p bin
	nasm -f bin src/boot/boot.asm -o bin/boot.bin
	nasm -f bin src/kernel/kernel.asm -o bin/kernel.bin
	
	dd if=/dev/zero of=futuredos.img bs=1024 count=1440
	mkfs.msdos futuredos.img
	dd if=bin/boot.bin of=futuredos.img bs=512 count=1 conv=notrunc
	mkdir -p mnt
	sudo mount -o loop -t msdos futuredos.img mnt
	sudo cp bin/kernel.bin mnt
	sudo umount futuredos.img

run:
	qemu-system-i386 futuredos.img