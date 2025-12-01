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
input_holding_this_frame:	.res 1

frame_counter: .res 1   ;doesn't really count frames but it keeps looping over 256
                        ;this is to do stuff like "every time an 8th frame passes, do this"

; buttons hold-delays
; when the button is held, it starts counting until, it's reached the BUTTON_HOLD_TIME (0.5s)
; then it executes the button press again
frame_counter_holding_button_a: .res 1
frame_counter_holding_button_b: .res 1
frame_counter_holding_button_dpad: .res 1

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
cursor_x: .res 1
cursor_y: .res 1
tile_cursor_x: .res 1
tile_cursor_y: .res 1

; store zero page for digit conversion (might not need this)
cursor_x_digits: .res 3
cursor_y_digits: .res 3

divide_by_x_divisor: .res 1 ; divisor for division routine in drawing_utils.s

cursor_type: .res 1 ; 0: small, 1: normal, 2: big 
cursor_small_direction: .res 1 ; 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right 
cursor_tile_position: .res 2

; drawing-related vars
tool_mode: .res 1
tool_use_attr: .res 1
drawing_tile_position: .res 2
drawing_color_tile_index: .res 1
brush_tile_index: .res 1
brush_size: .res 1
newPaletteColor: .res 1

; misc
abs_address_to_access: .res 2
current_program_mode: .res 1
scroll_x_position: .res 1
scroll_y_position: .res 1


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
.segment "RODATA"               ; this makes Background_music.s read only
.include "Background_music.s" 
; INclude SFX data
.include "SFX.s"
;***************************************

.segment "CODE"
.proc main
    ; main application - rendering is currently off
    ; clear 1st name table
    jsr SetupCanvas

    ; initialize palette table
    ldx #0
    paletteloop:
        lda default_palette, x
        sta palette, x
        inx
        cpx #32
        bcc paletteloop
    

    initialize_button_held_times:
        lda #00
        sta frame_counter_holding_button_a
        sta frame_counter_holding_button_b
        sta frame_counter_holding_button_dpad


    initialize_cursor:
        lda #TYPE_CURSOR_STARTUP
        sta cursor_type

        ; set cursor_x/y
        lda #CURSOR_MIN_X * 8
        sta cursor_x

        lda #CURSOR_MIN_Y * 8
        sta cursor_y

        ; set cursor tile x/y
        lda #CURSOR_MIN_X
        sta tile_cursor_x

        lda #CURSOR_MIN_Y
        sta tile_cursor_y


    Initialize_Shape_Tool_Type:
        lda #SHAPE_TOOL_TYPE_DEFAULT
        sta shape_tool_type



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


SAMPLE_SPRITE:
;    .byte $00,SMILEYFACE_TILE, %10000001, $10
                                ;76543210
                                ;||||||||
                                ;||||||++- Palette of sprite
                                ;|||+++--- Unimplemented
                                ;||+------ Priority (0: in front of background; 1: behind background)
                                ;|+------- Flip sprite horizontally
                                ;+-------- Flip sprite vertically

CURSOR_SMALL_DATA:
    .byte $00, TILEINDEX_CURSOR_SMALL_TOP_LEFT, %00000000, $00      ; top-left
    .byte $00, TILEINDEX_CURSOR_SMALL_TOP_LEFT, %01000000, $00      ; top-right
    .byte $00, TILEINDEX_CURSOR_SMALL_TOP_LEFT, %10000000, $00      ; bottom-left
    .byte $00, TILEINDEX_CURSOR_SMALL_TOP_LEFT, %11000000, $00      ; bottom-right

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

Seletion_Star_Sprite:
    .byte OAM_OFFSCREEN, STAR_TILE, $00000000, SELECTION_STAR_X_OFFSET

Selection_Menu_Tilemap:
    .incbin "./tilemaps/selection_menu.nam"

