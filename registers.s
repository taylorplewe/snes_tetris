; rw?fvha
; ||||||+--> '+' if it can be read/written at any time, '-' otherwise
; |||||+---> '+' if it can be read/written during H-Blank
; ||||+----> '+' if it can be read/written during V-Blank
; |||+-----> '+' if it can be read/written during force-blank
; ||+------> Read/Write style: 'b'     => byte
; ||                           'h'/'l' => read/write high/low byte of a word
; ||                           'w'     => word read/write twice low then high
; |+-------> 'w' if the register is writable for an effect
; +--------> 'r' if the register is readable for a value or effect (i.e. not [open bus](/open-bus)).

INIDISP			= $2100 ; Screen Display Register
; wb++++
; 	x---bbbb
; 	x        = Force blank on when set.
; 		bbbb = Screen brightness, F=max, 0="off".
	INIDISP_BLANK = %10000000
OBSEL			= $2101 ; Object Size and Character Size Register
; wb++?- 
;  sssnnbbb
;  sss       = Object size:
;        000 =  8x8  and 16x16 sprites
;        001 =  8x8  and 32x32 sprites
;        010 =  8x8  and 64x64 sprites
;        011 = 16x16 and 32x32 sprites
;        100 = 16x16 and 64x64 sprites
;        101 = 32x32 and 64x64 sprites
;        110 = 16x32 and 32x64 sprites ('undocumented')
;        111 = 16x32 and 32x32 sprites ('undocumented')
;     nn     = Name Select
;       bbb  = Name Base Select (Addr>>14)
	OBSEL_8x8_16x16   = %00000000
	OBSEL_8x8_32x32   = %00100000
	OBSEL_8x8_64x64   = %01000000
	OBSEL_16x16_32x32 = %01100000
	OBSEL_16x16_64x64 = %10000000
	OBSEL_32x32_64x64 = %10100000
	OBSEL_16x32_32x64 = %11000000
	OBSEL_16x32_32x32 = %11100000
OAMADDL			= $2102 ; OAM Address Registers (Low)
OAMADDH			= $2103 ; OAM Address Registers (High)
; $2102  wl++?-
; $2103  wh++?-
; p------b aaaaaaaa
; p                 = Obj Priority activation bit
;        b aaaaaaaa = OAM address
; think of it this way:
;	b is the table selector; either the 512 byte LOW table or the 32 byte HIGH table
;	aaaaaaaa is the WORD address into either table
OAMDATA			= $2104 ; OAM Data Write Register
; wb++--
; dddddddd
; The record format for the low table is 4 bytes:
;	byte OBJ*4+0: xxxxxxxx
;	byte OBJ*4+1: yyyyyyyy
;	byte OBJ*4+2: cccccccc
;	byte OBJ*4+3: vhoopppN
; The record format for the high table is 2 bits:
; 	bit 0/2/4/6 of byte OBJ/4: X
; 	bit 1/3/5/7 of byte OBJ/4: s
; Xxxxxxxxx = X position of the sprite. Basically, consider this signed but see below.
; yyyyyyyy  = Y position of the sprite.^
; cccccccc  = First tile of the sprite.^^
; N         = Name table of the sprite. See below for the calculation of the VRAM address.
; ppp       = Palette of the sprite. The first palette index is 128+ppp*16.
; oo        = Sprite priority. See below for details.
; h/v       = Horizontal/Vertical flip flags.^^^
; s         = Sprite size flag. See below for details.
	SPRINFO_VFLIP	= %10000000
	SPRINFO_HFLIP	= %01000000
	SPRINFO_PRIOR0	= %00000000
	SPRINFO_PRIOR1	= %00010000
	SPRINFO_PRIOR2	= %00100000
	SPRINFO_PRIOR3	= %00110000
	SPRINFO_PAL0	= %00000000
	SPRINFO_PAL1	= %00000010
	SPRINFO_PAL2	= %00000100
	SPRINFO_PAL3	= %00000110
	SPRINFO_PAL4	= %00001000
	SPRINFO_PAL5	= %00001010
	SPRINFO_PAL6	= %00001100
	SPRINFO_PAL7	= %00001110
	SPRINFO_NT1		= %00000001
	SPR_HI_NEGX		= %01010101
	SPR_HI_LARGE	= %10101010
BGMODE			= $2105 ; BG Mode and Character Size Register
; wb+++-
; DCBAemmm

; A/B/C/D   = BG character size for BG1/BG2/BG3/BG4
; (set if that bg should use 16x16 tiles not 8x8)
;      mmm  = BG Mode
;     e     = Mode 1 BG3 priority bit
;     Mode     BG depth  OPT  Priorities
;              1 2 3 4        Front -> Back
;     -=-------=-=-=-=----=---============---
;      0       2 2 2 2    n    3AB2ab1CD0cd
;      1       4 4 2      n    3AB2ab1C 0c
;                 * if e set: C3AB2ab1  0c
;      2       4 4        y    3A 2B 1a 0b
;      3       8 4        n    3A 2B 1a 0b
;      4       8 2        y    3A 2B 1a 0b
;      5       4 2        n    3A 2B 1a 0b
;      6       4          y    3A 2  1a 0
;      7       8          n    3  2  1a 0
;      7+EXTBG 8 7        n    3  2B 1a 0b
	BGMODE_16x16_BG1 = %00010000
	BGMODE_16x16_BG2 = %00100000
	BGMODE_16x16_BG3 = %01000000
	BGMODE_16x16_BG4 = %10000000
	BGMODE_MODE0 = 0
	BGMODE_MODE1 = 1
	BGMODE_MODE2 = 2
	BGMODE_MODE3 = 3
	BGMODE_MODE4 = 4
	BGMODE_MODE5 = 5
	BGMODE_MODE6 = 6
	BGMODE_MODE7 = 7
	BGMODE_BG3PRIOR = %00001000
MOSAIC			= $2106 ; Mosaic Register
; wb+++-
; xxxxDCBA
;     A/B/C/D = Affect BG1/BG2/BG3/BG4
; xxxx        = pixel size, 0=1x1, F=16x16
BG1SC			= $2107 ; BG Tilemap Address Registers (BG1)
BG2SC			= $2108 ; BG Tilemap Address Registers (BG2)
BG3SC			= $2109 ; BG Tilemap Address Registers (BG3)
BG4SC			= $210A ; BG Tilemap Address Registers (BG4)
; $2107  wb++?-
; $2108  wb++?-
; $2109  wb++?-
; $210A  wb++?-

; 00000000 00000000 00000000 00000000


; aaaaaayx
; aaaaaa      = Tilemap address  in VRAM (Addr>>10)
;        x    = Tilemap horizontal mirroring
;       y     = Tilemap vertical mirroring
;       00  32x32   AA
;                   AA
;       01  64x32   AB
;                   AB
;       10  32x64   AA
;                   BB
;       11  64x64   AB
;                   CD
BG12NBA			= $210B ; BG Character Address Registers (BG1&2)
BG34NBA			= $210C ; BG Character Address Registers (BG3&4)
; $210B  wb++?-
; $210C  wb++?-
;         bbbbaaaa
;             aaaa = Base address for BG1/3 (Addr>>12)
;         bbbb     = Base address for BG2/4 (Addr>>12)
; Simply spoken: Saving "$63" into $210B makes the PPU look for the Tileset for BG2 at $6000 in the VRAM and for BG1 at $3000.
BG1HOFS			= $210D ; BG Scroll Registers (BG1)
BG1VOFS			= $210E ; BG Scroll Registers (BG1)
BG2HOFS			= $210F ; BG Scroll Registers (BG2)
BG2VOFS			= $2110 ; BG Scroll Registers (BG2)
BG3HOFS			= $2111 ; BG Scroll Registers (BG3)
BG3VOFS			= $2112 ; BG Scroll Registers (BG3)
BG4HOFS			= $2113 ; BG Scroll Registers (BG4)
BG4VOFS			= $2114 ; BG Scroll Registers (BG4)
; $210F  ww+++-
; $2110  ww+++-
; $2111  ww+++-
; $2112  ww+++-
; $2113  ww+++-
; $2114  ww+++-
;         ------xx xxxxxxxx
; Note that these are "write twice" registers, first the low byte is written then the high. Current theory is that writes to the register work like this:

; BGnHOFS = (Current<<8) | (Prev1&~7) | (Prev2&7);
; Prev1 = Current;
; Prev2 = Current;
; or
; BGnVOFS = (Current<<8) | Prev1;
; Prev1 = Current;
; Note that there is only one Prev1 shared by all eight BGnxOFS registers, and only one Prev2 shared by the four BGnHOFS registers. These are NOT shared with the M7* registers (not even M7xOFS and BG1xOFS).
VMAIN			= $2115 ; Video Port Control Register
; $2115  wb++?-
;         i---mmii
;         i          = Address increment mode^:
;                      0 => increment after writing $2118/reading $2139
;                      1 => increment after writing $2119/reading $213A
;               ii   = Address increment amount
;                      00 = Normal increment by 1
;                      01 = Increment by 32
;                      1- = Increment by 128
;             mm     = Address remapping
;                      00 = No remapping
;                      01 = Remap addressing aaaaaaaaBBBccccc => aaaaaaaacccccBBB
;                      10 = Remap addressing aaaaaaaBBBcccccc => aaaaaaaccccccBBB
;                      11 = Remap addressing aaaaaaBBBccccccc => aaaaaacccccccBBB
	VMAIN_WORDINC	= %10000000
	VMAIN_INC_1		= %00
	VMAIN_INC_32	= %01
	VMAIN_INC_128	= %10
VMADDL			= $2116 ; VRAM Address Registers (Low)
VMADDH			= $2117 ; VRAM Address Registers (High)
; $2116  wl++?-
; $2117  wh++?-
;         aaaaaaaa aaaaaaaa
VMDATAL			= $2118 ; VRAM Data Write Registers (Low)
VMDATAH			= $2119 ; VRAM Data Write Registers (High)
; $2118  wl++--
; $2119  wh++--
;         xxxxxxxx xxxxxxxx
; TILEMAPS:
;   VMDATAH     VMDATAL
;    $4119       $4118
; 15  bit  8   7  bit  0
;  ---- ----   ---- ----
;  VHPC CCTT   TTTT TTTT
;  |||| ||||   |||| ||||
;  |||| ||++---++++-++++- Tile index
;  |||+-++--------------- Palette selection
;  ||+------------------- Priority
;  ++-------------------- Flip vertical (V) or horizontal (H)
M7SEL			= $211A ; Mode 7 Settings Register
; $211A  wb++?-
;         rc----yx
;         r        = Playing field size^
;          c       = Empty space fill, when bit 7 is set:
;                    0 = Transparent.
;                    1 = Fill with character 0. Note that the fill is matrix transformed like all other Mode 7 tiles.
;              x/y = Horizontal/Vertical mirroring. If the bit is set, flip the 256x256 pixel 'screen' in that direction.
M7A				= $211B ; Mode 7 Matrix Registers
M7B				= $211C ; Mode 7 Matrix Registers
M7C				= $211D ; Mode 7 Matrix Registers
M7D				= $211E ; Mode 7 Matrix Registers
; $211B  ww+++-
; $211C  ww+++-
; $211D  ww+++-
; $211E  ww+++-
;         aaaaaaaa aaaaaaaa
M7X				= $211F ; Mode 7 Matrix Registers
M7Y				= $2120 ; Mode 7 Matrix Registers
; $211F  ww+++-
; $2120  ww+++-
;         ---xxxxx xxxxxxxx
CGADD			= $2121 ; CGRAM Address Register
; $2121  wb+++-
;         cccccccc
; Keep in mind the color index accessed by $2121 will automatically increment by 1 after writing a color to $2122. This is an effect generated by $2122 after being used in case you want to write specific colors in a series.
CGDATA			= $2122 ; CGRAM Data Write Register
; $2122  ww+++-
;         -bbbbbgg gggrrrrr
W12SEL			= $2123 ; Window Mask Settings Registers
W34SEL			= $2124 ; Window Mask Settings Registers
WOBJSEL			= $2125 ; Window Mask Settings Registers
; $2123  wb+++-
; $2124  wb+++-
; $2125  wb+++-
;         ABCDabcd
;                d = Window 1 Inversion for BG1/BG3/OBJ
;               c  = Enable window 1 for BG1/BG3/OBJ
;              b   = Window 2 Inversion for BG1/BG3/OBJ
;             a    = Enable window 2 for BG1/BG3/OBJ
;            D     = Window 1 Inversion for BG2/BG4/Color^^
;           C      = Enable window 1 for BG2/BG4/Color^
;          B       = Window 2 Inversion for BG2/BG4/Color^^
;         A        = Enable window 2 for BG2/BG4/Color^
WH0				= $2126 ; Window Position Registers (WH0)
WH1				= $2127 ; Window Position Registers (WH1)
WH2				= $2128 ; Window Position Registers (WH2)
WH3				= $2129 ; Window Position Registers (WH3)
; $2126  wb+++-
; $2127  wb+++-
; $2128  wb+++-
; $2129  wb+++-
;         xxxxxxxx
WBGLOG			= $212A ; Window Mask Logic registers (BG)
WOBJLOG			= $212B ; Window Mask Logic registers (OBJ)
; $212A  wb+++- 
;         44332211
; $212B  wb+++- 
;         ----ccoo

;         44/33/22/11/oo/cc = Mask logic for BG1/BG2/BG3/BG4/OBJ/Color
;             This specified the window combination method, using standard boolean operators:
;               00 = OR
;               01 = AND
;               10 = XOR
;               11 = XNOR
TM				= $212C ; Screen Destination Registers
TS				= $212D ; Screen Destination Registers
; $212C  wb+++-
; $212D  wb+++-
;         ---o4321

;         1/2/3/4/o = Enable BG1/BG2/BG3/BG4/OBJ for display on the main (or sub) screen.
TMW				= $212E ; Window Mask Destination Registers
TSW				= $212F ; Window Mask Destination Registers
; $212E  wb+++-
; $212F  wb+++-
;         ---o4321
;         1/2/3/4/o = Enable window masking for BG1/BG2/BG3/BG4/OBJ on the main (or sub) screen.
	TMSW_BG1 = %00000001
	TMSW_BG2 = %00000010
	TMSW_BG3 = %00000100
	TMSW_BG4 = %00001000
	TMSW_OBJ = %00010000
CGWSEL			= $2130 ; Color Math Registers
; $2130  wb+++-
;         ccmm--sd
;         cc       = Clip colors to black before math
;                    00 => Never
;                    01 => Outside Color Window only
;                    10 => Inside Color Window only
;                    11 => Always
;           mm     = Prevent color math
;                    00 => Never
;                    01 => Outside Color Window only
;                    10 => Inside Color Window only
;                    11 => Always
;               s  = Add subscreen (instead of fixed color)
;                d = Direct color mode for 256-color BGs
CGADSUB			= $2131 ; Color Math Registers
; $2131  wb+++-
;         shbo4321
;         s             = Add/subtract select
;                         0 => Add the colors
;                         1 => Subtract the colors
;          h            = Half color math.^
;           4/3/2/1/o/b = Enable color math on BG1/BG2/BG3/BG4/OBJ/Backdrop ^^
COLDATA			= $2132 ; Color Math Registers
; $2132  wb+++-
;         bgrccccc
;         b/g/r    = Which color plane(s) to set the intensity for.
;            ccccc = Color intensity.
SETINI			= $2133 ; Screen Mode Select Register
; $2133  wb+++-
;         se--poIi
;         s        = "External Sync".^
;          e       = Mode 7 EXTBG ("Extra BG").^^
;             p    = Enable pseudo-hires mode.^^^
;              o   = Overscan mode.^^^^
;               I  = OBJ Interlace.^^^^^
;                i = Screen interlace.^^^^^^
MPYL			= $2134 ; Multiplication Result Registers
MPYM			= $2135 ; Multiplication Result Registers
MPYH			= $2136 ; Multiplication Result Registers
; $2134 r l+++?
; $2135 r m+++?
; $2136 r h+++?
;         xxxxxxxx xxxxxxxx xxxxxxxx
SLHV			= $2137 ; Software Latch Register
OAMDATAREAD		= $2138 ; OAM Data Read Register
VMDATALREAD		= $2139 ; VRAM Data Read Register (Low)
VMDATAHREAD		= $213A ; VRAM Data Read Register (High)
CGDATAREAD		= $213B ; CGRAM Data Read Register
; $213B r w++?-
;         -bbbbbgg gggrrrrr
OPHCT			= $213C ; Scanline Location Registers (Horizontal)
OPVCT			= $213D ; Scanline Location Registers (Vertical)
; $213C r w++++
; $213D r w++++
;         -------x xxxxxxxx
STAT77			= $213E ; PPU Status Register
; $213E r b++++
;         trm-vvvv
;         t        = Time Over Flag.^
;          r       = Range Over Flag.^^
;           m      = "Master/slave mode select".^^^
;            -     = PPU1 Open Bus.
;             vvvv = 5c77 chip version number. So far, we've only encountered version 1.
STAT78			= $213F ; PPU Status Register
; $213F r b++++
;         fl-pvvvv
;         f        = Interlace Field.^
;          l       = External latch flag.^^
;           -      = PPU2 Open Bus.
;            p     = NTSC/Pal Mode.^^^
;             vvvv = 5C78 chip version number. So far, we've encountered at least 2 and 3. Possibly 1 as well.
APUIO0			= $2140 ; APU IO Registers
APUIO1			= $2141 ; APU IO Registers
APUIO2			= $2142 ; APU IO Registers
APUIO3			= $2143 ; APU IO Registers
; $2140 rwb++++
; $2141 rwb++++
; $2142 rwb++++
; $2143 rwb++++
;         xxxxxxxx
WMDATA			= $2180 ; WRAM Data Register
; $2180 rwb++++
;         xxxxxxxx
WMADDL			= $2181 ; WRAM Address Registers
WMADDM			= $2182 ; WRAM Address Registers
WMADDH			= $2183 ; WRAM Address Registers
; $2181  wl++++
; $2182  wm++++
; $2183  wh++++
;         -------x xxxxxxxx xxxxxxxx
JOYSER0			= $4016 ; Old Style Joypad Registers
JOYSER1			= $4017 ; Old Style Joypad Registers
; $4016 rwb++++
;         Rd: ------ca
;         Wr: -------l
; $4017 r?b++++
;         ---111db
;     l    = Writing this bit controls the Latch line of both controller ports. 
;            When 1 is set, the Latch goes high (or is it low? At any rate, whichever one makes the pads latch their state). 
;            When cleared, the Latch goes the other way.
    
;     a/b  = These bits return the state of the Data1 line.
;     c/d  = These bits return the state of the Data2 line.
;            Reading $4016 drives the Clock line of Controller Port 1 low.
;            The SNES then reads the Data1 and Data2 lines, and Clock is set back to high.
;            $4017 does the same for Port 2.
NMITIMEN		= $4200 ; Interrupt Enable Register
; $4200  wb+++?
;         n-yx---a
;         n        = Enable NMI.^
;           x/y    = IRQ enable.
;                    0/0 => No IRQ will occur
;                    0/1 => An IRQ will occur sometime just after the V Counter reaches the value set in $4209/a.
;                    1/0 => An IRQ will occur sometime just after the H Counter reaches the value set in $4207/8.
;                    1/1 => An IRQ will occur sometime just after the H Counter reaches the value set in $4207/8 when V Counter equals the value set in $4209/a.
;                a = Auto-Joypad Read Enable.^^
	NMITIMEN_NMIENABLE	= %10000000
	NMITIMEN_AUTOJOY	= %00000001
WRIO			= $4201 ; IO Port Write Register
WRMPYA			= $4202 ; Multiplicand Registers
WRMPYB			= $4203 ; Multiplicand Registers
; $4202  wb++++
; $4203  wb++++
;         mmmmmmmm
WRDIVL			= $4204 ; Divisor & Dividend Registers
WRDIVH			= $4205 ; Divisor & Dividend Registers
WRDIVB			= $4206 ; Divisor & Dividend Registers
; $4204  wl++++
; $4205  wh++++
;         dddddddd dddddddd
; $4206  wb++++
;         bbbbbbbb
HTIMEL			= $4207 ; IRQ Timer Registers (Horizontal - Low)
HTIMEH			= $4208 ; IRQ Timer Registers (Horizontal - High)
; $4207  wl++++
; $4208  wh++++
;         -------h hhhhhhhh
VTIMEL			= $4209 ; IRQ Timer Registers (Vertical - Low)
VTIMEH			= $420A ; IRQ Timer Registers (Vertical - High)
; $4209  wl++++
; $420A  wh++++
;         -------v vvvvvvvv
MDMAEN			= $420B ; DMA Enable Register
; $420B  wb++++
;         76543210
;         7/6/5/4/3/2/1/0 = Enable the selected DMA channels.^
HDMAEN			= $420C ; HDMA Enable Register
; $420C  wb++++
;         76543210
;         7/6/5/4/3/2/1/0 = Enable the selected HDMA channels.^
MEMSEL			= $420D ; ROM Speed Register
; $420D  wb++++
;         -------f
;                f = FastROM select.
RDNMI			= $4210 ; Interrupt Flag Registers
TIMEUP			= $4211 ; Interrupt Flag Registers
HVBJOY			= $4212 ; PPU Status Register
; $4212 r b++++
;         vh-----a
;         v        = V-Blank Flag.^
;          h       = H-Blank Flag.^^
;                a = Auto-Joypad Status.^^^
RDIO			= $4213 ; IO Port Read Register
RDDIVL			= $4214 ; Multiplication Or Divide Result Registers (Low)
RDDIVH			= $4215 ; Multiplication Or Divide Result Registers (High)
; $4214 r l++++
; $4215 r h++++
;         qqqqqqqq qqqqqqqq

;     Write $4204/5, then $4206. 16 "machine cycles" (probably 96 master
;     cycles) after $4206 is set, the quotient may be read from these
;     registers, and the remainder from $4216/7.
    
;     The division is unsigned.
RDMPYL			= $4216 ; Multiplication Or Divide Result Registers (Low)
RDMPYH			= $4217 ; Multiplication Or Divide Result Registers (High)
; $4216 r l++++
; $4217 r h++++
;         xxxxxxxx xxxxxxxx
; Write $4202, then $4203. 8 "machine cycles" (probably 48 master cycles) after $4203 is set, the product may be read from these registers. Write $4204/5, then $4206. 16 "machine cycles" (probably 96 master cycles) after $4206 is set, the quotient may be read from $4214/5, and the remainder from these registers. The multiplication and division are both unsigned.
JOY1L			= $4218 ; Controller Port Data Registers (Pad 1 - Low)
JOY1H			= $4219 ; Controller Port Data Registers (Pad 1 - High)
JOY2L			= $421A ; Controller Port Data Registers (Pad 2 - Low)
JOY2H			= $421B ; Controller Port Data Registers (Pad 2 - High)
JOY3L			= $421C ; Controller Port Data Registers (Pad 3 - Low)
JOY3H			= $421D ; Controller Port Data Registers (Pad 3 - High)
JOY4L			= $421E ; Controller Port Data Registers (Pad 4 - Low)
JOY4H			= $421F ; Controller Port Data Registers (Pad 4 - High)
; $4218 r l++++
; $4219 r h++++
; $421A r l++++
; $421B r h++++
; $421C r l++++
; $421D r h++++
; $421E r l++++
; $421F r h++++
;         byetUDLR axlr0000
;         a/b/x/y/l/r/e/t   = A/B/X/Y/L/R/Select/Start button status.
;         U/D/L/R           = Up/Down/Left/Right control pad status.
;                             Note that only one of L/R and only one of U/D may be set, due to the pad hardware.
	JOY_U			= %0000100000000000
	JOY_D			= %0000010000000000
	JOY_L			= %0000001000000000
	JOY_R			= %0000000100000000
	JOY_SHOULDER_L	= %0000000000100000
	JOY_SHOULDER_R	= %0000000000010000
	JOY_A			= %0000000010000000
	JOY_B			= %1000000000000000
	JOY_X			= %0000000001000000
	JOY_Y			= %0100000000000000
	JOY_START		= %0001000000000000
	JOY_SELECT		= %0010000000000000

; DMA

DMAP0			= $4300 ; DMA Control Register
; $43x0 rwb++++
;         da-ifttt
;         d        = Transfer Direction.^
;          a       = HDMA Addressing Mode.^^
;            i     = DMA Address Increment.^^^
;             f    = DMA Fixed Transfer.^^^^

;         ttt  = Transfer Mode.
;             000 => 1 register write once             (1 byte:  p               )
;             001 => 2 registers write once            (2 bytes: p, p+1          )
;             010 => 1 register write twice            (2 bytes: p, p            )
;             011 => 2 registers write twice each      (4 bytes: p, p,   p+1, p+1)
;             100 => 4 registers write once            (4 bytes: p, p+1, p+2, p+3)
;             101 => 2 registers write twice alternate (4 bytes: p, p+1, p,   p+1)
;             110 => 1 register write twice            (2 bytes: p, p            )
;             111 => 2 registers write twice each      (4 bytes: p, p,   p+1, p+1)
; ^When clear, data will be read from the CPU memory and written to the PPU register. When set, vice versa. Contrary to previous belief, this bit DOES affect HDMA! Indirect mode is more useful, it will read the table as normal and write from Bus B to the Bus A address specified. Direct mode will work as expected though, it will read counts from the table and try to write the data values into the table.

; ^^When clear, the HDMA table contains the data to transfer. When set, the HDMA table contains pointers to the data. This bit does not affect DMA.

; ^^^When clear, the DMA address will be incremented for each byte. When set, the DMA address will be decremented. This bit does not affect HDMA.

; ^^^^When set, the DMA address will not be adjusted. When clear, the address will be adjusted as specified by bit 4. This bit does not affect HDMA.
	DMAP_1REG_1WR		= %000
	DMAP_2REG_1WR		= %001
	DMAP_1REG_2WR		= %010
	DMAP_2REG_2WR_EACH	= %011
	DMAP_4REG_1WR		= %100
	DMAP_2REG_2WR_ALT	= %101
	DMAP_READ_FROM_PPU	= %10000000
	DMAP_DECR_SOURCE	= %00010000
	DMAP_FIXED_SOURCE	= %00001000
BBAD0			= $4301 ; DMA Destination Register
; $43x1 rwb++++
;         pppppppp
A1T0L			= $4302 ; DMA Source Address Registers
A1T0H			= $4303 ; DMA Source Address Registers
A1B0			= $4304 ; DMA Source Address Registers
; $43x2 rwl++++
; $43x3 rwh++++
; $43x4 rwb++++
;         bbbbbbbb hhhhhhhh llllllll
DAS0L			= $4305 ; DMA Size Registers (Low)
DAS0H			= $4306 ; DMA Size Registers (High)

DMAP1			= $4310 ; DMA Control Register
BBAD1			= $4311 ; DMA Destination Register
A1T1L			= $4312 ; DMA Source Address Registers
A1T1H			= $4313 ; DMA Source Address Registers
A1B1			= $4314 ; DMA Source Address Registers
DAS1L			= $4315 ; DMA Size Registers (Low)
DAS1H			= $4316 ; DMA Size Registers (High)

DMAP2			= $4320 ; DMA Control Register
BBAD2			= $4321 ; DMA Destination Register
A1T2L			= $4322 ; DMA Source Address Registers
A1T2H			= $4323 ; DMA Source Address Registers
A1B2			= $4324 ; DMA Source Address Registers
DAS2L			= $4325 ; DMA Size Registers (Low)
DAS2H			= $4326 ; DMA Size Registers (High)

DMAP3			= $4330 ; DMA Control Register
BBAD3			= $4331 ; DMA Destination Register
A1T3L			= $4332 ; DMA Source Address Registers
A1T3H			= $4333 ; DMA Source Address Registers
A1B3			= $4334 ; DMA Source Address Registers
DAS3L			= $4335 ; DMA Size Registers (Low)
DAS3H			= $4336 ; DMA Size Registers (High)

DMAP4			= $4340 ; DMA Control Register
BBAD4			= $4341 ; DMA Destination Register
A1T4L			= $4342 ; DMA Source Address Registers
A1T4H			= $4343 ; DMA Source Address Registers
A1B4			= $4344 ; DMA Source Address Registers
DAS4L			= $4345 ; DMA Size Registers (Low)
DAS4H			= $4346 ; DMA Size Registers (High)

DMAP5			= $4350 ; DMA Control Register
BBAD5			= $4351 ; DMA Destination Register
A1T5L			= $4352 ; DMA Source Address Registers
A1T5H			= $4353 ; DMA Source Address Registers
A1B5			= $4354 ; DMA Source Address Registers
DAS5L			= $4355 ; DMA Size Registers (Low)
DAS5H			= $4356 ; DMA Size Registers (High)

DMAP6			= $4360 ; DMA Control Register
BBAD6			= $4361 ; DMA Destination Register
A1T6L			= $4362 ; DMA Source Address Registers
A1T6H			= $4363 ; DMA Source Address Registers
A1B6			= $4364 ; DMA Source Address Registers
DAS6L			= $4365 ; DMA Size Registers (Low)
DAS6H			= $4366 ; DMA Size Registers (High)

; HDMA (shares registers and names with DMA?)

; DMAPx			= $43x0 ; HDMA Control Register
; BBADx			= $43x1 ; HDMA Destination Register
; A1TxL			= $43x2 ; HDMA Table Address Registers
; A1TxH			= $43x3 ; HDMA Table Address Registers
; A1Bx			= $43x4 ; HDMA Table Address Registers
; DASxL			= $43x5 ; HDMA Indirect Address Registers
; DASxH			= $43x6 ; HDMA Indirect Address Registers
; DASBx			= $43x7 ; HDMA Indirect Address Registers
; A2AxL			= $43x8 ; HDMA Mid Frame Table Address Registers (Low)
; A2AxH			= $43x9 ; HDMA Mid Frame Table Address Registers (High)
; NTLRX			= $43xA ; HDMA Line Counter Register