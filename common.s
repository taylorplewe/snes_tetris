; NOTE: set DMAP0 beforehand!!
; Also don't forget to set the corresponding address register beforehand e.g. set CGADD before doing the DMA on CGDATA
; params:
;	a - destination PPU register; $21aa
;	x - low 16 bits of source address; -------- xxxxxxxx xxxxxxxx
;	b - high 8 bits of source address; bbbbbbbb -------- --------
;	y - # of bytes to transfer
dma_ch0:
	sta BBAD0
	stx A1T0L
	xba
	sta A1B0
	sty DAS0L

	lda #1
	sta MDMAEN ; run it
	rts

; params:
;	a - board pos
get_x_from_board_pos:
	and #%00000111
	; NOTE: assuming BOARD_WIDTH = 8. If it's not a power of 2 this will require a couple more instructions.
	asl a
	asl a
	asl a
	asl a ; x16
	clc
	adc #BOARD_X
	rts

; params:
;	a - board pos
get_y_from_board_pos:
	asl a
	and #%11110000
	; NOTE: assuming BOARD_WIDTH = 8. If it's not a power of 2 this will require a couple more instructions.
	clc
	adc #BOARD_Y
	rts

; params:
;	x - oam_lo_ind
;	a - bits to set (will be masked off for correct sprite, e.g. send over %10101010 and it will be masked off to only update %--10----)
set_oam_hi_bits:
	@new_hi_bits		= local
	@oam_hi_ind			= local+1
	@oam_hi_mask		= local+2
	pha
	a16
	txa
	lsr a
	lsr a
		pha
		and #%11
		tax
		pla
	lsr a
	lsr a ; /16
	a8
	sta @oam_hi_ind
	lda #%00000011
	@shift_left_loop:
		cpx #0
		beq :+
		asl a
		asl a
		dex
		bra @shift_left_loop
	:
	sta @oam_hi_mask

	pla
	and @oam_hi_mask
	sta @new_hi_bits
	lda @oam_hi_mask
	eor #$ff
	i8
	ldx @oam_hi_ind
	and OAM_DMA_ADDR_HI, x
	ora @new_hi_bits
	sta OAM_DMA_ADDR_HI, x
	i16
	rts

rand:
	; Galois linear feedback shift register
	; https://wiki.nesdev.org/w/index.php?title=Random_number_generator
	a16
	lda	seed
	ldx	#8
	@loop:
		asl a
		bcc :+
			eor #$0039
		:
		dex
		bne @loop
	sta seed
	a8
	rts

; params:
	; a - 8-bit number to mod against
	; x - 16-bit number to mod
mod:
	stx WRDIVL
	sta WRDIVB
	a16
	txa
	a8
	nop
	nop
	nop
	nop
	ldx RDDIVL
	beq @end
	ldx RDMPYL
	a16
	txa
	a8
	@end: rts

; hold button down, delay first before doing quick action
	.zeropage
delayed_action_ctr: .res 1
	.code
delayed_action:
	lda delayed_action_ctr
	cmp #16
	bcc :+
		lda #1
		rts
	:
	inc delayed_action_ctr
	lda #0
	rts

; hold button down to perform action quickly
	.zeropage
fast_action_ctr: .res 1
	.code
fast_action:
	inc fast_action_ctr
	lda fast_action_ctr
	and #%11
	cmp #1
	bne @no
	; yes:
		lda #1
		rts
	@no:
		lda #0
		rts