;file for all drawing functions

; Khine
.proc draw_brush
  lda tile_index
  sta temp_swap
  lda tile_index + 1
  sta temp_swap + 1

  lda arguments + 4
  beq square_brush
  jmp circle_brush

  ; square brush
  square_brush:
  ldy #$00
  @column_loop:

  lda PPU_STATUS ; reset address latch
	lda tile_index + 1 ; High bit of the location
	sta PPU_ADDR
	lda tile_index ; Low bit of the location
	sta PPU_ADDR

  ldx #$00
  lda arguments + 2 ; Color index of the tile
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

  lda temp_swap
  sta tile_index
  lda temp_swap + 1
  sta tile_index + 1
  rts



  ; cirle brush
  circle_brush:
  ldx arguments + 3
  lda #$FF
  @calc_brush_size:
  clc
  adc #$02
  dex
  bne @calc_brush_size
  sta circle_brush_size

  lda #$01
  sta circle_brush_fill_count
  lda arguments + 3
  sec
  sbc #$01
  sta circle_brush_offset

  ldy #$00
  @column_loop:

  lda PPU_STATUS ; reset address latch
	lda tile_index + 1 ; High bit of the location
	sta PPU_ADDR
	lda tile_index ; Low bit of the location
	sta PPU_ADDR

  ldx #$00
    @row_loop:
    cpx circle_brush_offset
    bne @skip_tile_update
      lda arguments + 2 ; Color index of the tile
      sta PPU_DATA
      jmp @skip_tile_read
    @skip_tile_update:
      lda PPU_DATA
    @skip_tile_read:
    inx
    cpx circle_brush_size
    bne @row_loop
  clc
  lda tile_index
  adc #32
  sta tile_index
  lda tile_index + 1
  adc #$00
  sta tile_index + 1
  iny
  cpy circle_brush_size
  bmi @column_loop

  lda temp_swap
  sta tile_index
  lda temp_swap + 1
  sta tile_index + 1
  rts
.endproc
; Khine