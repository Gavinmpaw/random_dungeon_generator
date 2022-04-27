; requires alloc.asm and random_generator.asm to be imported as well

section .data
	; node
	; 2 x 8 byte pointers
	; 4 x 4 byte integers (2 for x and y location, 2 for height and width)
	; assume x and y location are the upper left corner of the region, and the coordinate system has (0,0) in the upper left
	BSP_NODE_SZ 		equ 32

	BSP_NODE_X_OFF 		equ 0	; offset to X value
	BSP_NODE_Y_OFF 		equ 4	; offset to Y value
	BSP_NODE_H_OFF 		equ 8	; offset to Height value
	BSP_NODE_W_OFF 		equ 12	; offset to Width value
	BSP_NODE_LCHILD_OFF equ 16	; offset to left child pointer
	BSP_NODE_RCHILD_OFF equ 24	; offset to right child pointer

section .text

; BSP_NODE* create_node();
; creates a new bsp node... probably not going to be called from outside of this file very often
create_node:
	push rbp
	mov rbp, rsp

		; allocating space for a node
		mov rdi, BSP_NODE_SZ
		call basically_malloc

		push rax
		
		; zeroing out the whole range, effectively making all the values either 0 or NULL
		mov rdi, rax
		mov rax, 0
		mov rcx, BSP_NODE_SZ
		rep stosb

		pop rax

	mov rsp, rbp
	pop rbp
	ret

; BSP_NODE* create_node_with_values(int x, int y, int h, int w);
; same as above, but sets the node up with initial values
create_node_with_values:
	push rbp
	mov rbp, rsp
	
	push rdi
	call create_node
	pop rdi

	mov DWORD [rax + BSP_NODE_X_OFF], edi
	mov DWORD [rax + BSP_NODE_Y_OFF], esi
	mov DWORD [rax + BSP_NODE_H_OFF], edx
	mov DWORD [rax + BSP_NODE_W_OFF], ecx

	mov rsp, rbp
	pop rbp
	ret
