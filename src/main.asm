INCLUDE "hardware.inc"
INCLUDE "helpers.inc"
INCLUDE "utils.inc"
EXPORT PrintByte

SECTION "workram", WRAM0
facingDirection:: db
snakeLength :: dw
snakeLengthToGrow: db
; Keep a queue of body tile positions. 
; Positions are relative to TilemapGame. First 12 bits are the index, the last 4 bits are which subtile pos
snakeBodyQueue:: ds 2880
snakeHead :: dw ; offset in snakeBodyQueue
snakeTail :: dw ; offset in snakeBodyQueue
rngSeed :: db

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

    
EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

StartMenu:
    call WaitForVBlank
    mCopyTileData TilesTitle, TilesTitleEnd, TilemapTitle, TilemapTitleEnd

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
    
    ld a, 0
    ld [rngSeed], a

    ld h, 28
    ld l, 20
    call GetTileLocation
    call PrintByteBits

    ld a, 60
    call WaitForFrames

StartMenuLoop:
    ; Start game if any key is pressed

    ; Count the amount of main menu frames as RNG seed
    ld a, [rngSeed]
    inc a
    ld [rngSeed], a

    call DetectAnyInput
    cp a, 1
    jp z, StartGame

    call WaitForVBlank
    jp StartMenuLoop


StartGame:
    ld a, [rngSeed]
    call PrintByteHex
    ; Init tilemap graphics
    call WaitForVBlank
    mCopyTileData TilesGame, TilesGameEnd, TilemapGame, TilemapGameEnd

    ; Initiate snake body
    ; snakeLength = 1
    ld a, 1
    ld [snakeLength], a
    ld a, 7
    ; snakeLengthToGrow = 3
    ld [snakeLengthToGrow], a
    
    ld a, 0
    ld [facingDirection], a

    ; snakeHead = 0
    ld a, 0
    ld [snakeHead], a
    ld [snakeHead+1], a
    ; snakeTail = 0
    ld [snakeTail], a
    ld [snakeTail+1], a

    ; Set the first snake body element to be at the middle of the screen
    ld bc, $9800
    ld a, b
    ld [snakeBodyQueue], a
    ld a, c
    ld [snakeBodyQueue+1], a

    ld a, 0
    call GameLoop
    ret

GameLoop:
    ld a, 10
    call WaitForFrames

    BREAKPOINT
    call MoveSnake
    ld a, 0
.next
    call UpdateInput
    jp GameLoop
    ret


MoveSnake:
MoveSnakeTail:
    ; Only move tail if we are not growing
    ld a, [snakeLengthToGrow]
    cp a, 0
    jr z, .next
    dec a
    ld [snakeLengthToGrow], a
    jp MoveSnakeHead
.next
    ; Move tail
    ; hl = [snakeTail]
    ld a, [snakeTail]
    ld h, a
    ld a, [snakeTail + 1]
    ld l, a

    ld bc, snakeBodyQueue
    add hl, bc

    ; bc = [hl] (get the value pointed to in the queue)
    ld b, [hl]
    inc hl
    ld c, [hl]

    ; Clear this spot
    push hl
    ld h, b
    ld l, c
    ld [hl], 0
    pop hl

    ; Increment tail position
    mIncAddressValue16 snakeTail

MoveSnakeHead:
    ; Move head
    ; bc = current head position in tilemap coordinates
    ; hl = [snakeHead]
    ld a, [snakeHead]
    ld h, a
    ld a, [snakeHead + 1]
    ld l, a

    ld bc, snakeBodyQueue
    add hl, bc

    ; bc = [hl] (get the value pointed to in the queue)
    ld b, [hl]
    inc hl
    ld c, [hl]

    ; Move to the right
    ld a, [facingDirection]
    cp a, 0
    jr z, .moveRight
    cp a, 1
    jr z, .moveLeft
    cp a, 2
    jr z, .moveUp
    cp a, 3
    jr z, .moveDown
    jp .end
.moveRight
    inc bc
    jr .moveXBoundsCheck
.moveLeft 
    dec bc
.moveXBoundsCheck
    ; Isolate x coordinate
    ld a, c
    and a, %0011111
    ; Check that it is within 0 < x < 20
    cp a, 20
    jp nc, GameOver
    jp .end
.moveUp
    ld a, c
    sub a, 32
    ld c, a
    ld a, b
    sbc a, 0
    ld b, a
    jr .moveYBoundsCheck
.moveDown
    ld a, c
    add a, 32
    ld c, a
    ld a, b
    adc a, 0
    ld b, a
.moveYBoundsCheck:
    ; hl > 0x9800 (y > 0)
    ld a, b
    cp $98
    jp c, GameOver
    ; hl < 0x9A34 (y < 18)
    cp $9A
    jp c, .end
    cp $98
    jp c, GameOver
    ld a, c
    cp $34
    jp c, .end
    jp GameOver
.end
    ; Update this tile location
    push hl
    ld h, b
    ld l, c

    ; Make sure this spot is empty, otherwise game over!
    ld a, [hl]
    cp a, 0
    jp nz, GameOver

.next
    ld [hl], 15
    pop hl

    ; Get next spot in queue and set to new tile location (need to handle wraparound later)
    inc hl
    ld a, b
    ld [hli], a
    ld a, c
    ld [hl], a

    ; Move the head one step forward in the queue
    ; will need to handle wraparound here later
    mIncAddressValue16 snakeHead
    ret

GameOver:
    ; Display score,
    jp StartMenu

; Calculate the tilemap location of a coordinate pair
; x in h, y in l
; result in hl, subtile in a
GetTileLocation:
    push bc
    ld d, h ; d = x
    ld e, l ; e = y
    ld a, l
    ; y << 4 = (y/2) * 32 = y * 16
    ld b, 0
    mLeftShiftCarry a, b, 4
    ld h, b
    ld l, a
    ld c, d
    sra c
    ld b, 0
    add hl, bc
    ; hl = y * 32 + x
    ld b, $98
    ld c, 0
    add hl, bc

    ld a, h
    call PrintByteHex
    ld a, l
    call PrintByteHex
    pop bc

    ; Set register a to subtile position
    ; This is determined if y, x is even or odd
    bit 0, e 
    jr z, .yeven
    ; y odd
    bit 0, d 
    jr z, .yoddxeven
    ; y odd, x odd
    ld a, %00000001
    ret
.yoddxeven
    ; y odd, x even
    ld a, %00000010
    ret
.yeven
    ; y even
    bit 0, d 
    jr z, .yevenxeven
    ; y even, x odd
    ld a, %00000100
    ret
.yevenxeven
    ld a, d
    ; y even, x even
    ld a, %00001000
    ret

; Update the input 'facingDirection' variable
; 0 = right, 1 = left, 2 = up, 3 = down
; All registers are restored
UpdateInput:
    push af
    push bc
    ; Get arrow input
    ld a, 0
    set 5, a
	ld [$FF00], a
    ld a, [$FF00]
    ld b, a

    ; Store current direction in c
    ld a, [facingDirection]
    ld c, a

    ; Check right arrow
    bit 0, b
    ld a, 0
    ld [facingDirection], a
    jr z, .return

    ; Check left arrow
    bit 1, b
    ld a, 1
    ld [facingDirection], a
    jr z, .return

    ; Check up arrow
    bit 2, b
    ld a, 2
    ld [facingDirection], a
    jr z, .return

    ; Check down arrow
    bit 3, b
    ld a, 3
    ld [facingDirection], a
    jr z, .return

    ; Keep using current direction if no button is pressed
    ld a, c
    ld [facingDirection], a
.return
    pop af
    pop bc
    ret

; Wait until in VBlank. Will return directly if already in VBlank
WaitForVBlank:
    push af
.loop
    ld   a, [rLY]
    cp   144
    jp   c, .loop
    pop af
    ret

; Wait for the next frame (in VBlank)
WaitForNextFrame:
    push af
.loop
    ld   a, [rLY]
    cp   144
    jp   nz, .loop
.loop2
    ld   a, [rLY]
    cp   145
    jp   nz, .loop2

    pop af
    ret

; Wait for a certain amount of frames, specified by register A
WaitForFrames:
    dec a
    call WaitForNextFrame
    cp a, 0
    jr nz, WaitForFrames
    ret

; Returns whether any input key is pressed in register a
; a = 1 (input pressed), a = 0 (no input)
DetectAnyInput:
    ; Check arrow keys
    ld a, 0
    set 5, a
	ld [$FF00], a
    ld a, [$FF00]
    cp a, $0F
    ; If any bit is unset in right nibble, return 1
    ld a, 1
    ret nz
    
    ld a, 0
    set 4, a
	ld [$FF00], a
    ld a, [$FF00]
    cp a, $0F
    ; If any bit is unset in right nibble, return 1
    ld a, 1
    ret nz

    ; Else, return 0. No input
    ld a, 0
    ret

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
    ;mainmenu.png-0x0.png, 0:
    db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-10x10.png, 1:
    db $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-10x13.png, 2:
    db $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$00, 
    ;mainmenu.png-10x16.png, 3:
    db $ff,$ff, $ff,$ff, $ff,$ff, $ff,$00, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-10x1.png, 4:
    db $00,$ff, $00,$ff, $00,$ff, $ff,$ff, $06,$06, $06,$06, $e6,$e6, $e6,$e6, 
    ;mainmenu.png-10x2.png, 5:
    db $06,$06, $06,$06, $e6,$e6, $e6,$e6, $e6,$e6, $e6,$e6, $e6,$e6, $ff,$ff, 
    ;mainmenu.png-10x4.png, 6:
    db $fe,$01, $ff,$fc, $ff,$fe, $ff,$fe, $ff,$fe, $ff,$fe, $ff,$fe, $ff,$fe, 
    ;mainmenu.png-10x5.png, 7:
    db $ff,$fe, $ff,$ee, $ff,$e6, $ff,$c6, $ff,$c6, $ff,$c6, $ff,$e5, $ff,$ed, 
    ;mainmenu.png-10x6.png, 8:
    db $ff,$fb, $ff,$fb, $ff,$fb, $ff,$f7, $ff,$f7, $ff,$ef, $ff,$df, $ff,$bf, 
    ;mainmenu.png-10x7.png, 9:
    db $ff,$7f, $ff,$7f, $ff,$7f, $ff,$7f, $ff,$7f, $ff,$bf, $ff,$df, $ff,$df, 
    ;mainmenu.png-10x8.png, 10:
    db $ff,$df, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-11x10.png, 11:
    db $e0,$df, $e0,$df, $e0,$df, $e0,$df, $e0,$df, $e0,$df, $e0,$df, $e0,$df, 
    ;mainmenu.png-11x11.png, 12:
    db $e0,$df, $f0,$ef, $f0,$ef, $f8,$f7, $fc,$fb, $ff,$fc, $ff,$fe, $ff,$fe, 
    ;mainmenu.png-11x14.png, 13:
    db $ff,$fe, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-11x16.png, 14:
    db $ff,$ff, $ff,$ff, $ff,$fe, $fe,$01, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-11x1.png, 15:
    db $00,$ff, $00,$ff, $00,$ff, $ff,$ff, $7c,$7c, $78,$78, $71,$71, $63,$63, 
    ;mainmenu.png-11x2.png, 16:
    db $47,$47, $0f,$0f, $07,$07, $23,$63, $71,$71, $78,$78, $7c,$7c, $ff,$ff, 
    ;mainmenu.png-11x4.png, 17:
    db $00,$ff, $80,$7f, $c0,$bf, $e0,$df, $f0,$ef, $f8,$f7, $fc,$fb, $fe,$fd, 
    ;mainmenu.png-11x5.png, 18:
    db $fe,$fd, $ff,$fe, $ff,$fe, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-11x6.png, 19:
    db $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$fc, 
    ;mainmenu.png-11x7.png, 20:
    db $fc,$fb, $f8,$f7, $f0,$ef, $e0,$df, $e0,$df, $c0,$bf, $c0,$bf, $c0,$bf, 
    ;mainmenu.png-11x8.png, 21:
    db $c0,$bf, $c0,$bf, $c0,$bf, $80,$7f, $80,$7f, $80,$7f, $80,$7f, $80,$7f, 
    ;mainmenu.png-11x9.png, 22:
    db $c0,$bf, $c0,$bf, $c0,$bf, $c0,$bf, $c0,$bf, $c0,$bf, $c0,$bf, $e0,$df, 
    ;mainmenu.png-12x11.png, 23:
    db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $ff,$00, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-12x12.png, 24:
    db $ff,$7f, $ff,$7f, $ff,$bf, $ff,$bf, $ff,$df, $ff,$df, $ff,$df, $ff,$df, 
    ;mainmenu.png-12x13.png, 25:
    db $ff,$df, $ff,$df, $ff,$bf, $ff,$bf, $ff,$bf, $ff,$7f, $ff,$7f, $ff,$7f, 
    ;mainmenu.png-12x14.png, 26:
    db $ff,$00, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-12x16.png, 27:
    db $ff,$ff, $ff,$ff, $ff,$00, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-12x1.png, 28:
    db $00,$ff, $00,$ff, $00,$ff, $ff,$ff, $60,$60, $60,$60, $e7,$e7, $e7,$e7, 
    ;mainmenu.png-12x2.png, 29:
    db $e0,$e0, $e0,$e0, $e7,$e7, $e7,$e7, $e7,$e7, $60,$60, $60,$60, $ff,$ff, 
    ;mainmenu.png-12x5.png, 30:
    db $00,$ff, $00,$ff, $00,$ff, $80,$7f, $80,$7f, $80,$7f, $c0,$bf, $c0,$bf, 
    ;mainmenu.png-12x6.png, 31:
    db $c0,$bf, $c0,$bf, $c0,$bf, $c0,$bf, $c0,$bf, $c0,$bf, $80,$7f, $00,$ff, 
    ;mainmenu.png-13x11.png, 32:
    db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $c0,$3f, $fc,$c3, $ff,$fc, 
    ;mainmenu.png-13x1.png, 33:
    db $00,$ff, $00,$ff, $00,$ff, $fe,$ff, $06,$07, $06,$07, $fe,$ff, $fe,$ff, 
    ;mainmenu.png-13x2.png, 34:
    db $7e,$7f, $7e,$7f, $fe,$ff, $fe,$ff, $fe,$ff, $06,$07, $06,$07, $fe,$ff, 
    ;mainmenu.png-14x12.png, 35:
    db $80,$7f, $c0,$bf, $e0,$df, $f0,$ef, $f0,$ef, $f0,$ef, $f8,$f7, $f8,$f7, 
    ;mainmenu.png-14x13.png, 36:
    db $f8,$f7, $f8,$f7, $f8,$f7, $f0,$ef, $f0,$ef, $f0,$ef, $e0,$df, $e0,$df, 
    ;mainmenu.png-14x14.png, 37:
    db $e0,$1f, $ff,$e0, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-14x16.png, 38:
    db $ff,$ff, $ff,$f0, $f0,$0f, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-15x14.png, 39:
    db $00,$ff, $e0,$1f, $f0,$ef, $f8,$f7, $fc,$fb, $fc,$fb, $fe,$fd, $fe,$fd, 
    ;mainmenu.png-15x15.png, 40:
    db $fe,$fd, $fe,$fd, $fe,$fd, $fe,$fd, $fe,$fd, $fc,$fb, $fc,$fb, $f8,$f7, 
    ;mainmenu.png-15x16.png, 41:
    db $f0,$ef, $e0,$1f, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-4x14.png, 42:
    db $00,$ff, $07,$f8, $0f,$f7, $1f,$ef, $3f,$df, $3f,$df, $7f,$bf, $7f,$bf, 
    ;mainmenu.png-4x15.png, 43:
    db $7f,$bf, $7f,$bf, $7f,$bf, $7f,$bf, $7f,$bf, $3f,$df, $3f,$df, $1f,$ef, 
    ;mainmenu.png-4x16.png, 44:
    db $0f,$f7, $07,$f8, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-5x12.png, 45:
    db $01,$fe, $03,$fd, $07,$fb, $0f,$f7, $0f,$f7, $0f,$f7, $1f,$ef, $1f,$ef, 
    ;mainmenu.png-5x13.png, 46:
    db $1f,$ef, $1f,$ef, $1f,$ef, $0f,$f7, $0f,$f7, $0f,$f7, $07,$fb, $07,$fb, 
    ;mainmenu.png-5x14.png, 47:
    db $07,$f8, $ff,$07, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-5x16.png, 48:
    db $ff,$ff, $ff,$0f, $0f,$f0, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-6x11.png, 49:
    db $00,$ff, $00,$ff, $00,$ff, $00,$ff, $00,$ff, $03,$fc, $3f,$c3, $ff,$3f, 
    ;mainmenu.png-6x1.png, 50:
    db $00,$ff, $00,$ff, $00,$ff, $7f,$ff, $60,$e0, $60,$e0, $67,$e7, $67,$e7, 
    ;mainmenu.png-6x2.png, 51:
    db $60,$e0, $60,$e0, $7f,$ff, $7f,$ff, $7f,$ff, $60,$e0, $60,$e0, $7f,$ff, 
    ;mainmenu.png-7x1.png, 52:
    db $00,$ff, $00,$ff, $00,$ff, $ff,$ff, $06,$06, $06,$06, $fe,$fe, $fe,$fe, 
    ;mainmenu.png-7x2.png, 53:
    db $06,$06, $06,$06, $e6,$e6, $e6,$e6, $e6,$e6, $06,$06, $06,$06, $ff,$ff, 
    ;mainmenu.png-7x5.png, 54:
    db $00,$ff, $00,$ff, $00,$ff, $01,$fe, $01,$fe, $01,$fe, $03,$fd, $03,$fd, 
    ;mainmenu.png-7x6.png, 55:
    db $03,$fd, $03,$fd, $03,$fd, $03,$fd, $03,$fd, $03,$fd, $01,$fe, $00,$ff, 
    ;mainmenu.png-8x10.png, 56:
    db $07,$fb, $07,$fb, $07,$fb, $07,$fb, $07,$fb, $07,$fb, $07,$fb, $07,$fb, 
    ;mainmenu.png-8x11.png, 57:
    db $07,$fb, $0f,$f7, $0f,$f7, $1f,$ef, $3f,$df, $ff,$3f, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-8x13.png, 58:
    db $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$80, 
    ;mainmenu.png-8x14.png, 59:
    db $ff,$7f, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-8x16.png, 60:
    db $ff,$ff, $ff,$ff, $ff,$7f, $7f,$80, $00,$ff, $00,$ff, $00,$ff, $00,$ff, 
    ;mainmenu.png-8x1.png, 61:
    db $00,$ff, $00,$ff, $00,$ff, $ff,$ff, $1e,$1e, $1e,$1e, $4e,$4e, $4e,$4e, 
    ;mainmenu.png-8x2.png, 62:
    db $66,$66, $66,$66, $66,$66, $72,$72, $72,$72, $78,$78, $78,$78, $ff,$ff, 
    ;mainmenu.png-8x4.png, 63:
    db $00,$ff, $01,$fe, $03,$fd, $07,$fb, $0f,$f7, $1f,$ef, $3f,$df, $7f,$bf, 
    ;mainmenu.png-8x5.png, 64:
    db $7f,$bf, $ff,$7f, $ff,$7f, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, 
    ;mainmenu.png-8x6.png, 65:
    db $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$3f, 
    ;mainmenu.png-8x7.png, 66:
    db $3f,$df, $1f,$ef, $0f,$f7, $07,$fb, $07,$fb, $03,$fd, $03,$fd, $03,$fd, 
    ;mainmenu.png-8x8.png, 67:
    db $03,$fd, $03,$fd, $03,$fd, $01,$fe, $01,$fe, $01,$fe, $01,$fe, $01,$fe, 
    ;mainmenu.png-8x9.png, 68:
    db $03,$fd, $03,$fd, $03,$fd, $03,$fd, $03,$fd, $03,$fd, $03,$fd, $07,$fb, 
    ;mainmenu.png-9x1.png, 69:
    db $00,$ff, $00,$ff, $00,$ff, $ff,$ff, $60,$60, $60,$60, $67,$67, $67,$67, 
    ;mainmenu.png-9x2.png, 70:
    db $60,$60, $60,$60, $67,$67, $67,$67, $67,$67, $67,$67, $67,$67, $ff,$ff, 
    ;mainmenu.png-9x4.png, 71:
    db $7f,$80, $ff,$3f, $ff,$7f, $ff,$7f, $ff,$7f, $ff,$7f, $ff,$7f, $ff,$7f, 
    ;mainmenu.png-9x5.png, 72:
    db $ff,$7f, $ff,$77, $ff,$67, $ff,$63, $ff,$63, $ff,$63, $ff,$a7, $ff,$b7, 
    ;mainmenu.png-9x6.png, 73:
    db $ff,$df, $ff,$df, $ff,$df, $ff,$ef, $ff,$ef, $ff,$f7, $ff,$fb, $ff,$fd, 
    ;mainmenu.png-9x7.png, 74:
    db $ff,$fe, $ff,$fe, $ff,$fe, $ff,$fe, $ff,$fe, $ff,$fd, $ff,$fb, $ff,$fb, 
    ;mainmenu.png-9x8.png, 75:
    db $ff,$fb, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff, $ff,$ff,
TilesTitleEnd:

SECTION "Tilemap", ROM0
TilemapTitle:
	;    1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20  
    db   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,  50,  52,  61,  69,   4,  15,  28,  33,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,  51,  53,  62,  70,   5,  16,  29,  34,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,   0,  63,  71,   6,  17,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,  54,  64,  72,   7,  18,  30,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,  55,  65,  73,   8,  19,  31,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,   0,  66,  74,   9,  20,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,   0,  67,  75,  10,  21,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,   0,  68,   1,   1,  22,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,   0,  56,   1,   1,  11,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,  49,  23,  57,   1,   1,  12,  23,  32,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,  45,   1,   1,   1,   1,   1,   1,  24,   1,  35,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,  46,   1,   1,  58,   2,   2,   2,  25,   1,  36,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,  42,  47,  26,  26,  59,   1,   1,  13,  26,  26,  37,  39,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,  43,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,  40,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,  44,  48,  27,  27,  60,   3,   3,  14,  27,  27,  38,  41,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0
    db   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,0,0,0,0,0,0,0,0,0,0,0

TilemapTitleEnd:

TilemapGame:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
TilemapGameEnd: