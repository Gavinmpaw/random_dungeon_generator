%include "random_generator.asm"

section .text

global _start

_start:
	mov rax, 0

	int3

	sub rsp, 8

	mov rax, 318
	mov rdi, rsp
	mov rsi, 8
	mov rdx, 0
	syscall

	mov rdi, QWORD [rsp]
	add rsp, 8

	call sgenrand

	infinite:
		call genrand
	jmp infinite
	

	mov rax, 60
	mov rdi, 0
	syscall
