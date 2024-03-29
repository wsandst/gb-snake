; Macros

; Custom breakpoints for the emulator. Treats ld b, b as breakpoints.
MACRO BREAKPOINT
	ld b, b
ENDM

; Increment the 16-bit value of an address by 2
MACRO mIncAddressValue16
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

MACRO mCopyGPUData
    ; Copy the data
    ld de, \2
	ld hl, \1
	ld bc, \3 - \2
	call Memcpy
ENDM

MACRO mTurnOffLCD
    ; Turn off LCD
    ld a, 0
    ld [rLCDC], a
ENDM

MACRO mTurnOnLCD
    ; Turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a
ENDM

; Right-shifts register N times
MACRO mRightShift
    REPT \2
        sra \1
    ENDR
ENDM

; Left-shifts register N times
MACRO mLeftShift
    REPT \2
        sla \1
    ENDR
ENDM

; Left shifts register N times, and moves carry into secondary register
MACRO mLeftShiftCarry
    REPT \3
        rl \1
        rl \2
    ENDR
ENDM

MACRO mSetSpritePosition
    ld a, \2
    ld [$FE00 + \1*4 + 0], a
    ld a, \3
    ld [$FE00 + \1*4 + 1], a
ENDM

MACRO mGetSpritePosition
    ld a, \2
    ld [$FE00 + \1*4 + 0], a
    ld a, \3
    ld [$FE00 + \1*4 + 1], a
ENDM

; Take modulo of register. Slow
; Result in a. Do not use de as arguments
MACRO mModulo
    push de
    ld e, \1
    ld d, 0
.loop\@
    inc d
    dec e

    ; \1 > 0
    ; val < MODULO
    ld a, d
    cp a, \2
    jp nz, .next\@
    ld d, 0
.next\@
    ld a, e
    cp a, 0
    jp nz, .loop\@
    ld a, d
    pop de
ENDM


MACRO mPrintRegHex
    push af
    ld a, \1
    call PrintByteHexNoNewline
    ld a, \2
    call PrintByteHex
    pop af
ENDM