.include "constants.s"

; NES Cartridge header
.segment "HEADER"
INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 0 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 1 ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID
.byte $02 ; 16k PRG bank count
.byte $01 ; 8k CHR bank count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

; Import both the background and sprite character sets
.segment "TILES"
.incbin "game.chr"

; Define NES interrupt vectors
.segment "VECTORS"
.word nmi
.word reset
.word irq

;********************************************
; Reserves
; using .res you can reserve addresses in memory as "variables" 
; this way you can do stuff like `lda current_input` to read what input was given
; the number behind .res is the amount of bytes it will reserve for this address
;********************************************

; 6502 Zero Page Memory (256 bytes)
.segment "ZEROPAGE"

nmi_ready: .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI

current_input:				.res 1 ; stores the current gamepad values
last_frame_input:			.res 1
input_pressed_this_frame:	.res 1
input_released_this_frame:	.res 1

frame_counter: .res 1   ;doesn't really count frames but it keeps looping over 256
                        ;this is to do stuff like "every time an 8th frame passes, do this"

; Cursor position (single 8x8 sprite)
cursor_x: .res 1
cursor_y: .res 1
tile_cursor_x: .res 1
tile_cursor_y: .res 1

cursor_type: .res 1 ; 0: small, 1: normal, 2: big 
cursor_small_direction: .res 1 ; 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right 
cursor_tile_position: .res 2

; drawing-related vars
drawing_tile_position: .res 2
brush_tile_index: .res 1
brush_size: .res 1

current_program_mode: .res 1
; Sprite OAM Data area - copied to VRAM in NMI routine
.segment "OAM"
oam: .res 256	; sprite OAM data

; Remainder of normal RAM area
.segment "BSS"
palette: .res 32 ; current palette buffer

;*****************************************************************
; Main application logic section
;*****************************************************************

;***************************************
; Some useful functions
.segment "CODE"
.include "utils/utils.s"
.include "utils/drawing_utils.s"
.include "utils/input_utils.s"
.include "draw.s"

;.include "cursor.s"

;***************************************
; starting point
.segment "CODE"
.include "reset.s"

;***************************************
; nmi
.segment "CODE"
.include "nmi.s"

;***************************************
; interrupt request
.segment "CODE"
irq:
    ;handle interrupt if needed
    rti

;***************************************
.segment "CODE"
.proc main
    ; main application - rendering is currently off
    ; clear 1st name table
    jsr setup_canvas
    ; initialize palette table
    ldx #0
paletteloop:
    lda default_palette, x
    sta palette, x
    inx
    cpx #32
    bcc paletteloop

    jsr ppu_update

.ifdef TESTS
.include "tests/tests.s"
.endif

    .include "mainloop.s"
.endproc

;***************************************
; default palette table; 16 entries for tiles and 16 entries for sprites
.segment "RODATA"
default_palette:
;bg tiles/ text
.byte $0f,$00,$10,$30
.byte $0f,$0c,$21,$32
.byte $0f,$05,$16,$27
.byte $0f,$0b,$1a,$29


;sprites
.byte $0f,$20,$10,$30 ; changed Color 1 to $20 for testing
.byte $0f,$0c,$21,$32
.byte $0f,$05,$16,$27
.byte $0f,$0b,$1a,$29


SMILEY_DATA:
    .byte $00, SMILEYFACE_TILE, %10000001, $10
                                ;76543210
                                ;||||||||
                                ;||||||++- Palette of sprite
                                ;|||+++--- Unimplemented
                                ;||+------ Priority (0: in front of background; 1: behind background)
                                ;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically

CURSOR_SMALL_DATA:
    .byte $00, CURSOR_TILE_SMALL_TOP_LEFT,      %00000000, $00
    .byte $00, CURSOR_TILE_SMALL_TOP_RIGHT,     %00000000, $00
    .byte $00, CURSOR_TILE_SMALL_BOTTOM_LEFT,   %00000000, $00
    .byte $00, CURSOR_TILE_SMALL_BOTTOM_RIGHT,  %00000000, $00

CURSOR_NORMAL_DATA:
    .byte $00, CURSOR_TILE_NORMAL,  %00000000, $00

CURSOR_BIG_DATA:
    .byte $00, CURSOR_TILE_BIG_LEFT,    %00000000, $00
    .byte $00, CURSOR_TILE_BIG_TOP,     %00000000, $00
    .byte $00, CURSOR_TILE_BIG_RIGHT,   %00000000, $00
    .byte $00, CURSOR_TILE_BIG_BOTTOM,  %00000000, $00

