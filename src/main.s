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
; this way you can do stuff like `lda players_input` to read what input was given
; the number behind .res is the amount of bytes it will reserve for this address
;********************************************

; 6502 Zero Page Memory (256 bytes)
.segment "ZEROPAGE"

nmi_ready: .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI

player_1_properties: .res P_PROPERTY_SIZE
player_2_properties: .res P_PROPERTY_SIZE

current_player_index: .res 1
current_player_properties: .res P_PROPERTY_SIZE

; Shape Tool
shape_tool_type: .res 1
shape_tool_has_set_first_pos: .res 1

shape_tool_first_pos_x: .res 1
shape_tool_first_pos_y: .res 1

shape_tool_second_pos_x: .res 1
shape_tool_second_pos_y: .res 1

shape_tool_staring_pos_x: .res 1
shape_tool_staring_pos_y: .res 1


; Fill tool (ring queue)
fill_temp: .res 1
fill_target_color: .res 1
queue_head: .res 1
queue_tail: .res 1
fill_current_addr: .res 2
fill_neighbor_addr: .res 2


; Cursor position (single 8x8 sprite)
cursor_x: .res 2
cursor_y: .res 2

player_controller_loop: .res 1

; store zero page for digit conversion (might not need this)
cursor_x_digits: .res 3
cursor_y_digits: .res 3
divide_by_x_divisor: .res 1 ; divisor for division routine in drawing_utils.s


; drawing-related vars
selected_tool: .res 1
tool_use_flag: .res 1
drawing_color_tile_index: .res 1


; misc
update_flag: .res 1
abs_address_to_access: .res 2
current_program_mode: .res 1
scroll_x_position: .res 1
scroll_y_position: .res 1
player_count: .res 1

; Sound engine variables
sfx_temp: .res 1        ; Temporary storage for SFX operations
sfx_channel: .res 1     ; SFX channel to use
music_paused: .res 1    ; this is a flag changing this does not actually pause the music


; Sprite OAM Data area - copied to VRAM in NMI routine
.segment "OAM"
oam: .res 256	; sprite OAM data

; Remainder of normal RAM area
.segment "BSS"
palette: .res 32 ; current palette buffer

; Fill queue (ring queue)
fill_queue: .res 512


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
.include "audio.s"

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

;***************************************
; FamiStudio Sound Engine Configuration
;***************************************
.segment "CODE"

; FamiStudio config
FAMISTUDIO_CFG_EXTERNAL         = 1
FAMISTUDIO_CFG_DPCM_SUPPORT     = 0  ; We do not have DPCM samples in our music or sfx
FAMISTUDIO_CFG_SFX_SUPPORT      = 1  ; Set to 1 if you want sound effects
FAMISTUDIO_CFG_SFX_STREAMS      = 2
FAMISTUDIO_USE_VOLUME_TRACK     = 1
FAMISTUDIO_USE_PITCH_TRACK      = 1
FAMISTUDIO_USE_SLIDE_NOTES      = 1
FAMISTUDIO_USE_VIBRATO          = 1
FAMISTUDIO_USE_ARPEGGIO         = 1
FAMISTUDIO_USE_RELEASE_NOTES    = 1
FAMISTUDIO_DPCM_OFF             = $c000

; CA65-specific config
.define FAMISTUDIO_CA65_ZP_SEGMENT ZEROPAGE
.define FAMISTUDIO_CA65_RAM_SEGMENT BSS
.define FAMISTUDIO_CA65_CODE_SEGMENT CODE

; Include FamiStudio sound engine
.include "famistudio_ca65.s"

; Include music data
.segment "RODATA"
; This makes Background_music.s read only
.include "Background_music.s" 
; Include SFX data
.include "SFX.s"
;***************************************

.segment "CODE"
.proc main
    ; main application - rendering is currently off
    
    ; clear 1st name table
    jsr LoadTilemap

    ; initialize palette table
    ldx #$00
    paletteloop:
        lda default_palette, x
        sta palette, x
        inx
        cpx #PALETTE_SIZE
        bcc paletteloop

    Initialize_Shape_Tool_Type:
        lda #SHAPE_TOOL_TYPE_DEFAULT
        sta shape_tool_type

    jsr PPUUpdate

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
.byte WHITE, RED, GREEN, LIGHT_BLUE
.byte $0f,$00,$10,$30
.byte $0f,BLUE,$16,$27
.byte $0f,$0b,$1a,$29
.byte GRAY, BLACK, BLUE, RED
.byte $0f,$00,$10,$30
.byte $0f,$05,$16,$27
.byte $0f,$0b,$1a,$29


; EXAMPLE_DATA:
    ; .byte EXAMPLE_Y_POS, TILEINDEX_EXAMPLE,   %10000001, $10

    ; Sprite Attributes:
        ;%76543210
        ;||||||||
        ;||||||++- Palette of sprite
        ;|||+++--- Unimplemented
        ;||+------ Priority (0: in front of background; 1: behind background)
        ;|+------- Flip sprite horizontally
        ;+-------- Flip sprite vertically


CURSOR_NORMAL_DATA:
    .byte $00, TILEINDEX_CURSOR_NORMAL,  %00000000, $00


CURSOR_MEDIUM_DATA:
    .byte   $08,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %10000000,     $00     ; BOTTOM-LEFT: mirrored y
    .byte   $00,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %00000000,     $00     ; TOP-LEFT
    .byte   $00,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %01000000,     $08     ; TOP-RIGHT: mirrored x
    .byte   $08,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %11000000,     $08     ; BOTTOM-RIGHT: mirrored x & y


CURSOR_BIG_DATA:
    .byte   $10,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %10000000,     $00     ; BOTTOM-LEFT: mirrored y
    .byte   $08,  TILEINDEX_CURSOR_BIG_LEFT,       %00000000,     $00     ; LEFT
    .byte   $00,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %00000000,     $00     ; TOP-LEFT
    .byte   $00,  TILEINDEX_CURSOR_BIG_TOP,        %00000000,     $08     ; TOP
    .byte   $00,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %01000000,     $10     ; TOP-RIGHT: mirrored x
    .byte   $08,  TILEINDEX_CURSOR_BIG_LEFT,       %01000000,     $10     ; RIGHT: mirrored x
    .byte   $10,  TILEINDEX_CURSOR_BIG_TOP_LEFT,   %11000000,     $10     ; BOTTOM-RIGHT: mirrored x & y
    .byte   $10,  TILEINDEX_CURSOR_BIG_TOP,        %10000000,     $08     ; BOTTOM: mirrored y


CURSOR_SHAPE_TOOL_DATA:
    .byte   OAM_OFFSCREEN,  TILEINDEX_CURSOR_SHAPE_TOOL_FIRST,    %00000000,     $00
    .byte   OAM_OFFSCREEN,  TILEINDEX_CURSOR_SHAPE_TOOL_SECOND,   %00000000,     $00

Canvas_UI_Tilemap:
    .incbin "./tilemaps/canvas.nam"


Overlay_Tool_Text:
    Brush_Text:
    .byte 'b' + LETTER_OFFSET, 'r' + LETTER_OFFSET, 'u' + LETTER_OFFSET, 's' + LETTER_OFFSET, 'h' + LETTER_OFFSET, $00

    Eraser_Text:
    .byte 'e' + LETTER_OFFSET, 'r' + LETTER_OFFSET, 'a' + LETTER_OFFSET, 's' + LETTER_OFFSET, 'e' + LETTER_OFFSET, 'r' + LETTER_OFFSET, $00

    Fill_Text:
    .byte 'f' + LETTER_OFFSET, 'i' + LETTER_OFFSET, 'l' + LETTER_OFFSET, 'l' + LETTER_OFFSET, $00

    Shape_Text:
    .byte 's' + LETTER_OFFSET, 'h' + LETTER_OFFSET, 'a' + LETTER_OFFSET, 'p' + LETTER_OFFSET, 'e' + LETTER_OFFSET, $00

    Clear_Text:
    .byte 'c' + LETTER_OFFSET, 'l' + LETTER_OFFSET, 'e' + LETTER_OFFSET, 'a' + LETTER_OFFSET, 'r' + LETTER_OFFSET, $00
