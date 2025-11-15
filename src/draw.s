;file for all drawing functions

; Khine
.proc draw_one_block
	lda PPU_STATUS ; reset address latch
	lda tile_index + 1 ; High bit of the location
	sta PPU_ADDR
	lda tile_index ; Low bit of the location
	sta PPU_ADDR

	lda arguments + 2 ; Color index of the tile
	sta PPU_DATA
  rts
.endproc
