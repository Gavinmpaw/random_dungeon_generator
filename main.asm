%include "random_generator.asm"
%include "alloc.asm"
%include "bspTree.asm"

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
	call create_node_with_values

	int3


	mov rdi, rax
	call split_node_random
	
	int3

	mov rax, 60
	mov rdi, 0
	syscall
