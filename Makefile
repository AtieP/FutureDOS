clean:
	rm bin/*
	rm disk/*

build:
	mkdir -p bin
	mkdir -p disk

	nasm -i src/ -f bin src/boot/boot.asm -o bin/boot.bin
	nasm -i src/ -f bin src/kernel/kernel.asm -o bin/kernel.bin
	cat bin/kernel.bin >> bin/boot.bin

	dd if=/dev/zero of=disk/futuredos.img bs=512 count=2948
	mkfs.msdos disk/futuredos.img
	dd if=bin/boot.bin of=disk/futuredos.img bs=3072 count=1 conv=notrunc,noerror

	mkdir mnt
	sudo mount -o loop -t msdos disk/futuredos.img mnt
	sudo umount disk/futuredos.img
	rm -rf mnt

run:
	qemu-system-x86_64 disk/futuredos.img
