; requires alloc.asm and random_generator.asm to be imported as well

section .data
	; node
	; 2 x 8 byte pointers
	; 4 x 4 byte integers (2 for x and y location, 2 for height and width)
	; assume x and y location are the upper left corner of the region, and the coordinate system has (0,0) in the upper left
	BSP_NODE_SZ 		equ 32

	BSP_NODE_X_OFF 		equ 0	; offset to X value
	BSP_NODE_Y_OFF 		equ 4	; offset to Y value
	BSP_NODE_W_OFF 		equ 8	; offset to Height value
	BSP_NODE_H_OFF 		equ 12	; offset to Width value
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
	push rcx
	push rsi
	push rdx
	call create_node
	pop rdx
	pop rsi
	pop rcx
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
			push rax
		
			mov rbx, 4
			xor rax, rax
			mov eax, DWORD [rdi + BSP_NODE_H_OFF]
			cqo
			idiv rbx				; rax = BSP node height / 4

			xor rbx, rbx
			mov ebx, DWORD [rdi + BSP_NODE_H_OFF]
			sub rbx, rax
			mov rcx, rax

			; rcx now contains the lower limit and rbx the upper limit
			
			pop rax

			sub rbx, rcx
			cqo
			idiv rbx
			add rcx, rdx

			; rcx now holds a random number between 0+(height/4) and height-(height/4) or 25% and 75% of the height
			; the new nodes will have the following values
			; node 1: original X, Original Y, original width, rcx as height
			; node 2: original X, rcx as Y+original Y, original width, original height minus rcx as height	

			push rdi
			; target height is already in rcx (which happens to be the correct register)
			mov esi, DWORD [rdi + BSP_NODE_Y_OFF]	; original Y value	
			mov edx, DWORD [rdi + BSP_NODE_W_OFF]	; original width
			mov edi, DWORD [rdi + BSP_NODE_X_OFF]	; original X
			call create_node_with_values
			pop rdi
			mov QWORD [rdi + BSP_NODE_LCHILD_OFF], rax

			push rdi
			xor rsi,rsi
			mov esi, DWORD [rdi + BSP_NODE_Y_OFF]
			add rsi, rcx							; rcx + original Y = new Y
			mov edx, DWORD [rdi + BSP_NODE_W_OFF]	; original width
			xor eax, eax
			mov eax, DWORD [rdi + BSP_NODE_H_OFF]
			sub rax, rcx	
			mov rcx, rax							; original height minus rcx
			mov edi, DWORD [rdi + BSP_NODE_X_OFF] 	; original X
			call create_node_with_values
			pop rdi
			mov QWORD [rdi + BSP_NODE_RCHILD_OFF], rax
			
			jmp split_over

		split_node_random_X_split:
			; split on X (width)
			call genrand
			pop rdi
			push rax
		
			mov rbx, 4
			xor rax,rax
			mov eax, DWORD [rdi + BSP_NODE_W_OFF]
			cqo
			idiv rbx				; rax = BSP node height / 4

			xor rbx, rbx
			mov ebx, DWORD [rdi + BSP_NODE_W_OFF]
			sub rbx, rax
			mov rcx, rax

			; rcx now contains the lower limit and rbx the upper limit
			
			pop rax

			sub rbx, rcx
			cqo
			idiv rbx
			add rcx, rdx

			; rcx now holds a random number between 0+(width/4) and width-(width/4) or 25% and 75% of the width
			; the new nodes will have the following values
			; node 1: original X, Original Y, rcx as width, original height
			; node 2: X + rcx as X, original Y, original width minus rcx as width, original height	

			push rcx
			push rdi
			mov esi, DWORD [rdi + BSP_NODE_Y_OFF]	; original Y value	
			mov edx, ecx							; rcx (ecx) as width
			mov ecx, DWORD [rdi + BSP_NODE_H_OFF]	; original height
			mov edi, DWORD [rdi + BSP_NODE_X_OFF]	; original X
			call create_node_with_values
			pop rdi
			mov QWORD [rdi + BSP_NODE_LCHILD_OFF], rax

			pop rcx
			push rdi
			mov esi, DWORD [rdi + BSP_NODE_Y_OFF]	; original Y
			xor rdx, rdx
			mov edx, DWORD [rdi + BSP_NODE_W_OFF]
			sub rdx, rcx							; original width minus rcx
			mov eax, DWORD [rdi + BSP_NODE_H_OFF] 	; storing original height
			mov edi, DWORD [rdi + BSP_NODE_X_OFF] 
			add edi, ecx							; original X + ecx
			mov ecx, eax							; original height moved to proper register
			call create_node_with_values
			pop rdi
			mov QWORD [rdi + BSP_NODE_RCHILD_OFF], rax

	split_over:

	mov rsp, rbp
	pop rbp
	ret
