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

	mov rbx, 103

	call genrand	
	xor rdx,rdx
	div rbx

	call genrand
	xor rdx,rdx
	div rbx

	call genrand
	xor rdx,rdx
	div rbx

	mov rax, 60
	mov rdi, 0
	syscall
