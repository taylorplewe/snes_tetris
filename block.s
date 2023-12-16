; bl

BOARD_WIDTH		= 8 ; 16x16 blocks
BOARD_HEIGHT	= 13 ; 16x16 blocks
BOARD_X			= 48 ; px
BOARD_Y			= 8 ; px
BOARD_ADDR		= $0100 ; in RAM
BOARD_NUM_BYTES	= BOARD_WIDTH * BOARD_HEIGHT ; in RAM
BLOCK_FALL_CTR_INTRVL	= 32 ; frames
BLOCK_START_INDEX	= 12

	.zeropage
bl_type: .res 1
bl_center: .res 2 ; hi = old one, for reverting after trying to rotate
bl_rotation: .res 2 ; hi = old one, for reverting after trying to rotate
	; 0 - 0°
	; 0 - 90° clockwise
	; 0 - 180°
	; 0 - 90° counter-clockwise
bl_formation_addr: .res 2
bl_tiles_addr: .res 2
bl_preview_tiles_addr: .res 2
bl_fall_ctr: .res 1
bl_cleared_lines: .res 4 ; first index of each line; up to 4 possible
bl_next_types: .res 7

	.code
bl_init:
	; init block
	lda #BLOCK_START_INDEX
	sta bl_center
	stz bl_rotation

	; block type
	jsr bl_generate_next_7
	jsr bl_get_next_type

	jsr bl_set_formation_addr

	lda #bl_next_types
	sta $80

	; reset cleared_lines
	lda #$ff
	sta bl_cleared_lines
	sta bl_cleared_lines+1
	sta bl_cleared_lines+2
	sta bl_cleared_lines+3
	rts

; generate next 7 blocks (1 each)
bl_generate_next_7:
	@possibles		= local ; 7 bytes
	@possibles_i	= local+7 ; 16-bit
	@possibles_len	= local+9 ; 16-bit
	; 1-7 possible
		lda #1
		sta @possibles
		inc a
		sta @possibles+1
		inc a
		sta @possibles+2
		inc a
		sta @possibles+3
		inc a
		sta @possibles+4
		inc a
		sta @possibles+5
		inc a
		sta @possibles+6
	;
	; lda #7 ; already there hun
	sta @possibles_len
	ldy #0
	@loop:
		m_rand_mod @possibles_len
		sta @possibles_i
		tax
		lda @possibles, x
		sta bl_next_types, y
		phy
		; splice @possibles array
		array_remove @possibles, @possibles_i, @possibles_len
		ply

		; next
		iny
		dec @possibles_len
		bne @loop
	rts

bl_get_next_type:
	lda bl_next_types
	sta bl_type
	ldx #0
	@loop:
		lda bl_next_types+1, x
		sta bl_next_types, x
		; next
		inx
		cpx #6
		bne @loop
	stz bl_next_types+6
	lda bl_next_types
	bne @end
		jsr bl_generate_next_7
	@end: rts

bl_update:
	; back up old vals
	lda bl_center
	sta bl_center+1
	lda bl_rotation
	sta bl_rotation+1

	jsr bl_fall
	jsr bl_control
	jsr bl_draw_board
	jsr bl_draw_block
	jsr bl_draw_preview
	jsr bl_draw_next
	rts

bl_fall:
	lda debug_mode
	bne @end
	a16
	lda JOY1L
	and #JOY_D
	bne @end
	a8
	inc bl_fall_ctr
	lda bl_fall_ctr
	cmp #BLOCK_FALL_CTR_INTRVL
	bcc @end
	stz bl_fall_ctr
	jsr bl_move_d
	@end: rts

bl_control:
	.macro bl_move_r
		lda bl_center
		and #%111
		cmp #%111
		beq @end
		lda #1
		jmp bl_try_move_dir
		.endmacro
	.macro bl_move_l
		lda bl_center
		and #%111
		beq @end
		lda #<-1
		jmp bl_try_move_dir
		.endmacro
	; →
		a16
		lda JOY1L
		and #JOY_R
		beq :++
			a8
			jsr delayed_action
			beq :+
			jsr fast_action
			beq :++
			bra @mover
		:
		a16
		lda prev_joy1
		and #JOY_R
		bne :+
			@mover:
			a8
			bl_move_r
			.a16
	: ; ←
		a16
		lda JOY1L
		and #JOY_L
		beq :++
			a8
			jsr delayed_action
			beq :+
			jsr fast_action
			beq :++
			bra @movel
		:
		a16
		lda prev_joy1
		and #JOY_L
		bne :+
			@movel:
			a8
			bl_move_l
			.a16
	:
	a16
	lda JOY1L
	and #JOY_R | JOY_L
	bne :+
		a8
		stz z:delayed_action_ctr
		a16
	: ; a
		m_check_button_press #JOY_A, :+
			a8
			lda #1
			jmp bl_rotate
			@end: rts
			.a16
	: ; b
		m_check_button_press #JOY_B, :+
			a8
			lda #<-1
			jmp bl_rotate
			.a16
	: ; ↓
		lda JOY1L
		and #JOY_D
		beq :+
			a8
			jsr fast_action
			beq @end
			jmp bl_move_d
			.a16
	: ; R
		m_check_button_press #JOY_SHOULDER_R, :+
			a8
			lda #0
			xba
			jmp bl_incr_type
			.a16
	: ; L
		m_check_button_press #JOY_SHOULDER_L, :+
			a8
			lda #5
			xba
			jmp bl_incr_type
			.a16
	: ; sel
		m_check_button_press #JOY_SELECT, :+
			lda debug_mode
			eor #1
			sta debug_mode
	:
	lda JOY1L
	and #JOY_R | JOY_L | JOY_D
	a8
	bne :+
		stz z:fast_action_ctr
	: rts

; params:
;	b - # to add to type (0 for incr, 5 for decr)
bl_incr_type:
	lda debug_mode
	beq @end
	xba
	clc
	adc bl_type
	ldb #0
	tax
	lda #7
	jsr mod
	inc a
	sta bl_type
	jmp bl_set_formation_addr
	@end: rts

bl_move_d:
	lda #BOARD_WIDTH
	jsr bl_try_move_dir
	beq @end
	; landed
		jmp bl_land
	@end: rts

bl_land:
	; add current block to board
	i8
	ldy #0
	@loop:
		lda bl_center
		clc
		adc (bl_formation_addr), y
		tax
		lda (bl_tiles_addr), y
		sta BOARD_ADDR, x
		iny
		cpy #4
		bcc @loop
	i16

	; destroy line(s) & make above ones fall down
	jsr bl_clear_lines
	jsr bl_fall_lines
	
	; create new block
	lda #BLOCK_START_INDEX
	sta bl_center

	; only random type if !debug_mode
	lda debug_mode
	bne :+
		jsr bl_get_next_type
	:
	stz bl_rotation
		; back up old vals
		lda bl_center
		sta bl_center+1
		lda bl_rotation
		sta bl_rotation+1
	jsr bl_set_formation_addr
	jsr bl_rotate_adjust
	cmp #$ff
	bne @end
		jmp reset
	@end: rts

bl_clear_lines:
	ldy #0
	@loop:
		lda bl_center
		clc
		adc (bl_formation_addr), y
		and #%11111000
		ldb #0
		tax
		jsr bl_clear_line
		iny
		cpy #4
		bcc @loop
	rts
bl_clear_line:
	lda BOARD_ADDR, x
	beq @no
	inx
	txa
	and #%111
	bne bl_clear_line
	; clear line, add to cleared_lines (for falling)
	dex
	txa
	and #%11111000
	xba
	jsr bl_add_cleared_line
	@clear:
		stz BOARD_ADDR, x
		dex
		txa
		and #%111
		cmp #%111
		bne @clear
	@no:
	rts

; params:
;	b - first index of row to clear
bl_add_cleared_line:
	phx	
	ldx #0
	@loop:
		lda bl_cleared_lines, x
		cmp #$ff
		beq :+
			inx
			bra @loop
		:
		xba
		sta bl_cleared_lines, x
	plx
	rts

bl_fall_lines:
	@loop:
		lda bl_cleared_lines
		cmp #$ff
		beq @end
			; move data up until here
			a16
			and #%0000000011111111
			dec a ; count
			pha
			; source
				clc
				adc #BOARD_ADDR
				tax
			; destination
				clc
				adc #BOARD_WIDTH
				tay
			pla ; get source back in C
			mvp 0, 0
			a8
			; mvp
			; source = LAST block of line ABOVE empty line
			; destination = LAST block of EMPTY line
			; count = a - 1
			stz BOARD_ADDR
			stz BOARD_ADDR+1
			stz BOARD_ADDR+2
			stz BOARD_ADDR+3
			stz BOARD_ADDR+4
			stz BOARD_ADDR+5
			stz BOARD_ADDR+6
			stz BOARD_ADDR+7
		; shift up cleared_lines
		lda bl_cleared_lines+1
		sta bl_cleared_lines
		lda bl_cleared_lines+2
		sta bl_cleared_lines+1
		lda bl_cleared_lines+3
		sta bl_cleared_lines+2
		lda #$ff
		sta bl_cleared_lines+3
		bra @loop
	@end: rts

; params:
;	a - # to add to bl_rotation (1 or -1)
bl_rotate:
	clc
	adc bl_rotation
	and #%11
	sta bl_rotation
	jsr bl_set_formation_addr
	jsr bl_rotate_adjust
	jsr bl_set_formation_addr
	rts
; try placing newly rotated block in free space
bl_rotate_adjust:
	jsr bl_check_free
	beq @end
	cmp #BL_CHECK_FREE_BORDER_L
	beq @try_r
	cmp #BL_CHECK_FREE_BORDER_R
	beq @try_l
	cmp #BL_CHECK_FREE_BORDER_D
	beq @try_u
	@try_r:
		lda bl_center
		and #%111
		cmp #%111
		beq @try_l
		inc bl_center
		jsr bl_check_free
		beq @end
	; try 2R
		lda bl_center
		and #%111
		cmp #%111
		beq @try_l
		inc bl_center
		jsr bl_check_free
		beq @end
	@try_l:
		lda bl_center+1
		sta bl_center
		and #%111
		beq @try_u
		dec bl_center
		jsr bl_check_free
		beq @end
	; try 2L
		lda bl_center
		and #%111
		beq @try_u
		dec bl_center
		jsr bl_check_free
		beq @end
	@try_u:
		lda bl_center+1
		sec
		sbc #BOARD_WIDTH
		sta bl_center
		jsr bl_check_free
		beq @end
	; try 2U
		lda bl_center
		sec
		sbc #BOARD_WIDTH
		sta bl_center
		jsr bl_check_free
		beq @end
	@try_d:
		lda bl_center+1
		cmp #BOARD_NUM_BYTES - BOARD_WIDTH
		bcs @revert
		clc
		adc #BOARD_WIDTH
		sta bl_center
		jsr bl_check_free
		beq @end
	; no free space possible, revert rotation
	@revert:
	lda bl_center+1
	sta bl_center
	lda bl_rotation+1
	sta bl_rotation
	lda #$ff ; screem
	@end: rts

; params:
;	a - # to add to each block index to check
bl_try_move_dir:
	clc
	adc bl_center
	sta bl_center
	jsr bl_check_free
	beq @free
	; collision
		lda bl_center+1
		sta bl_center
		lda #$ff
		rts
	@free:
		lda #0
		rts

; check all segments of block in current place, considers other blocks on board as well as L, R and D borders
; returns 0 if free, one of ur mom's constants ↓ otherwise
bl_check_free:
	BL_CHECK_FREE_BLOCK		= 1
	BL_CHECK_FREE_BORDER_L	= 2
	BL_CHECK_FREE_BORDER_R	= 3
	BL_CHECK_FREE_BORDER_D	= 4
	.macro bl_check_free_side_border
		pha
		xba
		lda bl_center
		and #%111
		cmp #BOARD_WIDTH / 2
		bcs @r
		; l:
			xba
			and #%111
			cmp #%111
			bne :+
			pla
			lda #BL_CHECK_FREE_BORDER_L
			rts
		@r:
			xba
			and #%111
			bne :+
			pla
			lda #BL_CHECK_FREE_BORDER_R
			rts
		:
		pla
	.endmacro
	.macro bl_check_free_bottom_border
		pha
		cmp #BOARD_NUM_BYTES
		bcc :+
			pla
			lda #BL_CHECK_FREE_BORDER_D
			rts
		:
		pla
	.endmacro
	.macro bl_check_free_blocks
		ldb #0
		tax
		lda BOARD_ADDR, x
		beq :+
			lda #BL_CHECK_FREE_BLOCK
			rts
		:
	.endmacro
	ldy #0
	@loop:
		lda bl_center
		clc
		adc (bl_formation_addr), y
		bl_check_free_side_border
		bl_check_free_bottom_border
		bl_check_free_blocks
		; next
		iny
		cpy #4
		bcc @loop
	lda #0 ; free
	rts

bl_set_formation_addr:
	@rotation_offset = local
	lda bl_rotation
	asl a
	asl a
	sta @rotation_offset
	lda bl_type
	dec a
	asl a
	asl a
	asl a
	asl a
	ora @rotation_offset
	a16
	and #%0000000011111111
	clc
	adc #bl_formations
	sta bl_formation_addr
	clc
	adc #bl_tiles-bl_formations
	sta bl_tiles_addr
	clc
	adc #bl_preview_tiles-bl_tiles
	sta bl_preview_tiles_addr
	a8
	rts

bl_draw_board:
	ldy #0
	@loop:
		lda BOARD_ADDR, y
		beq :+
			xba
			i8
			tya
			i16
			phy
			ldy #SPRINFO_PRIOR3 | SPRINFO_NT1
			jsr bl_draw_block_piece
			ply
		:
		iny
		cpy #BOARD_NUM_BYTES
		bcc @loop
	rts

bl_draw_block:
	; draw all four blocks of whole block
	ldy #0
	@loop:
		lda (bl_tiles_addr), y
		xba
		lda bl_center
		clc
		adc (bl_formation_addr), y
		phy
		ldy #SPRINFO_PRIOR3 | SPRINFO_NT1
		jsr bl_draw_block_piece
		ply
		iny
		cpy #4
		bcc @loop
	rts

bl_draw_preview:
	.zeropage
	bl_preview_center: .res 1
	.code
	; first figure out where preview should go
	lda bl_center
	sta bl_center+1
	sta bl_preview_center
	@down_loop:
		lda bl_center
		clc
		adc #BOARD_WIDTH
		sta bl_center
		jsr bl_check_free
		bne @hit
		lda bl_center
		sta bl_preview_center
		bra @down_loop
	@hit:
	lda bl_center+1
	sta bl_center

	ldy #0
	@draw_loop:
		lda (bl_preview_tiles_addr), y
		xba
		lda bl_preview_center
		clc
		adc (bl_formation_addr), y
		phy
		ldy #SPRINFO_PRIOR3 | (1 << 1)
		jsr bl_draw_block_piece
		ply
		iny
		cpy #4
		bcc @draw_loop
	rts

BL_NEXT_CENTER = $2e
bl_next_xoffs_table:
	.byte 56, 72, 64, 64, 56, 64, 64
bl_draw_next:
	.zeropage
	bl_next_tiles_addr: .res 2
	bl_next_formation_addr: .res 2
	bl_next_xoffs: .res 1
	.code

	lda debug_mode
	beq :+
		rts
	:

	; set addresses
	lda bl_next_types
	pha
	dec a
	ldb #0
	tax
	lda bl_next_xoffs_table, x
	sta bl_next_xoffs
	pla
	dec a
	asl a
	asl a
	asl a
	asl a
	a16
	and #%0000000011111111
	clc
	adc #bl_formations
	sta bl_next_formation_addr
	clc
	adc #bl_tiles-bl_formations
	sta bl_next_tiles_addr
	a8

	; draw all four blocks of whole block
	ldy #0
	@loop:
		ldx oam_lo_ind
		lda #BL_NEXT_CENTER
		clc
		adc (bl_next_formation_addr), y
		pha
		; x
		jsr get_x_from_board_pos
		clc
		adc bl_next_xoffs
		sta OAM_DMA_ADDR_LO, x
		inx
		; y
		; lda bl_center
		pla
		jsr get_y_from_board_pos
		sta OAM_DMA_ADDR_LO, x
		inx
		; tile
		lda (bl_next_tiles_addr), y
		sta OAM_DMA_ADDR_LO, x
		inx
		; info
		lda #SPRINFO_PRIOR3 | SPRINFO_NT1
		sta OAM_DMA_ADDR_LO, x
		inx
	; hi bits
		phx
		ldx oam_lo_ind
		lda #SPR_HI_LARGE
		jsr set_oam_hi_bits
		plx
		stx oam_lo_ind

		iny
		cpy #4
		bcc @loop
	rts

; params:
;	a - board index of block to draw
;	b - block type (for tile)
;	y - info byte
bl_draw_block_piece:
	pha
	ldx oam_lo_ind
		; x
		; a = board index
		jsr get_x_from_board_pos
		sta OAM_DMA_ADDR_LO, x
		inx
		; y
		; lda bl_center
		pla
		jsr get_y_from_board_pos
		sta OAM_DMA_ADDR_LO, x
		inx
		; tile
		; lda #34
		xba
		sta OAM_DMA_ADDR_LO, x
		inx
		; info
		; uncomment these to do the palette per type thing
		; xba
		; dec a
		; asl a
		; lda #0
		; ora #SPRINFO_PRIOR3 | SPRINFO_NT1
		tya
		sta OAM_DMA_ADDR_LO, x
		inx
	; hi bits
		phx
		ldx oam_lo_ind
		lda #SPR_HI_LARGE
		jsr set_oam_hi_bits
		plx
		stx oam_lo_ind
	rts

bl_formations:
	; all formations MUST go top to bottom or lines will get cleared incorrectly
	; l0:
		.byte <-BOARD_WIDTH
		.byte 0
		.byte BOARD_WIDTH
		.byte BOARD_WIDTH + 1
	; l1:
		.byte <-1
		.byte 0
		.byte 1
		.byte BOARD_WIDTH - 1
	; l2:
		.byte <-BOARD_WIDTH
		.byte <-BOARD_WIDTH - 1
		.byte 0
		.byte BOARD_WIDTH
	; l3:
		.byte <-BOARD_WIDTH + 1
		.byte <-1
		.byte 0
		.byte 1

	; j0:
		.byte <-BOARD_WIDTH
		.byte 0
		.byte BOARD_WIDTH
		.byte BOARD_WIDTH - 1
	; j1:
		.byte <-BOARD_WIDTH - 1
		.byte 1
		.byte 0
		.byte <-1
	; j2:
		.byte <-BOARD_WIDTH + 1
		.byte <-BOARD_WIDTH
		.byte 0
		.byte BOARD_WIDTH
	; j3:
		.byte <-1
		.byte 0
		.byte 1
		.byte BOARD_WIDTH + 1

	; s0:
		.byte <-BOARD_WIDTH
		.byte <-BOARD_WIDTH + 1
		.byte <-1
		.byte 0
	; s1:
		.byte <-BOARD_WIDTH
		.byte 0
		.byte 1
		.byte BOARD_WIDTH + 1
	; s2:
		.byte 0
		.byte 1
		.byte BOARD_WIDTH - 1
		.byte BOARD_WIDTH
	; s3:
		.byte <-BOARD_WIDTH - 1
		.byte <-1
		.byte 0
		.byte BOARD_WIDTH
	
	; z0:
		.byte <-BOARD_WIDTH
		.byte <-BOARD_WIDTH - 1
		.byte 1
		.byte 0
	; z1:
		.byte <-BOARD_WIDTH + 1
		.byte 0
		.byte 1
		.byte BOARD_WIDTH
	; z2:
		.byte 0
		.byte <-1
		.byte BOARD_WIDTH + 1
		.byte BOARD_WIDTH
	; z3:
		.byte <-BOARD_WIDTH
		.byte <-1
		.byte 0
		.byte BOARD_WIDTH - 1

	; o0:
		.byte <-BOARD_WIDTH
		.byte <-BOARD_WIDTH+1
		.byte 0
		.byte 1
	; o1:
		.byte <-BOARD_WIDTH
		.byte <-BOARD_WIDTH+1
		.byte 0
		.byte 1
	; o2:
		.byte <-BOARD_WIDTH
		.byte <-BOARD_WIDTH+1
		.byte 0
		.byte 1
	; o3:
		.byte <-BOARD_WIDTH
		.byte <-BOARD_WIDTH+1
		.byte 0
		.byte 1

	; i0:
		.byte <-BOARD_WIDTH
		.byte 0
		.byte BOARD_WIDTH
		.byte BOARD_WIDTH * 2
	; i1:
		.byte 1
		.byte 0
		.byte <-1
		.byte <-2
	; i2:
		.byte <(-BOARD_WIDTH*2)
		.byte <-BOARD_WIDTH
		.byte 0
		.byte BOARD_WIDTH
	; i3:
		.byte <-1
		.byte 0
		.byte 1
		.byte 2

	; t0:
		.byte <-BOARD_WIDTH
		.byte <-1
		.byte 0
		.byte 1
	; t1:
		.byte <-BOARD_WIDTH
		.byte 0
		.byte 1
		.byte BOARD_WIDTH
	; t2:
		.byte <-1
		.byte 0
		.byte 1
		.byte BOARD_WIDTH
	; t3:
		.byte <-BOARD_WIDTH
		.byte 0
		.byte <-1
		.byte BOARD_WIDTH

bl_tiles:
	; all formations MUST go top to bottom or lines will get cleared incorrectly
	; l0:
		.byte $c0
		.byte $c2
		.byte $c4
		.byte $c6
	; l1:
		.byte $e8
		.byte $ea
		.byte $ec
		.byte $ee
	; l2:
		.byte $e2
		.byte $e0
		.byte $e4
		.byte $e6
	; l3:
		.byte $c8
		.byte $ca
		.byte $cc
		.byte $ce

	; j0:
		.byte $c0
		.byte $c2
		.byte $a6
		.byte $a4
	; j1:
		.byte $a8
		.byte $ec
		.byte $ea
		.byte $aa
	; j2:
		.byte $a2
		.byte $a0
		.byte $e4
		.byte $e6
	; j3:
		.byte $ca
		.byte $cc
		.byte $ac
		.byte $ae

	; s0:
		.byte $20
		.byte $22
		.byte $24
		.byte $26
	; s1:
		.byte $28
		.byte $2a
		.byte $2c
		.byte $2e
	; s2:
		.byte $20
		.byte $22
		.byte $24
		.byte $26
	; s3:
		.byte $28
		.byte $2a
		.byte $2c
		.byte $2e
	
	; z0:
		.byte $e2
		.byte $24
		.byte $22
		.byte $02
	; z1:
		.byte $28
		.byte $04
		.byte $06
		.byte $2e
	; z2:
		.byte $e2
		.byte $24
		.byte $22
		.byte $02
	; z3:
		.byte $28
		.byte $04
		.byte $06
		.byte $2e

	; o0:
		.byte $08
		.byte $0a
		.byte $0c
		.byte $0e
	; o1:
		.byte $08
		.byte $0a
		.byte $0c
		.byte $0e
	; o2:
		.byte $08
		.byte $0a
		.byte $0c
		.byte $0e
	; o3:
		.byte $08
		.byte $0a
		.byte $0c
		.byte $0e

	; i0:
		.byte $80
		.byte $82
		.byte $84
		.byte $86
	; i1:
		.byte $8e
		.byte $8c
		.byte $8a
		.byte $88
	; i2:
		.byte $80
		.byte $82
		.byte $84
		.byte $86
	; i3:
		.byte $88
		.byte $8a
		.byte $8c
		.byte $8e

	; t0:
		.byte $60
		.byte $62
		.byte $64
		.byte $66
	; t1:
		.byte $48
		.byte $4a
		.byte $4c
		.byte $4e
	; t2:
		.byte $40
		.byte $42
		.byte $44
		.byte $46
	; t3:
		.byte $68
		.byte $6c
		.byte $6a
		.byte $6e
bl_preview_tiles:
	; all formations MUST go top to bottom or lines will get cleared incorrectly
	; l0:
		.byte $c0
		.byte $e0
		.byte $e8
		.byte $c6
	; l1:
		.byte $ec
		.byte $c4
		.byte $c6
		.byte $e6
	; l2:
		.byte $ea
		.byte $c2
		.byte $e0
		.byte $e6
	; l3:
		.byte $c0
		.byte $c2
		.byte $c4
		.byte $ee

	; j0:
		.byte $c0
		.byte $e0
		.byte $ee
		.byte $c2
	; j1:
		.byte $c0
		.byte $c6
		.byte $c4
		.byte $e8
	; j2:
		.byte $c6
		.byte $ec
		.byte $e0
		.byte $e6
	; j3:
		.byte $c2
		.byte $c4
		.byte $ea
		.byte $e6

	; s0:
		.byte $ec
		.byte $c6
		.byte $c2
		.byte $ee
	; s1:
		.byte $c0
		.byte $e8
		.byte $ea
		.byte $e6
	; s2:
		.byte $ec
		.byte $c6
		.byte $c2
		.byte $ee
	; s3:
		.byte $c0
		.byte $e8
		.byte $ea
		.byte $e6
	
	; z0:
		.byte $ea
		.byte $c2
		.byte $c6
		.byte $e8
	; z1:
		.byte $c0
		.byte $ec
		.byte $ee
		.byte $e6
	; z2:
		.byte $ea
		.byte $c2
		.byte $c6
		.byte $e8
	; z3:
		.byte $c0
		.byte $ec
		.byte $ee
		.byte $e6

	; o0:
		.byte $e2
		.byte $e4
		.byte $ac
		.byte $ae
	; o1:
		.byte $e2
		.byte $e4
		.byte $ac
		.byte $ae
	; o2:
		.byte $e2
		.byte $e4
		.byte $ac
		.byte $ae
	; o3:
		.byte $e2
		.byte $e4
		.byte $ac
		.byte $ae

	; i0:
		.byte $c0
		.byte $e0
		.byte $e0
		.byte $e6
	; i1:
		.byte $c6
		.byte $c4
		.byte $c4
		.byte $c2
	; i2:
		.byte $c0
		.byte $e0
		.byte $e0
		.byte $e6
	; i3:
		.byte $c2
		.byte $c4
		.byte $c4
		.byte $c6

	; t0:
		.byte $c0
		.byte $c2
		.byte $c8
		.byte $c6
	; t1:
		.byte $c0
		.byte $ce
		.byte $c6
		.byte $e6
	; t2:
		.byte $c2
		.byte $ca
		.byte $c6
		.byte $e6
	; t3:
		.byte $c0
		.byte $cc
		.byte $c2
		.byte $e6