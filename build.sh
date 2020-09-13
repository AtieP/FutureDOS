mkdir -p bin
rm bin/*
cd src
nasm -f bin boot/boot.asm -o ../bin/boot || exit 1
nasm -f bin kernel/kernel.asm -o ../bin/kernel || exit 1
cd ..
cat bin/kernel >> bin/boot
mkdir -p disk
rm disk/*
mv bin/boot disk/floppy.flp
