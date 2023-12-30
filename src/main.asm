; main.asm

INCLUDE "hardware.inc"

SECTION "RST Vector 0", ROM0[$0]

CopyMemory::
	ld a, [bc]
	ld [hli], a
	inc bc
	dec de
	ld a, d
	or a, e
	jr nz, CopyMemory
	ret

SECTION "RST Vector 10", ROM0[$10]

SetMemory::
	ld a, b
	ld [hli], a
	dec de
	ld a, d
	or a, e
	jr nz, SetMemory
	ret

SECTION "VBlank Interrupt", ROM0[$40]

	jp VblankHandler

SECTION "Entry Point", ROM0[$100]

	di
	jp Startup

SECTION "Header", ROM0[$104]

	NINTENDO_LOGO

SECTION "Startup Routine", ROM0[$150]

Startup:

.waitLy
	ldh a, [rLY]
	cp a, 144
	jr nz, .waitLy

	xor a, a
	ldh [rLCDC], a

	ld b, 0
	ld de, _SRAM - _VRAM
	ld hl, _VRAM
	rst 16

	ld de, wShadowOam.end - wShadowOam
	ld hl, wShadowOam
	rst 16

	ld a, $1B
	ldh [rBGP], a
	ldh [rOBP0], a
	ldh [rOBP1], a

	ld bc, OamDmaSource
	ld de, OamDmaSource.end - OamDmaSource
	ld hl, hOamDmaDest
	rst 0

	ld a, IEF_VBLANK
	ldh [rIE], a
	xor a, a
	ldh [rIF], a
	ei

	ld a, LCDCF_ON | LCDCF_BLK01 | LCDCF_BGON
	ldh [rLCDC], a

	call PrepScreen

	ld b, 72
	ld c, 35
	ld d, 124
	ld e, 20
	call PlotLine

	ld b, 50
	ld c, 26
	ld d, 91
	ld e, 77
	call PlotLine

	ld b, 39
	ld c, 73
	ld d, 116
	ld e, 63
	call PlotLine

	ld b, 102
	ld c, 76
	ld d, 25
	ld e, 43
	call PlotLine

	ld b, 72
	ld c, 86
	ld d, 113
	ld e, 32
	call PlotLine

	ld b, 73
	ld c, 22
	ld d, 41
	ld e, 79
	call PlotLine

	ld b, 21
	ld c, 50
	ld d, 126
	ld e, 50
	call PlotLine

	ld b, 76
	ld c, 18
	ld d, 76
	ld e, 30
	call PlotLine

MainLoop::
	halt
	jr MainLoop

OamDmaSource:
	ldh [rDMA], a
	ld a, 53
.wait636
	dec a
	jr nz, .wait636
	ret
.end

VblankHandler:
	push af
	ld a, HIGH(wShadowOam)
	call hOamDmaDest
	pop af
	reti

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wShadowOam::
	ds 4 * OAM_COUNT
.end

SECTION "OAM DMA Destination", HRAM

hOamDmaDest:
	ds OamDmaSource.end - OamDmaSource