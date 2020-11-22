AS = nasm
AS_FLAGS = -f bin -o

futuredos.img: clean boot.bin kernel.bin
	dd if=/dev/zero of=$@ bs=1024 count=1440
	mkfs.msdos $@
	dd if=boot.bin of=$@ count=512 conv=notrunc
	mkdir mnt
	sudo mount -o loop -t msdos futuredos.img mnt
	sudo cp kernel.bin mnt/kernel.bin
	sudo umount mnt
	qemu-system-i386 $@

boot.bin:
	$(AS) $(AS_FLAGS) boot.bin src/boot/boot.asm

kernel.bin:
	$(AS) $(AS_FLAGS) kernel.bin src/kernel/kernel.asm

%.bin: %.asm
	$(AS) $(AS_FLAGS) $< $@

clean:
	rm *.bin
	rm *.img
	rm -rf mnt || true
