all:
	nasm -felf64 borth.asm
	ld borth.o -o borth
run: 
	cat borth.f - | ./borth
clean:
	rm borth.o
