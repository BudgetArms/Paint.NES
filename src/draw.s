;file for all drawing functions

; Khine
.proc draw_brush
  lda tile_index
  sta temp_swap
  lda tile_index + 1
  sta temp_swap + 1

  ; square brush
  ldy #$00
  @column_loop:

  lda PPU_STATUS ; reset address latch
	lda tile_index + 1 ; High bit of the location
	sta PPU_ADDR
	lda tile_index ; Low bit of the location
	sta PPU_ADDR

  ldx #$00
  lda arguments + 2 ; Pattern index of the tile
    @row_loop:
    sta PPU_DATA
    inx
    cpx arguments + 3
    bne @row_loop
  clc
  lda tile_index
  adc #32
  sta tile_index
  lda tile_index + 1
  adc #$00
  sta tile_index + 1
  iny
  cpy arguments + 3
  bne @column_loop

  ; restoring the indices
  lda temp_swap
  sta tile_index
  lda temp_swap + 1
  sta tile_index + 1
  rts
.endproc
; Khine


; Khine
.proc load_tilemap
  lda PPU_STATUS ; reset address latch
	lda #>NAME_TABLE_1 ; High bit of the location
	sta PPU_ADDR
	lda #<NAME_TABLE_1 ; Low bit of the location
	sta PPU_ADDR

  ldx #$00
  lda #<main_menu_tilemap
  sta temp_swap
  lda #>main_menu_tilemap
  sta temp_swap + 1
  @outer_loop:
    ldy #$00
      @inner_loop:
      lda (temp_swap), y
      sta PPU_DATA
      iny
      bne @inner_loop
    lda temp_swap + 1
    clc
    adc #$01
    sta temp_swap + 1
    inx
    cpx #$04
    bne @outer_loop
  
  rts
.endproc