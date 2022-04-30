
section .data
		
	ROOMMAP_BLANKING_CHAR db ' '
	ROOMMAP_WALLFILL_CHAR db '#'
	ROOMMAP_NL_CHAR db 10
	ROOMMAP_SPACING_CHAR db ' '

	; a room map should be defined by:
	;	- a overall height and width 
	;	- pointers for a BSPTree, BSP_NODE Array, Room array, room connection matrix, and overall Map
	;	- a count of the number of rooms for the sake of indexing into arrays and matrices
	ROOM_MAP_SZ equ 52

	ROOM_MAP_H_OFF equ 0
	ROOM_MAP_W_OFF equ 4
	ROOM_MAP_ROOMCNT_OFF equ 8
	ROOM_MAP_BSPTREE_OFF equ 12
	ROOM_MAP_BSPARRY_OFF equ 20
	ROOM_MAP_ROOMARY_OFF equ 28
	ROOM_MAP_ROOMMTX_OFF equ 36
	ROOM_MAP_MAPMTRX_OFF equ 44

	; a room should be defined by 2 sets of X and Y
	; which will represent oposite corners, which can then be mapped into space
	ROOM_DATA_SZ equ 16
	
	ROOM_DATA_X1_OFF equ 0
	ROOM_DATA_Y1_OFF equ 4
	ROOM_DATA_X2_OFF equ 8
	ROOM_DATA_Y2_OFF equ 12

section .text

; ROOMMAP* create_map(int height, int width)
; creates a blank ROOMMAP and fills its entire area with walls
; does not generate any rooms or room related structures
ROOMMAP_create_map:
	push rbp
	mov rbp,rsp
		push rsi
		push rdi
		
		mov rdi, ROOM_MAP_SZ
		mov rsi, 1
		call basically_calloc
		
		pop rdi
		pop rsi
		
		mov DWORD [rax + ROOM_MAP_H_OFF], edi
		mov DWORD [rax + ROOM_MAP_W_OFF], esi

		push rax	; pushing location of ROOM_MAP structure

		mov rax, rdi
		imul rsi	; rax should now hold required number of bytes for the map	
		
		push rax		; pushing number of bytes for map
		mov rdi, rax
		call basically_malloc

		mov rdi, rax
		pop rcx			; popping number of bytes for map
		push rdi		; pushing location of MAP array/matrix

		mov al, BYTE [ROOMMAP_WALLFILL_CHAR]
		rep stosb

		pop rdi	; popping location of MAP array/matrix
		pop rax	; popping location of ROOM_MAP structure

		mov QWORD [rax + ROOM_MAP_MAPMTRX_OFF], rdi
	mov rsp,rbp
	pop rbp
	ret

; void print_map(ROOMMAP* room_map)
ROOMMAP_print_map:
	push rbp
	mov rbp, rsp
		mov rcx, rdi

		mov rsi, QWORD [rcx + ROOM_MAP_MAPMTRX_OFF]
		
		xor rdx,rdx
		mov edx, DWORD [rcx + ROOM_MAP_H_OFF]
		ROOMMAP_print_map_loop:
			push rsi
			push rcx
			push rdx
			
			mov rdx, rcx
			xor rcx, rcx
			mov ecx, DWORD [rdx + ROOM_MAP_W_OFF]
			
			ROOMMAP_print_map_innerLoop:
				push rcx
				push rsi
					mov rax, 1
					mov rdi, 1
					mov rdx, 1 		
					syscall

					mov rax, 1
					mov rdi, 1
					mov rsi, ROOMMAP_SPACING_CHAR
					mov rdx, 1
					syscall
				pop rsi
				pop rcx
			add rsi, 1
			loop ROOMMAP_print_map_innerLoop

			mov rax, 1
			mov rdi, 1
			mov rsi, ROOMMAP_NL_CHAR
			mov rdx, 1
			syscall
			
			pop rdx
			pop rcx
			pop rsi
		xor eax, eax
		mov eax, DWORD [rcx + ROOM_MAP_W_OFF]
		add rsi, rax	
		dec rdx
		cmp rdx, 0
		jge ROOMMAP_print_map_loop

	mov rsp, rbp
	pop rbp
	ret

; void generate_rooms(ROOMMAP* room_map, int target_area);
ROOMMAP_generate_rooms:
	push rbp
	mov rbp, rsp
		push rdi
		push rsi

		mov esi, 0
		mov edx, DWORD [rdi + ROOM_MAP_W_OFF]
		mov ecx, DWORD [rdi + ROOM_MAP_H_OFF]
		mov edi, 0
		call BSP_create_node_with_values
				
		pop rsi
		pop rdi

		mov QWORD [rdi + ROOM_MAP_BSPTREE_OFF], rax	; save newly created BSP Tree root node to the map structure

		push rdi
		push rsi

		; rsi is already correct for the next call
		mov rdi, rax
		push rdi
		call BSP_split_to_area

		pop rdi
		call BSP_flatten_leaf_nodes
		
		pop rsi	; restore original parameter values
		pop rdi

		mov QWORD [rdi + ROOM_MAP_BSPARRY_OFF], rax	; saving the flattened BSP array of leaf nodes
		mov DWORD [rdi + ROOM_MAP_ROOMCNT_OFF], edx	; saving the number of partitions in said array

		xor rcx,rcx
		
		generate_room_partition_check_loop:
			push rcx
			push rdx
			push rdi
			
				int3
	
				xor rax,rax
				mov eax, DWORD [rdi + ROOM_MAP_W_OFF]
				mov rdx, QWORD [rdi + ROOM_MAP_BSPARRY_OFF]
				lea rdx, [rdx + rcx*8]
				
				xor r8,r8
				xor r9,r9
				mov r8d, DWORD [rdx + BSP_NODE_X_OFF]
				mov r9d, DWORD [rdx + BSP_NODE_Y_OFF]

				imul r9
				add rax, r8

				mov rdi, QWORD [rdi + ROOM_MAP_MAPMTRX_OFF]
				add rdi, rax
				mov al, BYTE [ROOMMAP_BLANKING_CHAR]
				mov BYTE [rdi], al			 	

			pop rdi
			pop rdx
			pop rcx
		inc rcx
		cmp rcx, rdx
		jle generate_room_partition_check_loop
			
	mov rsp, rbp
	pop rbp
	ret
