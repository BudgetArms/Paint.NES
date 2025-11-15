;*****************************************************************
; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
;*****************************************************************
.proc ppu_update
	lda #1
	sta nmi_ready
	loop:
		lda nmi_ready
		bne loop
	rts
.endproc

;*****************************************************************
; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_DATA)
;*****************************************************************
.proc ppu_off
	lda #2
	sta nmi_ready
	loop:
		lda nmi_ready
		bne loop
	rts
.endproc


; Khine
.proc convert_cursor_coordinates_to_tile_index
	; Convert the X and Y coordinates of the cursor to
	; the tile index storied in 'tile_index' variable
	; 2 bytes -> LO + HI bytes
	; parameters: 0 -> Cursor X, 1 -> Cursor Y

	; Reset the tile index
	clc
	lda #$00
	sta tile_index
	sta tile_index + 1


	; A loop that multiplies the Y coordinate
	; with 32 since each namespace is 32 tiles wide
	; and then adding the resultant number to the X coordinate
	; Simple table to index conversion
	; For example, X: 2, Y: 6 would convert to (6 * 32) + 2 = 194
	lda #$00
	ldx arguments + 1
	beq skip_loop
	row_loop:
	adc #32
	dex
	; Check for carry bit and then increment the high bit when carry is set
	bcc skip_high_bit_increment1
		inc tile_index + 1
		clc
	skip_high_bit_increment1:
	bne row_loop
	skip_loop:
	adc arguments
	sta tile_index ; Low bit of the location

	; Increment the high bit position if there is a remaining carry flag set
	bcc skip_high_bit_increment2
		inc tile_index + 1 ; High bit of the location
		clc
	skip_high_bit_increment2:

	; Add the offset of nametable 1 to the tile index
	lda #<NAME_TABLE_1
	adc	tile_index
	sta tile_index
	lda #>NAME_TABLE_1
	adc #$00
	adc tile_index + 1
	sta tile_index + 1
	rts
.endproc
; Khine