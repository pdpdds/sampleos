nasm -f bin -o boot.bin boot.asm
nasm -f bin -o setup.bin setup.asm -l list._setup.txt
nasm -f coff -o interrupt_asm.o interrupt.asm


gcc -c kernel.c
gcc -c interrupt.c
gcc -c process.c

nasm -f coff -o floppy_asm.o floppy.asm
gcc -c floppy.c
ld -o kernel -Ttext 0xC0000000 -e _start_kernel kernel.o interrupt_asm.o interrupt.o process.o floppy_asm.o floppy.o

objcopy -R .note -R .comment -S -O binary kernel kernel.bin
gcc -c print_string.c

gcc -c user_program1.c
ld -o user_program1 -Ttext 0x80001000 -e _main user_program1.o print_string.o
objcopy -R .note -R .comment -S -O binary user_program1 user_program1.bin

gcc -c user_program2.c
ld -o user_program2 -Ttext 0x80002000 -e _main user_program2.o print_string.o
objcopy -R .note -R .comment -S -O binary user_program2 user_program2.bin

gcc -c user_program3.c
ld -o user_program3 -Ttext 0x80003000 -e _main user_program3.o print_string.o
objcopy -R .note -R .comment -S -O binary user_program3 user_program3.bin

gcc -c user_program4.c
ld -o user_program4 -Ttext 0x80004000 -e _main user_program4.o print_string.o
objcopy -R .note -R .comment -S -O binary user_program4 user_program4.bin

copy boot.bin+setup.bin+kernel.bin+user_program1.bin+user_program2.bin+user_program3.bin+user_program4.bin /b kernel.img