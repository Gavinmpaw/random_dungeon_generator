
section .data
		
	ROOMMAP_MINIMUM_ROOM_WH equ 5

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
	
		push rdi

		xor rsi,rsi
		mov rdi, ROOM_DATA_SZ
		mov esi, edx
		call basically_calloc

		pop rdi

		mov QWORD [rdi + ROOM_MAP_ROOMARY_OFF], rax	; saving newly allocated space for array of room data all initialized to zero
		
		xor rax,rax
		xor rdx,rdx
		mov eax, DWORD [rdi + ROOM_MAP_ROOMCNT_OFF]
		mov edx, eax
		imul rdx

		push rdi
		push rax

		mov rdi, rax
		call basically_malloc

		mov rdi, rax
		pop rcx
		xor rax,rax
		push rdi
		rep stosb
		pop rax
		pop rdi

		mov QWORD [rdi + ROOM_MAP_ROOMMTX_OFF], rax

		push rdi
		call ROOMMAP_populate_room_array
		pop rdi

		push rdi
		call ROOMMAP_draw_room_array
		pop rdi	

	mov rsp, rbp
	pop rbp
	ret

; void populate_room_array(ROOMMAP* room_map)
; meant as a subroutine of generate_rooms, assumes all structures exist already and that the count is set
ROOMMAP_populate_room_array:
	push rbp
	mov rbp,rsp
		
		xor rcx,rcx
		ROOMMAP_populate_room_array_lp:

			mov rax, ROOM_DATA_SZ
			imul rcx
			add rax, [rdi+ROOM_MAP_ROOMARY_OFF]	; rax should now hold the location of a single room array element (4 integers representing the ul and lr corners of a room)
			push rax							; rax pushed but will be popped into rdx later

			mov rax, 8	; this one is an array of pointers, and not directly an array of structs... so 8 bytes is the correct size here
			imul rcx
			add rax, [rdi+ROOM_MAP_BSPARRY_OFF]	; rax should now hold the location of a single BSP_NODE structure representing one of the partitions
			mov rax, [rax]						; dereferencing rax, because it was a pointer to a pointer to the struct instead of a pointer to the struct itself
			pop rdx								; rdx should now hold the location of a single room array element	
			push rcx
		
			; these next two blocks set the corners of each room such that each section contains a 5x5 room	
			mov ecx, DWORD [rax + BSP_NODE_X_OFF]

			; random ul corner X position within half of section
			push rax
			push rcx
			push rdx
			mov ecx, DWORD [rax + BSP_NODE_W_OFF]
			shr ecx, 1
			xor rax,rax
			push rcx
			call genrand
			pop rcx
			cqo
			idiv rcx
			mov rax,rdx
			pop rdx
			pop rcx
			
			add ecx, eax
			mov DWORD [rdx + ROOM_DATA_X1_OFF], ecx

			pop rax

			; random width
			push rax
			push rcx
			push rdx
			mov ecx, DWORD [rax + BSP_NODE_W_OFF]
			shr ecx, 1
			xor rax,rax
			push rcx
			call genrand
			pop rcx
			cqo
			idiv rcx
			mov rax,rdx
			pop rdx
			pop rcx

			cmp eax, ROOMMAP_MINIMUM_ROOM_WH
			jge ROOMMAP_populate_rooms_over_min_w
				add eax, ROOMMAP_MINIMUM_ROOM_WH
			ROOMMAP_populate_rooms_over_min_w:
			add ecx, eax
			mov DWORD [rdx + ROOM_DATA_X2_OFF], ecx

			pop rax
			
	
			mov ecx, DWORD [rax + BSP_NODE_Y_OFF]
		
			; random ul corner Y position within half of section	
			push rax
			push rcx
			push rdx
			mov ecx, DWORD [rax + BSP_NODE_H_OFF]
			shr ecx, 1
			xor rax,rax
			call genrand
			cqo
			idiv rcx
			mov rax,rdx
			pop rdx
			pop rcx

			mov DWORD [rdx + ROOM_DATA_Y1_OFF], ecx

			pop rax

			; random height
			push rax
			push rcx
			push rdx
			mov ecx, DWORD [rax + BSP_NODE_H_OFF]
			shr ecx, 1
			xor rax,rax
			push rcx
			call genrand
			pop rcx
			cqo
			idiv rcx
			mov rax,rdx
			pop rdx
			pop rcx

			cmp eax, ROOMMAP_MINIMUM_ROOM_WH
			jge ROOMMAP_populate_rooms_over_min_h
				add eax, ROOMMAP_MINIMUM_ROOM_WH
			ROOMMAP_populate_rooms_over_min_h:
			add ecx, eax
			mov DWORD [rdx + ROOM_DATA_Y2_OFF], ecx

			pop rax
		
			pop rcx
		inc ecx
		cmp ecx, DWORD [rdi + ROOM_MAP_ROOMCNT_OFF]
		jl ROOMMAP_populate_room_array_lp
		
	mov rsp,rbp
	pop rbp
	ret

; void draw_room_array(ROOMMAP* room_map)
; meant as a subroutine of generate_rooms, assmes all structures exist already and room array has been populated
ROOMMAP_draw_room_array:
	push rbp
	mov rbp, rsp
		; for each room
		; need width and height of room, width of overall map/matrix, and upper left corner of room position in array

		xor rcx,rcx
		ROOMMAP_draw_room_array_lp:
			push rcx
			push rdi			

			mov rax, ROOM_DATA_SZ
			imul rcx
			add rax, [rdi+ROOM_MAP_ROOMARY_OFF]	; rax should now hold the location of a single room array element (4 integers representing the ul and lr corners of a room)
			mov rsi, rax						; moved to rsi to free rax for math operations
			
			xor rax,rax
			xor rdx,rdx
			mov eax, DWORD [rsi + ROOM_DATA_Y1_OFF] ; Y value of ul corner of room
			mov edx, DWORD [rdi + ROOM_MAP_W_OFF]	; width of map
			imul rdx								; eax now contains offset to start of correct row
			mov rdx,rax
			add edx, DWORD [rsi + ROOM_DATA_X1_OFF] ; adding the X value of the ul corner brings edx/rdx to the correct offset for the ul corner

			xor rax,rax
			mov eax, DWORD [rsi + ROOM_DATA_Y2_OFF]
			sub eax, DWORD [rsi + ROOM_DATA_Y1_OFF]	; eax contains overall height of room (number of rows to draw)
			
			xor rcx,rcx
			ROOMMAP_draw_room_array_lp2:
				push rcx
				push rax

					xor rax,rax
					mov eax, DWORD [rsi + ROOM_DATA_X2_OFF]
					sub eax, DWORD [rsi + ROOM_DATA_X1_OFF]	; eax contains width of room

					push rdi
					mov rdi, [rdi + ROOM_MAP_MAPMTRX_OFF]	; start of map matrix
					add rdi, rdx							; offset to start writing from
					mov rcx, rax							; width of room as counter
					xor rax,rax
					mov al, BYTE [ROOMMAP_BLANKING_CHAR]	; character to write
					rep stosb
					pop rdi
						
					add edx, DWORD [rdi + ROOM_MAP_W_OFF]	; effectively moves to next row start location
				pop rax
				pop rcx
			inc ecx
			cmp ecx, eax
			jl ROOMMAP_draw_room_array_lp2

	
			pop rdi
			pop rcx
		inc ecx
		cmp ecx, DWORD [rdi + ROOM_MAP_ROOMCNT_OFF]
		jl ROOMMAP_draw_room_array_lp
	
	mov rsp, rbp
	pop rbp
	ret
