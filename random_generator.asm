; Based on example C code in the 1998 paper "Mersenne Twister: A 623-Dimensionally Equidistributed Uniform Pseudo-Random Number Generator" by Makoto Matumoto and Takuji Nishimura

; sourced from the ACM digital library https://dl.acm.org/doi/10.1145/272991.272995

; converted to handwritten assembly by Gavin M. Pawlovich who would like to note that there may be minor errors

section .data
	N equ 624
	M equ 397
	
	MATRIX_A 	equ 0x9908b0df
	UPPER_MASK 	equ 0x80000000
	LOWER_MASK 	equ 0x7fffffff

	TEMPERING_MASK_B equ 0x9d2c5680
	TEMPERING_MASK_C equ 0xefc60000
	TEMPERING_SHIFT_U_AMT equ 11
	TEMPERING_SHIFT_S_AMT equ 7
	TEMPERING_SHIFT_T_AMT equ 16
	TEMPERING_SHIFT_L_AMT equ 18

	mti dd N + 1

section .bss
	mt resq N

section .text

global sgenrand
global genrand

; void sgenrand(unsigned long seed)
sgenrand:
	push rbp
	mov rbp, rsp

	; mt[0] = seed & 0xffffffff
	mov rsi, 0xffffffff
	and rdi, rsi
	mov QWORD [mt], rdi

	; for (mti = 1; mti < N; mti++)
	xor rcx,rcx
	mov ecx, 1
	jmp sgenrand_loop_cond
	sgenrand_loop_start:

		; mt + mti
		mov rdi, mt
		lea rdx, [rcx*8]
		add rdi, rdx
		
		; (69069 * mt[mti - 1])   same as mt + (mti - 1) dereferenced
		mov rax, QWORD [rdi - 8]
		imul rax, rax, 69069

		; & 0xffffffff
		mov rdx, 0xffffffff
		and rax, rdx

		; mt[mti] = (69069 * mt[mti - 1]) & 0xffffffff
		mov QWORD [rdi], rax

	inc ecx
	sgenrand_loop_cond:
	cmp ecx, N
	jl sgenrand_loop_start
	mov DWORD [mti], ecx

	mov rsp,rbp
	pop rbp
	ret	

; unsigned long genrand()
genrand:
	push rbx
	push rbp
	mov rbp, rsp

	sub rsp, 28 ; allocating space for locals at rbp - (8, 16, 24, 28)

	; 8 - UNUSED
	; 24,16 - mag01
	; 28 - kk


	mov   QWORD [rbp - 24], 0			; mag01[0] ; rbp-24
	mov rbx, MATRIX_A
	mov QWORD [rbp - 16], rbx			; mag01[1] ; rbp-16

	; if(mti >= N)
	mov rax, N
	movsx rcx, DWORD [mti]
	cmp rcx, rax
	jl genrand_mtiNeN
		
		; if(mti == N+1)
		inc rax
		cmp rcx, rax
		jne genrand_dontReseed
			mov rdi, 4357
			call sgenrand
		genrand_dontReseed:


		; for(kk = 0; kk < N-M; kk++)
		mov DWORD [rbp - 28], 0
		jmp genrand_for1_compare
		genrand_for1_top:
	
			; y = (mt[kk]&upper_mask) | (mt[kk+1]&lower_mask)
			mov   rax, mt
			movsx rcx, DWORD [rbp-28]	
			lea rbx, [rcx*8]
			add rax, rbx
			mov rax, QWORD [rax]
			and eax, UPPER_MASK

			inc rcx
			mov rdx, mt
			lea rbx, [rcx*8]
			add rdx, rbx
			mov rdx, QWORD [rdx]
			and rdx, LOWER_MASK

			or rax, rdx	
			; y is stored in rax
			
			; mt[kk] = mt[kk+m] ^ (y >> 1) ^ mag01[y & 0x1];
			mov rcx, rax
			and rcx, 0x1		; y & 0x1
			lea rbx, [rbp - 24]
			lea rcx, [rcx*8]
			add rbx, rcx 	; mag01[y & 0x1]

			shr rax, 1
			xor rax, rbx	; rax = (y >> 1) ^ mag01[y & 0x1]

			mov   rbx, mt
			movsx rcx, DWORD [rbp - 28]	; I was being dumb and this value was rbx - 28 instead of rbp - 28... a wonder it didnt blow up sooner
			add rcx, M
			lea rcx, [rcx*8]
			add rbx, rcx
			mov rbx, QWORD [rbx]

			xor rax, rbx	; rax = mt[kk+m] ^ (y >> 1) ^ mag01[y & 0x1];
			
			mov rbx, mt
			movsx rcx, DWORD [rbp - 28]
			lea rcx, [rcx * 8]
			add rbx, rcx
			mov QWORD [rbx], rax ; mt[kk] = rax
			
			mov eax, DWORD [rbp-28]
			inc eax
			mov DWORD [rbp-28], eax
		genrand_for1_compare:
		mov eax, DWORD [rbp-28]
		cmp eax, N-M
		jl genrand_for1_top
			

		; for(; kk < N-1; kk++)
		jmp genrand_for2_compare
		genrand_for2_top:	
	
			; y = (mt[kk]&upper_mask) | (mt[kk+1]&lower_mask)
			mov   rax, mt
			movsx rcx, DWORD [rbp-28]	
			lea rbx, [rcx*8]
			add rax, rbx
			mov rax, QWORD [rax]
			and eax, UPPER_MASK

			inc rcx
			mov rdx, mt
			lea rbx, [rcx*8]
			add rdx, rbx
			mov rdx, QWORD [rdx]
			and rdx, LOWER_MASK

			or rax, rdx	
			; y is stored in rax
			
			; mt[kk] = mt[kk+m] ^ (y >> 1) ^ mag01[y & 0x1];
			mov rcx, rax
			and rcx, 0x1		; y & 0x1
			lea rbx, [rbp - 24]
			lea rcx, [rcx*8]
			add rbx, rcx 	; mag01[y & 0x1]

			shr rax, 1
			xor rax, rbx	; rax = (y >> 1) ^ mag01[y & 0x1]
			
			mov   rbx, mt
			movsx rcx, DWORD [rbp - 28]
			add rcx, M-N
			lea rcx, [rcx*8]
			add rbx, rcx
			mov rbx, QWORD [rbx]

			xor rax, rbx	; rax = mt[kk+m] ^ (y >> 1) ^ mag01[y & 0x1];
			
			mov rbx, mt
			movsx rcx, DWORD [rbp - 28]
			lea rcx, [rcx * 8]
			add rbx, rcx
			mov QWORD [rbx], rax ; mt[kk] = rax

			mov eax, DWORD [rbp - 28]
			inc eax
			mov DWORD [rbp-28], eax
		genrand_for2_compare:
		mov eax, DWORD [rbp-28]
		cmp eax, N-1
		jl genrand_for2_top

		; y = (mt[N-1]&upper_mask) | (mt[0]&lower_mask)
		mov rax, mt
		mov rcx, N
		lea rbx, [rcx*8]
		add rax, rbx
		mov rax, QWORD [rax]
		and eax, UPPER_MASK

		mov rdx, mt
		mov rdx, QWORD [rdx]
		and rdx, LOWER_MASK

		or rax, rdx	
		; y is stored in rax
			
		; mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
		mov rcx, rax
		and rcx, 0x1		; y & 0x1
		lea rbx, [rbp - 24]
		lea rcx, [rcx*8]
		add rbx, rcx 	; mag01[y & 0x1]

		shr rax, 1
		xor rax, rbx	; rax = (y >> 1) ^ mag01[y & 0x1]
			
		mov   rbx, mt
		mov rcx, M-1
		lea rcx, [rcx*8]
		add rbx, rcx
		mov rbx, QWORD [rbx]

		xor rax, rbx	; rax = mt[kk+m] ^ (y >> 1) ^ mag01[y & 0x1];
			
		mov rbx, mt
		mov rcx, N-1
		lea rcx, [rcx * 8]
		add rbx, rcx
		mov QWORD [rbx], rax ; mt[N-1] = rax

		; mti = 0;
		xor eax,eax
		mov DWORD [mti], eax
	genrand_mtiNeN:
	
	mov ebx, DWORD [mti]		; rax = y = mt[mti++]
	add ebx, 8
	mov rax, QWORD [mt + ebx]
	mov DWORD [mti], ebx

	mov rbx, rax		; rax = y ^= TEMPERING_SHIFT_U(y);
	shr rbx, TEMPERING_SHIFT_U_AMT
	xor rax, rbx

	mov rbx, rax		; rax = y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B
	shl rbx, TEMPERING_SHIFT_S_AMT
	and ebx, TEMPERING_MASK_B
	xor rax, rbx

	mov rbx, rax		; rax = y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C
	shl rbx, TEMPERING_SHIFT_T_AMT
	and ebx, TEMPERING_MASK_C
	xor rax, rbx

	mov rbx, rax
	shr rbx, TEMPERING_SHIFT_L_AMT
	xor rax, rbx

	mov rsp, rbp
	pop rbp
	pop rbx
	ret

