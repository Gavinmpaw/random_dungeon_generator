main: main.asm random_generator.asm alloc.asm bspTree.asm room_map.asm
	@nasm -f elf64 main.asm
	@ld main.o -o main
	@rm main.o
	@echo "Assembled Main Program"

clean: main
	@rm main
