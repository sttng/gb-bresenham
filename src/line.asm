; line.asm

INCLUDE "hardware.inc"

MACRO get_delta ;\1 = start, \2 = end, \3 = delta, \4 = increment
	ld a, \2
	sub a, \1
	ld \3, a

	ld a, $1
	ld [\4], a

	jr nc, .isPositive\@

	ld a, \3
	cpl
	inc a
	ld \3, a

	ld a, $FF
	ld [\4], a

.isPositive\@
ENDM

MACRO plot_line ;\1 = position, \2 = end, \3 = second, \4 = delta one, \5 = delta two, \6 = error, \7 = increment one, \8 = increment two
	sla \5
	ld a, \5
	sub a, \4
	sla \4
	ld \6, a

.loopPosition\@
	call PlotPixel

	ld a, \5
	cp a, \6
	jr c, .isCarry\@

	ld a, [\8]
	add a, \3
	ld \3, a

	ld a, \6
	sub a, \4
	ld \6, a

.isCarry\@
	ld a, \6
	add a, \5
	ld \6, a

	ld a, [\7]
	add a, \1
	ld \1, a
	cp a, \2
	jr nz, .loopPosition\@

	call PlotPixel
ENDM

MACRO plot_straight ;\1 = position, \2 = end, \3 = increment one
.loopPosition\@
	call PlotPixel

	ld a, [\3]
	add a, \1
	ld \1, a
	cp a, \2
	jr nz, .loopPosition\@

	call PlotPixel
ENDM

MACRO wait_stat
.waitStat\@
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .waitStat\@
ENDM

SECTION "Line Drawing Functions", ROM0

PlotLine::
	get_delta b, d, h, wIncX
	get_delta c, e, l, wIncY

	ld a, h
	or a, a
	jr z, .isVertical

	ld a, l
	or a, a
	jr z, .isHorizontal

	cp a, h
	jr nc, .dyIsLonger

	plot_line b, d, c, h, l, e, wIncX, wIncY
	ret

.isVertical
	plot_straight c, e, wIncY
	ret

.isHorizontal
	plot_straight b, d, wIncX
	ret

.dyIsLonger
	plot_line c, e, b, l, h, d, wIncY, wIncX
	ret

PlotPixel::
	push hl

	ld a, b
	and a, $7
	ld l, a
	ld h, HIGH(LineMaskLut)
	ld a, [hl]
	ld [wLineMask], a

	ld a, c
	and a, $7
	ld h, a

	ld a, b
	sub a, $10
	and a, $F8
	or a, h
	rla
	ld l, a

	ld a, c
	sub a, $8
	srl a
	srl a
	scf
	rra
	ld h, a

	wait_stat
	ld a, [wLineMask]
	or a, [hl]
	ld [hli], a
	ld [hl], a

	pop hl
	ret

PrepScreen::
	xor a, a
	ld e, $10
	ld hl, _SCRN0 + $22

.loopRows
	ld c, $20
	ld d, $10

.loopColumns
	ld b, a
	wait_stat
	ld a, b

	ld [hli], a
	inc a
	dec c
	dec d
	jr nz, .loopColumns

	ld b, $0
	add hl, bc
	dec e
	jr nz, .loopRows

	ret

SECTION "Line Mask Lookup Table", ROMX, ALIGN[8]

LineMaskLut:
	db $80, $40, $20, $10, $08, $04, $02, $01

SECTION "Line Drawing Variables", WRAM0

wIncX:
	db

wIncY:
	db

wLineMask:
	db