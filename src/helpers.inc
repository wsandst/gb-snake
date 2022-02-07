
SECTION "Helpers", ROM0

Memcpy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcpy
	ret

; Print value in a as hexadecimal
PrintByte:
	ld c, a
	; Print first 4 bits
	srl a
	srl a
	srl a
	srl a
	call _Print4Bit
	ld a, c
	; Print last 4 bits
	and a, %00001111
	call _Print4Bit
	ld a, c
	ret
_Print4Bit:
	cp a, 10
	ld b, 55
	jr nc, .next
	ld b, 48
.next
	add a, b
	; Send character over link
	ld [rSB], a
	ld a, $81
	ld [rSC], a
	ret