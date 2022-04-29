
section .data
	WRITER_SIZE equ 16
	WRITER_BASE_ADDR_OFF equ 0
	WRITER_CURRENT_ADDR_OFF equ 8

section .text

; WRITER* create_writer(void* BASE_ADDR)
WRITER_create_writer:
	push rbp
	mov rbp, rsp
		push rdi

		mov rdi, WRITER_SIZE
		call basically_malloc
		push rax

		mov rdi, rax
		mov rax, 0
		mov rcx, WRITER_SIZE
		rep stosb

		pop rax
		pop rdi

		mov QWORD [rax + WRITER_BASE_ADDR_OFF], rdi
		mov QWORD [rax + WRITER_CURRENT_ADDR_OFF], rdi
		
	mov rsp, rbp
	pop rbp
	ret

; void write_64bitReg(WRITER* writer) + 64 bit register value in rsi to be written
WRITER_write_64bitReg:
	push rbp
	mov rbp,rsp
		
		mov rax, QWORD [rdi + WRITER_CURRENT_ADDR_OFF]

		mov QWORD [rax], rsi
		add rax, 8

		mov QWORD [rdi + WRITER_CURRENT_ADDR_OFF], rax	

	mov rsp, rbp
	pop rbp
	ret	

; void* dissolve_writer(WRITER* writer, size in bytes)
WRITER_dissolve_writer:
	push rbp
	mov rbp, rsp

		mov rax, QWORD [rdi + WRITER_BASE_ADDR_OFF]
		push rax
			
		; rdi and rsi end up being correct by calling convention
		call basically_free
		
		pop rax

	mov rsp, rbp
	pop	rbp
	ret
