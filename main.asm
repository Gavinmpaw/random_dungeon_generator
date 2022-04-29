%include "random_generator.asm"
%include "alloc.asm"
%include "bspTree.asm"
%include "writer.asm"
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

	call sgenrand

	xor rdi,rdi
	xor rsi,rsi
	mov rdx,500
	mov rcx,500
	call BSP_create_node_with_values

	mov rdi, rax
	mov rsi, 8000
	push rdi
	call BSP_split_to_area
	pop rdi

	push rdi	
	call BSP_print_leaf_nodes

	pop rdi
	call BSP_count_leaf_nodes	

	int3

	mov rax, 60
	mov rdi, 0
	syscall
