
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
