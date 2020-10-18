clean:
	rm -rf bin/*
	rm -rf disk/*
	rm -rf mnt

build:
	mkdir -p bin
	mkdir -p disk

	nasm -i src/ -f bin src/boot/boot.asm -o bin/boot.bin
	nasm -i src/ -f bin src/kernel/kernel.asm -o bin/kernel.bin

	nasm -f bin apps/terminal.asm -o bin/terminal.bin
	nasm -f bin apps/loadmz.asm -o bin/loadmz.bin

	dd if=/dev/zero of=disk/futuredos.img bs=1024 count=1440
	mkfs.msdos disk/futuredos.img
	dd if=bin/boot.bin of=disk/futuredos.img bs=512 count=1 conv=notrunc

	mkdir -p mnt
	sudo mount -o loop -t msdos disk/futuredos.img mnt
	sudo cp bin/kernel.bin mnt/kernel.bin
	sudo cp bin/terminal.bin mnt/terminal.bin
	sudo cp bin/loadmz.bin mnt/loadmz.bin
	sudo cp splash.cga mnt/splash.cga
	sudo cp RAYMARCH.EXE mnt/RAYMARCH.EXE
	sudo umount disk/futuredos.img
	rm -rf mnt

run:
	qemu-system-x86_64 disk/futuredos.img

debugrun:
	qemu-system-x86_64 disk/futuredos.img -debugcon stdio
