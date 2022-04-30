; requires alloc.asm and random_generator.asm to be imported as well
; pretty printing functionality requires some form of printf to be imported	
; leaf flattening relies on writer.asm

section .data
	BSP_pretty_print_str db "BSP_NODE{ x:%d, y:%d, w:%d, h:%d }",10,0

	BSP_MAX_HW_RATIO equ 3	

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
BSP_create_node:
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
BSP_create_node_with_values:
	push rbp
	mov rbp, rsp
	
	push rdi
	push rcx
	push rsi
	push rdx
	call BSP_create_node
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
BSP_split_node_random:
	push rbp
	mov rbp, rsp

		; refuse to split if height or width are less than 10
		cmp DWORD [rdi + BSP_NODE_H_OFF], 10
		jle	BSP_split_node_split_over
		cmp DWORD [rdi + BSP_NODE_W_OFF], 10
		jle BSP_split_node_split_over
	
		push rdi

		; if height*max ratio is less than width, split width
		mov rcx, BSP_MAX_HW_RATIO
		xor rax,rax
		mov eax, DWORD [rdi + BSP_NODE_H_OFF]
		imul rcx
		cmp eax, DWORD [rdi + BSP_NODE_W_OFF]
		jle BSP_split_node_random_X_split

		; if width*max ratio is less than height, split height
		mov rcx, BSP_MAX_HW_RATIO
		xor rax,rax
		mov eax, DWORD [rdi + BSP_NODE_W_OFF]
		imul rcx
		cmp eax, DWORD [rdi + BSP_NODE_H_OFF]
		jle BSP_split_node_random_Y_split

		call genrand

		and rax, 0x1
		cmp rax, 1
		jne BSP_split_node_random_X_split
		BSP_split_node_random_Y_split:
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
			call BSP_create_node_with_values
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
			call BSP_create_node_with_values
			pop rdi
			mov QWORD [rdi + BSP_NODE_RCHILD_OFF], rax
			
			jmp BSP_split_node_split_over

		BSP_split_node_random_X_split:
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
			call BSP_create_node_with_values
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
			call BSP_create_node_with_values
			pop rdi
			mov QWORD [rdi + BSP_NODE_RCHILD_OFF], rax

	BSP_split_node_split_over:
	mov rsp, rbp
	pop rbp
	ret

; void split_to_area(BSP_NODE* root, int targetArea) 
BSP_split_to_area:
	push rbp
	mov rbp, rsp
		
		cmp rdi, 0
		je BSP_split_to_area_size_reached_base_case ; shouldnt ever trigger... but doesnt hurt to be careful	

		xor eax,eax
		xor ebx,ebx
		mov eax, DWORD [rdi + BSP_NODE_W_OFF]
		mov ebx, DWORD [rdi + BSP_NODE_H_OFF]
		;sub eax, DWORD [rdi + BSP_NODE_X_OFF]
		;sub ebx, DWORD [rdi + BSP_NODE_Y_OFF]
		; rax and rbx should now contain the width and height of the node	
		imul rbx
		; rax should now contain the area of the node (ignoring rdx because I doubt the output was too big for rax)

		cmp rax, rsi		
		jle BSP_split_to_area_size_reached_base_case	; assuming the area is less than or equal to the target... splitting wont take it any closer, so we hit the end


		push rdi
		push rsi
		call BSP_split_node_random	; split itself
		pop rsi
		pop rdi

		push rdi
		push rsi

		; recursively call on Left Child
		mov rdi, [rdi + BSP_NODE_LCHILD_OFF]
		call BSP_split_to_area
		
		pop rsi
		pop rdi

		; recursively call on Right Child
		mov rdi, [rdi + BSP_NODE_RCHILD_OFF]
		call BSP_split_to_area
	
	BSP_split_to_area_size_reached_base_case:
	mov rsp,rbp
	pop rbp
	ret

; void print_leaf_nodes(BSP_NODE* root)
BSP_print_leaf_nodes:
	push rbp
	mov rbp,rsp

		cmp rdi, 0
		je BSP_print_leaf_nodes_exit

		mov eax, DWORD [rdi + BSP_NODE_LCHILD_OFF]
		cmp eax, 0
		jne BSP_print_leaf_nodes_not_leaf
			xor rsi,rsi
			xor rdx,rdx
			xor rcx,rcx
			xor r8, r8

			mov esi, DWORD [rdi + BSP_NODE_X_OFF]
			mov edx, DWORD [rdi + BSP_NODE_Y_OFF]
			mov ecx, DWORD [rdi + BSP_NODE_W_OFF]
			mov r8d, DWORD [rdi + BSP_NODE_H_OFF]
			mov rdi, BSP_pretty_print_str
			call printf		

		jmp BSP_print_leaf_nodes_exit
		BSP_print_leaf_nodes_not_leaf:
			push rdi
			mov rdi, [rdi + BSP_NODE_LCHILD_OFF]
			call BSP_print_leaf_nodes
			pop rdi
			mov rdi, [rdi + BSP_NODE_RCHILD_OFF]
			call BSP_print_leaf_nodes
	BSP_print_leaf_nodes_exit:
	mov rsp,rbp
	pop rbp
	ret

; BSP_NODE* flatten_leaf_nodes(BSP_NODE* root)
; should return an array of BSP_NODE* containing only the leaf nodes in rax
; should also return the number of nodes in rdx
BSP_flatten_leaf_nodes:
	push rbp
	mov rbp,rsp			
		push rdi ; push root, it will be needed later

		call BSP_count_leaf_nodes
		push rax	; push count (it will be needed multiple times later)
		
		mov rdi, 8
		mov rsi, rax
		call basically_calloc	; calloc count items of size 8

		mov rdi, rax
		call WRITER_create_writer ; create a writer to the space calloc returned

		pop rbx	; using rbx as a temp to hold the count so that I can shuffle the root node pointer off of the stack
		pop rdi
		push rbx

		mov rsi, rax	; move the writer into the second argument of write_leaf_nodes
		push rsi		; save the location of the writer

		call BSP_write_leaf_nodes
		
		pop rdi	; pop location of writer into rdi
		call WRITER_dissolve_writer	; disolve the writer, leaving a pointer to its array in rax

		pop rdx	; pop the count into rdx

		; rax should now hold an array of BSP_NODE*
		; rdx should now hold the number of them
	mov rsp,rbp
	pop rbp
	ret

; void write_leaf_nodes(BSP_NODE* root, WRITER* writer)
; writes all leaf nodes of a BSP rooted at root into an array controlled by writer
; should not be called directly in most cases
BSP_write_leaf_nodes:
	push rbp
	mov rbp,rsp
		cmp rdi, 0
		je BSP_write_leaf_nodes_exit

		mov eax, DWORD [rdi + BSP_NODE_LCHILD_OFF]
		cmp eax, 0
		jne BSP_write_leaf_nodes_not_leaf
			push rdi
			push rsi
			xchg rdi,rsi	; writer function expects them to be perfectly reversed (Writer first as opposed to node first)
			call WRITER_write_64bitReg
			pop rsi
			pop rdi
		jmp BSP_write_leaf_nodes_exit
		BSP_write_leaf_nodes_not_leaf:
			push rdi
			push rsi
			mov rdi, [rdi + BSP_NODE_LCHILD_OFF]
			call BSP_write_leaf_nodes
			
			pop rsi
			pop rdi
			mov rdi, [rdi + BSP_NODE_RCHILD_OFF]
			call BSP_write_leaf_nodes
	BSP_write_leaf_nodes_exit:
	mov rsp,rbp
	pop rbp
	ret

; i64 count_leaf_nodes(BSP_NODE* root)
; should return the number of leaf nodes which exist within a tree rooted at the node passed in
BSP_count_leaf_nodes:
	push rcx
	push rbp
	mov rbp, rsp
		xor rcx,rcx
		
		cmp rdi, 0
		je BSP_count_leaf_nodes_exit

		mov eax, DWORD [rdi + BSP_NODE_LCHILD_OFF]
		cmp eax, 0
		jne BSP_count_leaf_nodes_not_leaf
			inc rcx	; add one because this node is a leaf
		jmp BSP_count_leaf_nodes_exit
		BSP_count_leaf_nodes_not_leaf:
			push rdi
			mov rdi, [rdi + BSP_NODE_LCHILD_OFF]
			call BSP_count_leaf_nodes
			add rcx, rax	; add return of left child to this nodes counter
			
			pop rdi
			mov rdi, [rdi + BSP_NODE_RCHILD_OFF]
			call BSP_count_leaf_nodes
			add rcx, rax	; add return of right child to this nodes counter
	BSP_count_leaf_nodes_exit:
	mov rax, rcx
	mov rsp,rbp
	pop rbp
	pop rcx
	ret
