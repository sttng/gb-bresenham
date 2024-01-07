; main.asm

INCLUDE "hardware.inc"

MACRO set_palette
	ld a, \1CPSF_AUTOINC
	ldh [r\1CPS], a

	ld b, 0
	ld d, 64
	ld hl, r\1CPD

.loopCpd\@
	ld [hl], b
	dec d
	jr nz, .loopCpd\@
ENDM

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

SECTION "Header - Part 1", ROM0[$104]

	NINTENDO_LOGO

SECTION "Header - Part 2", ROM0[$143]

	db CART_COMPATIBLE_GBC

SECTION "Startup Routine", ROM0[$150]

Startup:
	ldh a, [rLY]
	cp a, 144
	jr nz, Startup

	xor a, a
	ldh [rLCDC], a

	ld b, 0
	ld de, _SRAM - _VRAM
	ld hl, _VRAM
	rst 16

	ld a, 1
	ldh [rVBK], a

	ld b, 8
	ld de, _SCRN1 - _SCRN0
	ld hl, _SCRN0
	rst 16

	xor a, a
	ldh [rVBK], a

	call InitLineDrawing

	ld de, wShadowOam.end - wShadowOam
	ld hl, wShadowOam
	rst 16

	set_palette B
	set_palette O

	ld a, BCPSF_AUTOINC + 6
	ldh [rBCPS], a

	ld bc, $FF7F
	ld hl, rBCPD

	ld [hl], b
	ld [hl], c

	ld bc, OamDmaSource
	ld de, OamDmaSource.end - OamDmaSource
	ld hl, hOamDmaDest
	rst 0

	ld a, IEF_VBLANK
	ldh [rIE], a
	xor a, a
	ldh [rIF], a
	ei

	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
CopyTilemap:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTilemap

	ld a, LCDCF_ON | LCDCF_BLK01 | LCDCF_BGON
	ldh [rLCDC], a
	

	ld b, 0
	ld c, 24
	ld d, 159
	ld e, 119
	call DrawLine

	ld b, 98
	ld c, 54
	ld d, 44
	ld e, 73
	call DrawLine
	

	ld b, 12
	ld c, 24
	ld d, 44
	ld e, 24
	call DrawLine


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
	
	
	
SECTION "Tilemap", ROM0

Tilemap:
DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11,$12,$13,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$20,$21,$22,$23,$24,$25,$26,$27,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $28,$29,$2A,$2B,$2C,$2D,$2E,$2F,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $3C,$3D,$3E,$3F,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F,$60,$61,$62,$63,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$70,$71,$72,$73,$74,$75,$76,$77,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $78,$79,$7a,$7b,$7c,$7d,$7e,$7f,$80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $8c,$8d,$8e,$8f,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af,$b0,$b1,$b2,$b3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf,$c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf,$d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$db,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $dc,$dd,$de,$df,$e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
TilemapEnd: