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
player: .res P_PROPERTY_SIZE
; tile position output
tile_position_output: .res 2

; Shape Tool
;player + P_SHAPE_TOOL_TYPE: .res 1
;player + P_SHAPE_TOOL_FIRST_SET: .res 1

;player + P_SHAPE_TOOL_FIRST_POS: .res 2
;player + P_SHAPE_TOOL_SECOND_POS: .res 2

shape_tool_starting_pos: .res 2
shape_tool_temp_pos: .res 2

; shape tool: retangle
shape_tool_rectangle_width: .res 1
shape_tool_rectangle_height: .res 1


; shape tool: circle
shape_tool_circle_radius: .res 1
shape_tool_circle_draw_pos: .res 2
shape_tool_circle_offset: .res 2
shape_tool_circle_decision_parameter: .res 1


; Fill tool (ring queue)
fill_temp: .res 1
fill_target_color: .res 1
queue_head: .res 1
queue_tail: .res 1
fill_current_addr: .res 2
fill_neighbor_addr: .res 2

; store zero page for digit conversion (might not need this)
cursor_x_digits: .res 3
cursor_y_digits: .res 3
divide_by_x_divisor: .res 1 ; divisor for division routine in drawing_utils.s


; drawing-related vars
drawing_color_tile_index: .res 1


; misc
next_program_mode: .res 1
current_program_mode: .res 1
previous_program_mode: .res 1
mode_transition_time: .res 1
current_transition_addr: .res 2
update_flag: .res 1
abs_address_to_access: .res 2
scroll_x_position: .res 1
scroll_y_position: .res 1
player_count: .res 1
loop_index: .res 1

; Sound engine variables
sfx_temp: .res 1        ; Temporary storage for SFX operations
sfx_channel: .res 1     ; SFX channel to use
music_paused: .res 1    ; this is a flag changing this does not actually pause the music


; Save system
save_temp_byte: .res 1
save_ptr: .res 2


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
    
    ; load start menu
    ; Help menu is only needed to load once
    jsr InitializeHelpMenuTilemap
    jsr EnterStartMenuMode
    jsr LoadPalette

    jsr PPUUpdate

.ifdef TESTS
.include "tests/tests.s"
.endif

    .include "mainloop.s"
.endproc

;***************************************
; default palette table; 16 entries for tiles and 16 entries for sprites
.segment "RODATA"
START_MENU_PALETTE:
;.byte $00, $3c, $2c, $01
;.byte $00, $3d, $05, $0f
;.byte $00, $0d, $24, $31
;.byte $00, $1c, $3c, $0f
;.byte GRAY, BLACK, BLUE, RED
;.byte $0f,$00,$10,$30
;.byte $0f,$05,$16,$27
;.byte $0f,$0b,$1a,$29

default_palette:
;bg tiles/ text
;.byte OFFWHITE, RED, GREEN, BLUE
;.byte OFFWHITE,OFFWHITE,RED,BLACK
;.byte OFFWHITE,BLACK,$24,$2c ; pink and blue
;.byte OFFWHITE,GREEN,BLUE,BLACK
;.byte GRAY, BLACK, BLUE, RED
;.byte $0f,$00,$10,$30
;.byte $0f,$05,$16,$27
;.byte $0f,$0b,$1a,$29

color_palette_ui_overlay:
    .byte OFFWHITE, RED, GREEN, BLUE
    .byte OFFWHITE, OFFWHITE, RED, $0f
    .byte OFFWHITE, $0f, $24, $2c
    .byte OFFWHITE, GREEN, BLUE, $0f
    .byte GRAY, BLACK, BLUE, RED
    .byte $0f,$00,$10,$30
    .byte $0f,$05,$16,$27
    .byte $0f,$0b,$1a,$29

color_palette_help_menu:
    .byte $00, $3c, $2c, $01
    .byte $00, $3d, $05, $0f
    .byte $00, $0d, $24, $31
    .byte $00, $1c, $3c, $0f
    .byte GRAY, BLACK, BLUE, RED
    .byte $0f,$00,$10,$30
    .byte $0f,$05,$16,$27
    .byte $0f,$0b,$1a,$29

color_palette_startup_menu:
    .byte $16, $00, $29, $0f
    .byte $16, $19, $29, $0f
    .byte $16, $05, $16, $27
    .byte $16, $0b, $19, $29
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

CURSOR_START_MENU:
    .byte START_MENU_CURSOR_Y_OFFSET, TILEINDEX_STAR, %00000000, START_MENU_CURSOR_X_OFFSET

CURSOR_NORMAL_DATA:
    .byte $00, TILEINDEX_CURSOR_NORMAL, %00000000, $00


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


CURSOR_SHAPE_TOOL_RECTANGLE_DATA:
    .byte   OAM_OFFSCREEN,  TILEINDEX_CURSOR_SHAPE_TOOL_RECTANGLE_FIRST,    %00000000,     $00
    .byte   OAM_OFFSCREEN,  TILEINDEX_CURSOR_SHAPE_TOOL_RECTANGLE_SECOND,   %00000000,     $00

CURSOR_SHAPE_TOOL_CIRCLE_DATA:
    .byte   OAM_OFFSCREEN,  TILEINDEX_CURSOR_SHAPE_TOOL_CIRCLE_FIRST,    %00000000,     $00
    .byte   OAM_OFFSCREEN,  TILEINDEX_CURSOR_SHAPE_TOOL_CIRCLE_SECOND,   %00000000,     $00

Start_Menu_Tilemap:
    .incbin "./tilemaps/start_menu.nam"

Help_Menu_Tilemap:
    .incbin "./tilemaps/help_menu.nam"

Canvas_Tilemap:
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
