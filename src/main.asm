INCLUDE "hardware.inc"
INCLUDE "helpers.inc"
INCLUDE "utils.inc"
EXPORT PrintByte

SECTION "workram", WRAM0
facingDirection:: db
snakeLength :: dw
snakeLengthToGrow: db
; Keep a queue of body tile positions. 
; Positions are stored as X, Y coordinates. X in first byte, Y in second.
; The positions represent the tilemap position * 2, which allows for subtile precision
snakeBodyQueue:: ds 2880
snakeHead :: dw ; offset in snakeBodyQueue
snakeTail :: dw ; offset in snakeBodyQueue
rngSeed :: db
; Collectible/food location in subtile coordinates
def COLLECTIBLE_COUNT equ 3
collectibleList :: ds COLLECTIBLE_COUNT*2

; Current score represented as 4 digits (2 BCD bytes)
scoreBCD1 :: db
scoreBCD2 :: db
score: dw ; Score as binary

menuInitialized :: db

animationCounter :: db

; Interrupts

SECTION "VBlank Interrupt", ROM0[$0040]
VBlankInterrupt:
	push af
	push bc
	push de
	push hl
	jp VBlankHandler

SECTION "VBlank Handler", ROM0
VBlankHandler:
	pop hl
	pop de
	pop bc
	pop af
	reti

SECTION "Stat Interrupt", ROM0[$0048]
StatInterrupt:
	push af
	push hl
    push bc
	jp StatHandler

SECTION "Stat Handler", ROM0
StatHandler:
    jp .end ; Disable for now
    ; I don't have a ton of cycles to work with here
    ld a, [rLY]
    jr nc, .end

    ld hl, SinTable
    add a, l
    ld l, a
    ld a, [hl]

    ; Squash the sine by mapping the animation counter to the squash table
    ld b, a
    ld a, [animationCounter]
    ld hl, SquashTable
    add a, l
    ld l, a
    ld a, [hl]
    ld c, a
    ld a, b

.squash
    ld a, c
    cp 0
    jr z, .squashDone
    dec a
    ld c, a
    ld a, b
    sra a
    ld b, a
    jp .squash
.squashDone
    ld a, b
    ld [rSCX], a
.end
    pop bc
	pop hl
	pop af
	reti

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

LYC::
    push af
    push hl
    ldh a, [rLY]
    cp 128 - 1

    ld a, [rBGP]
    ld d, %11101101
    xor a, d
    ld [rBGP], a
    call PrintByteHex

    reti
    
EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

    ; Enable interrupts
    ld a, STATF_MODE00
    ldh [rSTAT], a

	ld a, IEF_STAT
	ldh [rIE], a
    xor a, a ; This is equivalent to `ld a, 0`!
	ldh [rIF], a
    ei

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a

    ld a, %11100100
    ld [rOBP0], a
    
    ld a, 0
    ld [rngSeed], a

    ld a, 0
    ld [menuInitialized], a
    
    ; Enable audio
    ld a, $80
    ld [rAUDENA], a
    ld a, $FF
    ld [rAUDTERM], a
    ld a, $77
    ld [rAUDVOL], a

    ; Start music
    ld hl, snake_song
    call hUGE_init

    ; Setup initial window scroll position
    ld a, $8F
    ld [rSCY], a

StartMenu:
    ld a, 8
    ld [ticks_per_row], a
    call WaitForVBlank

    mTurnOffLCD
    mCopyGPUData $9000, TilesTitle, TilesTitleEnd
    mCopyGPUData $9800, TilemapTitle, TilemapTitleEnd
    mCopyGPUData $8000, SpriteTilesGame, SpriteTilesGameEnd

    mTurnOnLCD

    ld a, 60
    call WaitForFrames

StartMenuLoop:
    ; Start game if any key is pressed

    ; Count the amount of main menu frames as RNG seed
    call DetectAnyInput
    cp a, 1
    jp z, StartGame

    call WaitForNextFrame
    call AnimateStartMenuSnake

    ld a, [rDIV]
    ld [rngSeed], a

    jp StartMenuLoop

AnimateStartMenuSnake:
    ld a, 2
    call WaitForFrames
    ; Increment frame counter
    ld a, [animationCounter]
    inc a
    ld [animationCounter], a
    ; Only animate snake if the menu is still being initialized
    ld a, [menuInitialized]
    cp 0
    jr nz, .end

    ; Move the window Y offset up
    ld a, [rSCY]
    add a, 1
    ld [rSCY], a
    cp a, 0
    jr nz, .end
    ; Animation done, rSCY is 0
    ld a, 1
    ld [menuInitialized], a
.end
    ret


StartGame:
    ; Cancel start menu animation
    ld a, 1
    ld [menuInitialized], a
    ld a, 0
    ld [rSCY], a

    ; Init tilemap graphics
    call WaitForVBlank

    mTurnOffLCD
    mCopyGPUData $9000, TilesGame, TilesNumberFontEnd
    mCopyGPUData $9800, TilemapGame, TilemapGameEnd

    ; Enable LCD and sprites
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; Init palette
    ld a, %01110010
    ld [rOBP0], a

    ; Initiate snake body
    ; snakeLength = 1
    ld a, 1
    ld [snakeLength], a
    ld a, 2
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
    ld a, 15
    ld [snakeBodyQueue], a
    ld [snakeBodyQueue+1], a

    ; Setup score BCD
    ld a, 3
    ld [scoreBCD1], a
    ld a, 0
    ld [scoreBCD2], a
    ld a, 0
    ld [score], a
    ld a, 3
    ld [score + 1], a

    ; Add initial collectibles
    ld d, COLLECTIBLE_COUNT
    ld hl, collectibleList + (COLLECTIBLE_COUNT-1)*2
.addCollectible
    dec d
    call CreateNewCollectible
    dec hl
    dec hl
    ld a, d
    cp a, 0
    jr nz, .addCollectible

    ld a, 0
    call GameLoop
    ret

GameLoop:
    call DetermineSnakeSpeed
    ;ld a, c
    ; ld [ticks_per_row], a
    ld a, b
    call WaitForFrames

    BREAKPOINT
    call MoveSnake
    call DrawScore

    ld a, 0
.next
    call UpdateInput
    jp GameLoop
    ret

; Return in reg a how many frames should be waited before every snake move
; Returns: b is frames per movement, c is music tempo
DetermineSnakeSpeed:
    ; if score > 256, jump to .greaterThan130
    ld a, [score]
    or a, a
    jr nz, .greaterThan130

    ; if score > 130, jump to .greaterThan130
    ld a, [score+1]
    cp 130
    jr nc, .greaterThan130
    
    ; if score > 70, jump to .greaterThan70
    ld a, [score+1]
    cp 70
    jr nc, .greaterThan70

    ; if score > 30, jump to .greaterThan30
    ld a, [score+1]
    cp 30
    jr nc, .greaterThan30

    ; if score > 20, jump to .greaterThan20
    ld a, [score+1]
    cp 20
    jr nc, .greaterThan20

    ; if score > 10, jump to .greaterThan10
    ld a, [score+1]
    cp 10
    jr nc, .greaterThan10

    ; if a > 0, fall through
.greaterThan0
    ld a, 8
    ld c, a
    ld a, 7
    jp .next
.greaterThan10
    ld a, 8
    ld c, a
    ld b, 6
    jp .next
.greaterThan20
    ld a, 7
    ld c, a
    ld a, 5
    jp .next
.greaterThan30
    ld a, 7
    ld c, a
    ld a, 4
    jp .next
.greaterThan70
    ld a, 7
    ld c, a
    ld a, 3
    jp .next
.greaterThan130
    ld a, 6
    ld c, a
    ld a, 2
    jp .next
.next
    ld b, a
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
    call GetTileLocation
    ; clear bit
    cpl 
    ld d, a
    ld a, [hl]
    and a, d
    ld [hl], a

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
    inc b
    ; Unflip sprite in X
    ld a, 0
    ld [$FE00+3], a
    ld e, 9 ; sprite x offset
    jr .moveXBoundsCheck
.moveLeft 
    dec b
    ; Flip sprite in X
    ld a, %00100000
    ld [$FE00+3], a
    ld e, 4 ; sprite x offset
.moveXBoundsCheck
    ld d, 14 ; sprite y offset
    ; Set tile id to horizontal snake head
    ld a, 0
    ld [$FE00+2], a
    ; Check that x is within 0 < x < 40
    ld a, b
    cp a, 40
    jp nc, GameOver
    jp .end
.moveUp
    dec c
    ; Flip sprite in X
    ld a, %01000000
    ld [$FE00+3], a
    ld d, 16 ; sprite y offset
    jr .moveYBoundsCheck
.moveDown
    inc c
    ; Unflip sprite in X6
    ld a, 0
    ld [$FE00+3], a
    ld d, 12 ; sprite y offset
.moveYBoundsCheck:
    ld e, 6; sprite x offset
    ; Set tile id to vertical snake head
    ld a, 1
    ld [$FE00+2], a
    ; Check that y is within 0 < y < 36
    ld a, c
    cp a, 36
    jp nc, GameOver
.end
    ; Update this tile location
    push hl
    push de
    ld hl, collectibleList
    
    ; Loop over every collectible
    ld d, COLLECTIBLE_COUNT
.collectibleCollisionsLoop
    ; Check if the new head position is on a collectible
    dec d
    ld a, [hli] ; 0 => 1
    cp a, b
    jr nz, .noCollectible
    ld a, [hl]
    cp a, c
    jr z, .collectible
.noCollectible
    inc hl ; 1 => 2
    ld a, d
    cp a, 0
    jr nz, .collectibleCollisionsLoop
    jp .loopEnd
.collectible
    ; The snake head is on a pickup
    ; Grow and generate a new one
    ld a, [snakeLengthToGrow]
    add a, 2
    ld [snakeLengthToGrow], a
    call IncrementScore
    call IncrementScore
    dec hl
    inc d
    ld a, COLLECTIBLE_COUNT
    sub a, d 
    ld d, a
    call CreateNewCollectible
.loopEnd
    pop de
    ; Update head sprite location
    
    call GetSpriteLocation
    
    ; mSetSpritePosition 0, l, h

    ld h, b
    ld l, c

    call GetTileLocation
    ; Make sure this spot is empty, otherwise game over!
    ld d, a
    ld a, [hl]
    and a, d
    cp a, 0
    jp nz, GameOver

    ; Set subtile to filled
    ld a, [hl]
    or a, d
.next
    ld [hl], a
    pop hl

    ; Get next spot in queue and set to new position
    inc hl
    ld a, b
    ld [hli], a
    ld a, c
    ld [hl], a

    ; Move the head one step forward in the queue
    ; will need to handle wraparound here later
    mIncAddressValue16 snakeHead
    ret

DrawScore:
    push af

    ; First digit
    ld a, [scoreBCD1]
    and a, %00001111
    add a, 17
    ld [$9A33-0], a
    ; Second digit
    ld a, [scoreBCD1]
    swap a
    and a, %00001111
    add a, 17
    ld [$9A33-1], a
    ; Third digit
    ld a, [scoreBCD2]
    and a, %00001111
    add a, 17
    ld [$9A33-2], a
    ; Fourth digit
    ld a, [scoreBCD2]
    swap a
    and a, %00001111
    add a, 17
    ld [$9A33-3], a

    pop af
    ret

IncrementScore:
    push af
    push hl
    push bc
    ; Increment score word
    ld a, [score]
    ld h, a
    ld a, [score + 1]
    ld l, a

    ld bc, 1
    add hl, bc

    ld a, h
    ld [score], a
    ld a, l
    ld [score+1], a

    ld a, [scoreBCD1]
    ; Increment first BCD byte
    add a, 1
    daa ; Use DAA to adjust after BCD add
    ; If we carried, increment the second byte
    jr c, .incrementSecondByte
    ld [scoreBCD1], a
    jp .next
.incrementSecondByte
    ; Increment second BCD byte
    ld [scoreBCD1], a
    ld a, [scoreBCD2]
    add a, 1
    ld [scoreBCD2], a
    daa ; Use DAA to adjust after BCD add
.next
    pop bc
    pop hl
    pop af
    ret

GameOver:
    ; Flash the snake by changing the palette
    ld a, [rBGP]
    ld b, a
    ld c, 10
    ld d, %11101101
.loop 
    ld a, d
    xor a, %00001101
    ld d, a
    ld [rBGP], a
    ld a, 10
    call WaitForFrames
    dec c
    ld a, c
    cp 0
    jr nz, .loop
.end
    ; Restore the palette
    ld a, b
    ld [rBGP], a
    jp StartMenu

; Calculate the tilemap location of a coordinate pair. 
; x in h, y in l. 
; result in hl, subtile in a. 
GetTileLocation:
    ; set carry flag to 0
    scf 
    ccf
    push bc
    push de
    ld d, h ; d = x
    ld e, l ; e = y
    ld a, l
    ; y << 4 = (y/2) * 32 = y * 16
    ld b, 0
    rra
    scf 
    ccf
    mLeftShiftCarry a, b, 5
    ld h, b
    ld l, a
    ld c, d
    sra c
    ld b, 0

    add hl, bc
    
    ; hl = 0x9800 + (y/2) * 32 + (x/2)
    ld b, $98
    ld c, 0
    add hl, bc

    ; Set register a to subtile position
    ; This is determined if y, x is even or odd
    bit 0, e 
    jr z, .yeven
    ; y odd
    bit 0, d 
    jr z, .yoddxeven
    ; y odd, x odd
    ld a, %00000001
    jr .returnTL
.yoddxeven
    ; y odd, x even
    ld a, %00000010
    jr .returnTL
.yeven
    ; y even
    bit 0, d 
    jr z, .yevenxeven
    ; y even, x odd
    ld a, %00000100
    jr .returnTL
.yevenxeven
    ld a, d
    ; y even, x even
    ld a, %00001000
.returnTL
    pop de
    pop bc
    ret

; Calculate the sprite location of a snake body coordinate
; x in h, y in l. e is extra x offset, extra d is y offset
; Result in hl
GetSpriteLocation:
    push af
    ; x
    ld a, 0
    add a, h
    add a, a ; * 2
    add a, a ; * 2
    add a, e
    ld h, a
    ; y
    ld a, 0
    add a, l
    add a, a ; * 2
    add a, a ; * 2
    add a, d
    ld l, a
    pop af
    ret

; Set a sprite position and tile texture
; sprite id in a, sprite x in h, sprite y in l
SetSprite:
    push hl
    sla a
    sla a
    ld hl, $FE00
    add a, l
    ld l, a
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, b
    ld [hli], a
    pop hl
    ret

; Generate a new collectible position
; hl is address in collectible list, d is sprite index
; destroys: a
CreateNewCollectible:
    ; juggle registers
    push af
    push bc
    ld a, h
    ld b, a
    ld a, l
    push hl
    ld l, a
    ld a, b
    ld h, a
    ld a, d
    inc a
    ld b, a
    push de
    inc hl
    inc hl
.generateCollectiblePosition
    dec hl
    dec hl
    ; X
    call GenerateRNG
    ld a, [rngSeed]   
    ; Throw away lowest 2 bits
    sra a
    sra a
    mModulo a, 38
    inc a
    ld [hli], a
    ld e, a

    ; Y
    call GenerateRNG
    ld a, [rngSeed]   
    ; Throw away lowest 2 bits
    sra a
    sra a
    mModulo a, 34
    inc a
    ld [hli], a ; hli causes issues here, what happens if we fail? Then hl keeps increasing, bad
    ld d, a

    ; Double check that the collectible is not ontop another filled in tile
    push hl
    ld h, e
    ld l, d
    call GetTileLocation
    ld a, [hl]
    cp 0
    pop hl
    ; If so, generate a new one
    jr nz, .generateCollectiblePosition
    ld h, e
    ld l, d

    ; Randomize sprite
    ld d, b
    push bc
    ld c, d
    call GenerateRNG
    ld a, [rngSeed]  
    and a, %00010000
    swap a
    add a, 2
    ld b, a

    ld e, 6
    ld d, 14
    call GetSpriteLocation
    ld a, c
    ld e, l
    ld d, h
    call SetSprite
    pop bc

    pop de
    pop hl
    pop bc
    pop af
    ret

; Update the input 'facingDirection' variable. 
; 0 = right, 1 = left, 2 = up, 3 = down. 
; All registers are restored. 
UpdateInput:
    push af
    push bc
    ; Get arrow input
    ld a, 0
    set 5, a
	ld [$FF00], a
    ; Stabilize input
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    ld b, a

    ; Store current direction in c
    ld a, [facingDirection]
    ld c, a

    ; Only allow right press if left is not active
    ld a, c
    cp a, 1
    jr z, .left 
    ; Check right arrow
    bit 0, b
    ld a, 0
    ld [facingDirection], a
    jr z, .return
.left
    ; Only allow left press if right is not active
    ld a, c
    cp a, 0
    jr z, .up 
    ; Check left arrow
    bit 1, b
    ld a, 1
    ld [facingDirection], a
    jr z, .return
.up
    ; Only allow up press if down is not active
    ld a, c
    cp a, 3
    jr z, .down 
    ; Check up arrow
    bit 2, b
    ld a, 2
    ld [facingDirection], a
    jr z, .return
.down
    ; Only allow down press if up is not active
    ld a, c
    cp a, 2
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
    push bc
    push de
    push hl
    call hUGE_dosound
.loop
    ld   a, [rLY]
    cp   144
    jp   nz, .loop
.loop2
    ld   a, [rLY]
    cp   145
    jp   nz, .loop2
    pop hl
    pop de
    pop bc
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
    ; Stabilize input
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    and a, $0F
    cp a, $0F
    ; If any bit is unset in right nibble, return 1
    ld a, 1
    ret nz
    
    ld a, 0
    set 4, a
	ld [$FF00], a
    ; Stabilize input
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    and a, $0F
    cp a, $0F
    ; If any bit is unset in right nibble, return 1
    ld a, 1
    ret nz

    ; Else, return 0. No input
    ld a, 0
    ret
    
; Simple LCG RNG. Period is 256, so update seed frequently.
; Restores all registers. Output in [rngSeed]
GenerateRNG:
    push af
    push bc
    ld a, [rngSeed]   
    ld b, a            
    add a, a          
    add a, a   
    add a, b       
    inc a 
    ld [rngSeed], a
    pop bc
    pop af
    ret
    
SECTION "Tile data", ROM0

INCLUDE "data.inc"