; Macros

; Custom breakpoints for the emulator. Treats ld b, b as breakpoints.
MACRO BREAKPOINT
	ld b, b
ENDM

; Increment the 16-bit value of an address by 2
incAddressValue16: MACRO
    ld a, [\1]
    ld h, a
    ld a, [\1 + 1]
    ld l, a
    inc hl
    inc hl
    ld a, h
    ld [\1], a
    ld a, l
    ld [\1+1], a
ENDM

copyTileData: MACRO
    ; Turn off LCD
    ld a, 0
	ld [rLCDC], a

    ; Copy the tile data
    ld de, \1
	ld hl, $9000
	ld bc, \2 - \1
	call Memcpy

	; Copy the tilemap
	ld de, \3
	ld hl, $9800
	ld bc, \4 - \3
	call Memcpy

    ; Turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a
ENDM