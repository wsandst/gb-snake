INCLUDE "hardware.inc"
INCLUDE "helpers.inc"
EXPORT PrintByte

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

	; Do not turn the LCD off outside of VBlank
WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; Copy the tile data
	ld de, TilesGame
	ld hl, $9000
	ld bc, TilesGameEnd - TilesGame
	call Memcpy

	; Copy the tilemap
	ld de, TilemapGame
	ld hl, $9800
	ld bc, TilemapGameEnd - TilemapGame
	call Memcpy

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a

	ld a, $A4
	call PrintByte

Done:
	jp Done

SECTION "Tile data", ROM0

TilesGame:
	db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, ; body0000/background, 0
	db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $06,$f9, $09,$f0, $09,$f0, $06,$f9, ; body0001, 1
	db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $60,$9f, $90,$0f, $90,$0f, $60,$9f, ; body0010, 2
	db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $66,$99, $99,$00, $99,$00, $66,$99, ; body0011, 3
	db $06,$f9, $09,$f0, $09,$f0, $06,$f9, $00,$ff, $00,$ff, $00,$ff, $00,$ff, ; body0100, 4
	db $06,$f9, $09,$f0, $09,$f0, $06,$f9, $06,$f9, $09,$f0, $09,$f0, $06,$f9, ; body0101, 5
	db $06,$f9, $09,$f0, $09,$f0, $06,$f9, $60,$9f, $90,$0f, $90,$0f, $60,$9f, ; body0110, 6
	db $06,$f9, $09,$f0, $09,$f0, $06,$f9, $66,$99, $99,$00, $99,$00, $66,$99, ; body0111, 7
	db $60,$9f, $90,$0f, $90,$0f, $60,$9f, $00,$ff, $00,$ff, $00,$ff, $00,$ff, ; body1000, 8
	db $60,$9f, $90,$0f, $90,$0f, $60,$9f, $06,$f9, $09,$f0, $09,$f0, $06,$f9, ; body1001, 9
	db $60,$9f, $90,$0f, $90,$0f, $60,$9f, $60,$9f, $90,$0f, $90,$0f, $60,$9f, ; body1010, 10
	db $60,$9f, $90,$0f, $90,$0f, $60,$9f, $66,$99, $99,$00, $99,$00, $66,$99, ; body1011, 11
	db $66,$99, $99,$00, $99,$00, $66,$99, $00,$ff, $00,$ff, $00,$ff, $00,$ff, ; body1100, 12
	db $66,$99, $99,$00, $99,$00, $66,$99, $06,$f9, $09,$f0, $09,$f0, $06,$f9, ; body1101, 13
	db $66,$99, $99,$00, $99,$00, $66,$99, $60,$9f, $90,$0f, $90,$0f, $60,$9f, ; body1110, 14
	db $66,$99, $99,$00, $99,$00, $66,$99, $66,$99, $99,$00, $99,$00, $66,$99, ; body1111, 15

	db $00,$ff, $70,$8f, $fc,$23, $fe,$01, $fe,$01, $fc,$23, $70,$8f, $00,$ff, ; head, 16
TilesGameEnd:

TilesTitle:
	db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff
	db $00,$ff, $00,$80, $00,$80, $00,$80, $00,$80, $00,$80, $00,$80, $00,$80
	db $00,$ff, $00,$7e, $00,$7e, $00,$7e, $00,$7e, $00,$7e, $00,$7e, $00,$7e
	db $00,$ff, $00,$01, $00,$01, $00,$01, $00,$01, $00,$01, $00,$01, $00,$01
	db $00,$ff, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00
	db $00,$ff, $00,$7f, $00,$7f, $00,$7f, $00,$7f, $00,$7f, $00,$7f, $00,$7f
	db $00,$ff, $03,$fc, $00,$f8, $00,$f0, $00,$e0, $20,$c0, $00,$c0, $40,$80
	db $00,$ff, $c0,$3f, $00,$1f, $00,$0f, $00,$07, $04,$03, $00,$03, $02,$01
	db $00,$80, $00,$80, $7f,$80, $00,$80, $00,$80, $7f,$80, $7f,$80, $00,$80
	db $00,$7e, $2a,$7e, $d5,$7e, $2a,$7e, $54,$7e, $ff,$00, $ff,$00, $00,$00
	db $00,$01, $00,$01, $ff,$01, $00,$01, $01,$01, $fe,$01, $ff,$01, $00,$01
	db $00,$80, $80,$80, $7f,$80, $80,$80, $00,$80, $ff,$80, $7f,$80, $80,$80
	db $00,$7f, $2a,$7f, $d5,$7f, $2a,$7f, $55,$7f, $ff,$00, $ff,$00, $00,$00
	db $00,$ff, $aa,$ff, $55,$ff, $aa,$ff, $55,$ff, $fa,$07, $fd,$07, $02,$07
	db $00,$7f, $2a,$7f, $d5,$7f, $2a,$7f, $55,$7f, $aa,$7f, $d5,$7f, $2a,$7f
	db $00,$ff, $80,$ff, $00,$ff, $80,$ff, $00,$ff, $80,$ff, $00,$ff, $80,$ff
	db $40,$80, $00,$80, $7f,$80, $00,$80, $00,$80, $7f,$80, $7f,$80, $00,$80
	db $00,$3c, $02,$7e, $85,$7e, $0a,$7e, $14,$7e, $ab,$7e, $95,$7e, $2a,$7e
	db $02,$01, $00,$01, $ff,$01, $00,$01, $01,$01, $fe,$01, $ff,$01, $00,$01
	db $00,$ff, $80,$ff, $50,$ff, $a8,$ff, $50,$ff, $a8,$ff, $54,$ff, $a8,$ff
	db $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80
	db $ff,$00, $ff,$00, $ff,$00, $ab,$7e, $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e
	db $ff,$01, $fe,$01, $ff,$01, $fe,$01, $ff,$01, $fe,$01, $ff,$01, $fe,$01
	db $7f,$80, $ff,$80, $7f,$80, $ff,$80, $7f,$80, $ff,$80, $7f,$80, $ff,$80
	db $ff,$00, $ff,$00, $ff,$00, $aa,$7f, $d5,$7f, $aa,$7f, $d5,$7f, $aa,$7f
	db $f8,$07, $f8,$07, $f8,$07, $80,$ff, $00,$ff, $aa,$ff, $55,$ff, $aa,$ff
	db $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $ff,$80, $7f,$80, $ff,$80
	db $d5,$7f, $aa,$7f, $d5,$7f, $aa,$7f, $d5,$7f, $aa,$7f, $d5,$7f, $aa,$7f
	db $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e, $d5,$7e, $eb,$3c
	db $54,$ff, $aa,$ff, $54,$ff, $aa,$ff, $54,$ff, $aa,$ff, $54,$ff, $aa,$ff
	db $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $00,$ff
	db $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e, $d5,$7e, $2a,$ff
	db $ff,$01, $fe,$01, $ff,$01, $fe,$01, $ff,$01, $fe,$01, $ff,$01, $80,$ff
	db $7f,$80, $ff,$80, $7f,$80, $ff,$80, $7f,$80, $ff,$80, $7f,$80, $aa,$ff
	db $ff,$00, $ff,$00, $ff,$00, $ff,$00, $ff,$00, $ff,$00, $ff,$00, $2a,$ff
	db $ff,$01, $fe,$01, $ff,$01, $fe,$01, $fe,$01, $fe,$01, $fe,$01, $80,$ff
	db $7f,$80, $ff,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $7f,$80, $00,$ff
	db $fe,$01, $fe,$01, $fe,$01, $fe,$01, $fe,$01, $fe,$01, $fe,$01, $80,$ff
	db $3f,$c0, $3f,$c0, $3f,$c0, $1f,$e0, $1f,$e0, $0f,$f0, $03,$fc, $00,$ff
	db $fd,$03, $fc,$03, $fd,$03, $f8,$07, $f9,$07, $f0,$0f, $c1,$3f, $82,$ff
	db $55,$ff, $2a,$7e, $54,$7e, $2a,$7e, $54,$7e, $2a,$7e, $54,$7e, $00,$7e
	db $01,$ff, $00,$01, $01,$01, $00,$01, $01,$01, $00,$01, $01,$01, $00,$01
	db $54,$ff, $ae,$f8, $50,$f0, $a0,$e0, $60,$c0, $80,$c0, $40,$80, $40,$80
	db $55,$ff, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00
	db $55,$ff, $6a,$1f, $05,$0f, $02,$07, $05,$07, $02,$03, $03,$01, $02,$01
	db $54,$ff, $80,$80, $00,$80, $80,$80, $00,$80, $80,$80, $00,$80, $00,$80
	db $55,$ff, $2a,$1f, $0d,$07, $06,$03, $01,$03, $02,$01, $01,$01, $00,$01
	db $55,$ff, $2a,$7f, $55,$7f, $2a,$7f, $55,$7f, $2a,$7f, $55,$7f, $00,$7f
	db $55,$ff, $aa,$ff, $55,$ff, $aa,$ff, $55,$ff, $aa,$ff, $55,$ff, $00,$ff
	db $15,$ff, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00
	db $55,$ff, $6a,$1f, $0d,$07, $06,$03, $01,$03, $02,$01, $03,$01, $00,$01
	db $54,$ff, $a8,$ff, $54,$ff, $a8,$ff, $50,$ff, $a0,$ff, $40,$ff, $00,$ff
	db $00,$7e, $2a,$7e, $d5,$7e, $2a,$7e, $54,$7e, $ab,$76, $dd,$66, $22,$66
	db $00,$7c, $2a,$7e, $d5,$7e, $2a,$7e, $54,$7c, $ff,$00, $ff,$00, $00,$00
	db $00,$01, $00,$01, $ff,$01, $02,$01, $07,$01, $fe,$03, $fd,$07, $0a,$0f
	db $00,$7c, $2a,$7e, $d5,$7e, $2a,$7e, $54,$7e, $ab,$7e, $d5,$7e, $2a,$7e
	db $00,$ff, $a0,$ff, $50,$ff, $a8,$ff, $54,$ff, $a8,$ff, $54,$ff, $aa,$ff
	db $dd,$62, $bf,$42, $fd,$42, $bf,$40, $ff,$00, $ff,$00, $f7,$08, $ef,$18
	db $ff,$00, $ff,$00, $ff,$00, $ab,$7c, $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e
	db $f9,$07, $fc,$03, $fd,$03, $fe,$01, $ff,$01, $fe,$01, $ff,$01, $fe,$01
	db $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7e, $d5,$7e, $ab,$7c
	db $f7,$18, $eb,$1c, $d7,$3c, $eb,$3c, $d5,$3e, $ab,$7e, $d5,$7e, $2a,$ff
	db $ff,$01, $fe,$01, $ff,$01, $fe,$01, $ff,$01, $fe,$01, $ff,$01, $a2,$ff
	db $7f,$c0, $bf,$c0, $7f,$c0, $bf,$e0, $5f,$e0, $af,$f0, $57,$fc, $aa,$ff
	db $ff,$01, $fc,$03, $fd,$03, $fc,$03, $f9,$07, $f0,$0f, $c1,$3f, $82,$ff
	db $55,$ff, $2a,$ff, $55,$ff, $2a,$ff, $55,$ff, $2a,$ff, $55,$ff, $00,$ff
	db $45,$ff, $a2,$ff, $41,$ff, $82,$ff, $41,$ff, $80,$ff, $01,$ff, $00,$ff
	db $54,$ff, $aa,$ff, $54,$ff, $aa,$ff, $54,$ff, $aa,$ff, $54,$ff, $00,$ff
	db $15,$ff, $2a,$ff, $15,$ff, $0a,$ff, $15,$ff, $0a,$ff, $01,$ff, $00,$ff
	db $01,$ff, $80,$ff, $01,$ff, $80,$ff, $01,$ff, $80,$ff, $01,$ff, $00,$ff
TilesTitleEnd:

SECTION "Tilemap", ROM0

TilemapTitle:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $01, $02, $03, $01, $04, $03, $01, $05, $00, $01, $05, $00, $06, $04, $07, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $08, $09, $0a, $0b, $0c, $0d, $0b, $0e, $0f, $08, $0e, $0f, $10, $11, $12, $13, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $14, $15, $16, $17, $18, $19, $1a, $1b, $0f, $14, $1b, $0f, $14, $1c, $16, $1d, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $1e, $1f, $20, $21, $22, $23, $24, $22, $25, $1e, $22, $25, $26, $22, $27, $1d, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $01, $28, $29, $2a, $2b, $2c, $2d, $2b, $2e, $2d, $2f, $30, $2d, $31, $32, $33, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $08, $34, $0a, $0b, $11, $0a, $0b, $35, $36, $0b, $0e, $0f, $08, $37, $0a, $38, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $14, $39, $16, $17, $1c, $16, $17, $3a, $3b, $17, $1b, $0f, $14, $3c, $16, $1d, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $1e, $3d, $3e, $3f, $22, $27, $21, $1f, $20, $21, $22, $25, $1e, $22, $40, $1d, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $41, $42, $43, $44, $30, $33, $41, $45, $43, $41, $30, $43, $41, $30, $33, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
TilemapTitleEnd:

TilemapGame:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, 01, 02, 03, 04, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, 05, 06, 07, 08, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, 09, 10, 11, 12, 16, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, 13, 14, 15, 00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
TilemapGameEnd: