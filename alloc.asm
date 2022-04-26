
section .text
	
; (number of bytes)
basically_malloc:
	push rbp
	mov rbp,rsp

	mov rsi, rdi

	mov rax, 9
	mov rdi, 0
	mov rdx, 3
	mov r10, 34
	mov r8, 0
	mov r9, 0
	syscall

	mov rsp, rbp
	pop rbp
	ret

; (size of objects in bytes, number of objects)
basically_calloc:
	push rbp
	mov rbp,rsp

	; allocate new space (preserving length)
	mov rax, rdi
	imul rsi
	mov rsi, rax

	push rsi

	mov rax, 9
	mov rdi, 0
	mov rdx, 3
	mov r10, 34
	mov r8, 0
	mov r9, 0
	syscall

	; set new space to all zeros (preserving rax)
	pop rcx
	push rax

	mov rdi, rax
	mov al, 0
	rep stosb

	pop rax

	mov rsp, rbp
	pop rbp

; (pointer, oldsize, newsize)
basically_realloc:
	push rbp
	mov rbp, rsp
	
	push rdi
	push rsi

	; allocate new space
	mov rsi, rdx

	mov rax, 9
	mov rdi, 0	
	mov rdx, 3
	mov r10, 34
	mov r8, 0
	mov r9, 0
	syscall

	; copy old -> new
	pop rcx
	pop rsi
	push rcx
	push rsi

	mov rdi, rax
	rep movsb

	; free old space
	mov rax, 11
	pop rdi
	pop rsi
	syscall	

	mov rsp, rbp
	pop rbp
	ret

; (pointer, size in bytes)
basically_free:
	push rbp
	mov rbp, rsp

		; rdi and rsi end up in the correct spots based on calling convention
		mov rax, 11
		syscall

	mov rsp,rbp
	pop rbp
