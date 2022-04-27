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

	call create_node	

	mov rax, 60
	mov rdi, 0
	syscall
