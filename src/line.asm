; line.asm

INCLUDE "hardware.inc"

/*
	\1 = start
	\2 = end
	\3 = delta
	\4 = increment
*/
MACRO get_delta
	ld a, \2
	sub a, \1
	ld \3, a

	ld a, 1
	ld [\4], a

	jr nc, .isPositive\@

	ld a, \3
	cpl
	inc a
	ld \3, a

	ld a, 255
	ld [\4], a

.isPositive\@
ENDM

/*
	\1 = position
	\2 = end
	\3 = second
	\4 = delta one
	\5 = delta two
	\6 = error
	\7 = increment one
	\8 = increment two
*/
MACRO draw_line
	ld a, \5
	srl \4
	sub a, \4
	ld \6, a

.loopPosition\@
	call DrawPixel

	bit 7, \6
	jr nz, .isNegative\@

	ld a, \6
	sub a, \4
	sub a, \4
	ld \6, a

	ld a, [\8]
	add a, \3
	ld \3, a

.isNegative\@
	ld a, \6
	add a, \5
	ld \6, a

	ld a, [\7]
	add a, \1
	ld \1, a

	cp a, \2
	jr nz, .loopPosition\@

	call DrawPixel
	ret
ENDM

MACRO wait_stat
.waitStat\@
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .waitStat\@
ENDM

SECTION "Line Drawing Functions", ROM0

DrawLine::
	get_delta b, d, h, wIncX
	get_delta c, e, l, wIncY

	ld a, h
	cp a, l
	jr c, .dyLonger

	draw_line b, d, c, h, l, e, wIncX, wIncY

.dyLonger
	draw_line c, e, b, l, h, d, wIncY, wIncX

DrawPixel::
	push hl

	ld a, b
	and a, 7
	ld l, a
	ld h, HIGH(LineMaskLut)
	ld a, [hl]
	ld [wLineMask], a

	ld a, c
	sub a, 24
	srl a
	srl a
	and a, 254

	ld l, a
	ld h, HIGH(TileRowLut)
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld a, b
	rla
	ld a, h
	adc a, 0
	ld h, a

	ld a, b
	rla
	and a, 240
	add a, l
	ld l, a

	ld a, h
	adc a, 0
	ld h, a

	ld a, c
	and a, 7
	rla
	or a, l
	ld l, a

	di
	wait_stat
	ld a, [wLineMask]
	or a, [hl]
	ld [hli], a
	ld [hl], a
	ei

	pop hl
	ret

PrepLineDrawing::
	ld b, 0
	ld e, 12
	ld hl, _SCRN0 + 96

.loopRows
	ld c, 32
	ld d, 20

.loopColumns
	ld [hl], b

	ld a, 1
	ldh [rVBK], a
	xor a, a
	ld [hli], a
	ldh [rVBK], a

	inc b
	dec c
	dec d
	jr nz, .loopColumns

	ld a, b
	ld b, 0
	add hl, bc
	ld b, a
	dec e
	jr nz, .loopRows

	ret

SECTION "Line Mask Lookup Table", ROMX, ALIGN[8]

LineMaskLut:
	db $80, $40, $20, $10, $08, $04, $02, $01

SECTION "Tile Row Lookup Table", ROMX, ALIGN[8]

TileRowLut:
	dw $8000, $8140, $8280, $83C0, $8500, $8640, $8780, $88C0
	dw $8A00, $8B40, $8C80, $8DC0

SECTION "Line Drawing Variables", WRAM0

wIncX:
	db

wIncY:
	db

wLineMask:
	db