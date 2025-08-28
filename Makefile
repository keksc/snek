snek: snek.o
	ld -o snek snek.o

snek.o: snek.asm
	nasm -felf64 -o snek.o snek.asm
