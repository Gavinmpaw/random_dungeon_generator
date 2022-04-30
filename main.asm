%include "random_generator.asm"
%include "alloc.asm"
%include "bspTree.asm"
%include "writer.asm"
%include "room_map.asm"
%include "../Assembly-Playground/basically_stdio.asm"

section .text

global _start

_start:
	sub rsp, 8
	mov rax, 318
	mov rdi, rsp
	mov rsi, 8
	mov rdx, 0
	syscall
	mov rdi, QWORD [rsp]
	add rsp, 8

	;call sgenrand

	mov rdi, 150
	mov rsi, 150
	call ROOMMAP_create_map

	mov rdi, rax
	call ROOMMAP_print_map

	mov rax, 60
	mov rdi, 0
	syscall
