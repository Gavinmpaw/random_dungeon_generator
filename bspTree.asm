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

; BSP_NODE* create_node_with_values(int x, int y, int w, int h);
; same as above, but sets the node up with initial values
create_node_with_values:
	push rbp
	mov rbp, rsp
	
	push rdi
	call create_node
	pop rdi

	mov DWORD [rax + BSP_NODE_X_OFF], edi
	mov DWORD [rax + BSP_NODE_Y_OFF], esi
	mov DWORD [rax + BSP_NODE_H_OFF], ecx
	mov DWORD [rax + BSP_NODE_W_OFF], edx

	mov rsp, rbp
	pop rbp
	ret

; void split_node_random(BSP_NODE* node);
; splits the region contained in a node at a random offset and creates child nodes containing the two sub-regions
split_node_random:
	push rbp
	mov rbp, rsp

		push rdi
		call genrand

		and rax, 0x1
		cmp rax, 1
		jne split_node_random_X_split
			; split on Y (height)
			call genrand
			pop rdi
		
			; thinking I want only the middle 50% to be valid
			; so, 0+(height/4) and height-(height/4) are the bounds, then use the random number from above to pick something in that range	

		split_node_random_X_split:
			; split on X (width)
			call genrand
			pop rdi


	mov rsp, rbp
	pop rbp
	ret
