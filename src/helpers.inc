
SECTION "Helpers", ROM0

; Copy the memory in address de to address hl, with length bc
Memcpy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, Memcpy
	ret


; Print value in reg A as hexadecimal over link
; All registers are restored
PrintByteHex:
	; Save registers
	push bc
	ld c, a
	push af
	push de
	ld a, c

	; Print first 4 bits
	srl a
	srl a
	srl a
	srl a
	call .print4Bit
	ld a, c

	; Print last 4 bits
	and a, %00001111
	call .print4Bit

	; Print newline
	ld a, 10
	call PrintByteChar
	pop de
	pop af
	pop bc
	ret
.print4Bit:
	cp 10
	; Use number if number <10, otherwise letter (for hex)
	ld b, 55
	jr nc, .next
	ld b, 48
.next
	add a, b
	call PrintByteChar
	ret


; Print byte in reg A as ASCII char over link
PrintByteChar:
	; Print char over link
	ld [rSB], a
	ld a, $81
	ld [rSC], a
	ret

; Print byte in reg A as bits over link
; All registers are restored
PrintByteBits:
	; Save registers
	push bc
	ld b, a
	push af
	push de

	ld c, 8
.loop
	ld a, b
	and a, %10000000
	srl a
	srl a
	srl a
	srl a
	srl a
	srl a
	srl a
	ld d, 48
	add d
	call PrintByteChar
	dec c
	sla b
	ld a, c
	cp 0
	jr nz, .loop

	; Print newline
	ld a, 10
	call PrintByteChar

	; Restore registers
	pop de
	pop af
	pop bc
	ret

; Print between the memory addresses hl and de
PrintMem:
	ld a, [hli]
	call PrintByteHex
	ld a, [hli]
	call PrintByteHex

	ld a, h
	cp a, d
	jr nz, PrintMem
	ld a, l
	cp a, e
	jr nz, PrintMem
	ret


; Print value in reg A as hexadecimal over link
; All registers are restored
PrintByteHexNoNewline:
	; Save registers
	push bc
	ld c, a
	push af
	push de
	ld a, c

	; Print first 4 bits
	srl a
	srl a
	srl a
	srl a
	call .print4Bit
	ld a, c

	; Print last 4 bits
	and a, %00001111
	call .print4Bit
	pop de
	pop af
	pop bc
	ret
.print4Bit:
	cp 10
	; Use number if number <10, otherwise letter (for hex)
	ld b, 55
	jr nc, .next
	ld b, 48
.next
	add a, b
	call PrintByteChar
	ret