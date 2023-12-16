	.include "boiler.s"

OAM_DMA_ADDR_LO	= $1d00 ; 2 whole pages of low table OAM, 32 bytes of high table shared with stack page ($1f--)
OAM_DMA_ADDR_HI	= OAM_DMA_ADDR_LO + 512
OAM_NUM_BYTES	= 544

	.zeropage
local: .res 16
oam_lo_ind: .res 2
prev_joy1: .res 2
seed: .res 2
debug_mode: .res 1
started: .res 1
start_anim_ctr: .res 1
	
	.code
reset:
	; go into native mode lets gooooo
	clc
	xce ; Now you're playing with ~power~
	i16
	a8

	; clear all RAM
	ldx #2
	@clearallram:
		stz 0, x
		inx
		cpx #$2000
		bcc @clearallram

	dex
	txs ; stack now starts at $1fff

	; grab those first two bytes we didn't clear, hoping they're random, -> seed
	ldx $00
	stx seed

	lda #NMITIMEN_NMIENABLE | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn off screen for PPU writes
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

	; inc debug_mode

forever:
	a16
	inc seed
	a8

	jsr clear_oam
	jsr wait_for_input

	lda started
	bne :+
		jsr draw_press_start
		jsr start
		bra :++
	:
		; regular game update
		jsr bl_update
	:

	ldx JOY1L
	stx prev_joy1

	wai
	bra forever

nmi:
	pha
	phx
	phy

	; OAM (sprites)
	ldx #0
	stx OAMADDL
	m_dma_ch0 DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAMDATA, OAM_NUM_BYTES

	ply
	plx
	pla
	rti

; NOTE: if you're ever desparate for frame time to do stuff (that doesn't need controller input), place it before this function, which just waits until controller input is ready, gets called
wait_for_input:
	lda HVBJOY
	lsr a
	bcs wait_for_input
	rts

clear_oam:
	ldx #0
	stx oam_lo_ind
	lda #@oam_mush_lo
	@loloop:
		sta OAM_DMA_ADDR_LO, x
		inx
		cpx #512
		bcc @loloop
	ldx #0
	lda #@oam_mush_hi
	@hiloop:
		sta OAM_DMA_ADDR_HI, x
		inx
		cpx #32
		bcc @hiloop
	rts
	@oam_mush_lo = 224
	@oam_mush_hi = $ff

start:
	a16
	m_check_button_press #JOY_START, @end
	a8
	jsr bl_init
	inc started
	@end:
	a8
	rts

press_start_tiles:
	.byte $80, $82, $82, $84
	.byte $86, $88, $ff, $8c ; swap out a6 for 8a
	.byte $8e, $a0, $a2, $a4
press_start_x:
	.byte 0 +84, 16 +84, 32 +84, 48 +84
	.byte 0 +84, 16 +84, 32 +84, 48 +84
	.byte 0 +84, 16 +84, 32 +84, 48 +84
press_start_y:
	.byte 0 +88,  0 +88,  0 +88,  0 +88
	.byte 16 +88, 16 +88, 16 +88, 16 +88
	.byte 32 +88, 32 +88, 32 +88, 32 +88
draw_press_start:
	inc start_anim_ctr
	ldy #0
	ldx oam_lo_ind
	@loop:
		; x
		lda press_start_x, y
		sta OAM_DMA_ADDR_LO, x
		inx
		; y
		lda press_start_y, y
		sta OAM_DMA_ADDR_LO, x
		inx
		; tile
		lda press_start_tiles, y
		cmp #$ff
		bne :++
			lda start_anim_ctr
			and #%10000
			bne :+
				lda #$a6
				bra :++
			:
				lda #$8a
		:
		sta OAM_DMA_ADDR_LO, x
		inx
		; info
		lda #SPRINFO_PRIOR3 | SPRINFO_PAL2
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
		cpy #3*4
		bcc @loop
	rts
;

	; code
	.include "common.s"
	.include "init.s"

	.include "block.s"

	; data
chr:
	.incbin "bin/chr.bin"
chrend:
	.include "data/pals.s"
	.include "data/bgmap.s"
	.include "data/bg3map.s"