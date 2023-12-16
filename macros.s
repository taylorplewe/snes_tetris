	.macro a8
		sep #%00100000 ; a 8 bit
	.endmacro
	.macro a16
		rep #%00100000 ; a 16 bit
	.endmacro
	.macro i8
		sep #%00010000 ; x & y 8 bit
	.endmacro
	.macro i16
		rep #%00010000 ; x & y 16 bit
	.endmacro
	
	.macro m_dma_ch0 dmap, src, ppureg, count
		lda #dmap
		sta DMAP0
		ldx #src
		lda #^src
		xba
		lda #<ppureg
		ldy #count
		jsr dma_ch0
	.endmacro

	.macro m_rand_mod dividend
		jsr rand
		tax
		lda dividend
		jsr mod
	.endmacro

	.macro ldb val
		xba
		lda val
		xba
	.endmacro

	; MUST BE 16-BIT A
	.a16
	.macro m_check_button_press buttons, on_no_press
		lda buttons
		and JOY1L
		beq on_no_press
		and prev_joy1
		bne on_no_press
	.endmacro
	.a8

	; remove item at index i from array
	; len = length of array (will be 1 less after this)
	; NOTE: len and i must be 16-bit
	.macro array_remove array, i, len
		.local @end
		a16
		; removing last item?
			lda len
			dec a
			cmp i
			beq @end
		lda #array
		clc
		adc i
		tay ; dest
		inc a
		tax ; source
		lda #0
		; len
			lda len
			sec
			sbc i
			dec a
			dec a
		mvn 0, 0
		@end:
		a8
	.endmacro