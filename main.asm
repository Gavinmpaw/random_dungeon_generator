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

	;call sgenrand

	xor rdi,rdi
	xor rsi,rsi
	mov rdx,500
	mov rcx,500
	;call BSP_create_node_with_values

	mov rdi, rax
	mov rsi, 8000
	push rdi
	;call BSP_split_to_area
	pop rdi
	
	;call BSP_print_leaf_nodes

	int3

	mov rdi, 64
	mov rsi, 1
	call basically_calloc

	mov rdi, rax
	call WRITER_create_writer
	
	mov rdi, rax
	push rdi
	
	mov rsi, 1
	call WRITER_write_64bitReg
	
	mov rsi, 2
	call WRITER_write_64bitReg

	mov rsi, 3
	call WRITER_write_64bitReg
	
	pop rdi
	call WRITER_dissolve_writer

	mov rax, 60
	mov rdi, 0
	syscall
