; Define PPU Registers
PPU_CONTROL = $2000 ; PPU Control Register 1 (Write)
PPU_MASK = $2001 ; PPU Control Register 2 (Write)
PPU_STATUS = $2002; PPU Status Register (Read)
PPU_OAMADDR = $2003 ; PPU SPR-RAM Address Register (Write)
PPU_OAMDATA = $2004 ; PPU SPR-RAM I/O Register (Write)
PPU_SCROLL = $2005 ; PPU VRAM Address Register 1 (Write)
PPU_ADDR = $2006 ; PPU VRAM Address Register 2 (Write)
PPU_DATA = $2007 ; VRAM I/O Register (Read/Write)
PPU_OAMDMA = $4014 ; Sprite DMA Register

; PPU Memory Map
PPU_PATTERN_TABLE_0 = $0000
PPU_PATTERN_TABLE_1 = $1000

PPU_NAMETABLE_0 = $2000
PPU_ATTRIBUTE_TABLE_0 = $23C0
PPU_NAMETABLE_1 = $2400
PPU_ATTRIBUTE_TABLLE_1 = $27C0
PPU_NAMETABLE_2 = $2800
PPU_ATTRIBUTE_TABLLE_2 = $2BC0
PPU_NAMETABLE_3 = $2C00
PPU_ATTRIBUTE_TABLLE_3 = $2FC0

PPU_PALLETE_START = $3F00


; Define APU Registers
APU_DM_CONTROL = $4010 ; APU Delta Modulation Control Register (Write)
APU_CLOCK = $4015 ; APU Sound/Vertical Clock Signal Register (Read/Write)

;cpu oam data
CPU_OAM_PTR = $0200

; Joystick/Controller values
JOYPAD1 = $4016 ; Joypad 1 (Read/Write)
JOYPAD2 = $4017 ; Joypad 2 (Read/Write)

; Gamepad bit values
PAD_A      = $01
PAD_B      = $02
PAD_SELECT = $04
PAD_START  = $08
PAD_UP     = $10
PAD_DOWN   = $20
PAD_LEFT   = $40
PAD_RIGHT  = $80

; name tables
NAME_TABLE_1 = $2000
ATTR_TABLE_1 = $23C0
NAME_TABLE_2 = $2400
ATTR_TABLE_2 = $27C0
NAME_TABLE_3 = $2C00
ATTR_TABLE_3 = $2FC0
ATTR_TABLE_SIZE = $40

;WRAM
WRAM_START = $6000
WRAM_END   = $7FFF


; display
DISPLAY_REFRESH_RATE_HZ = 50
DISPLAY_SCREEN_WIDTH  = 32
DISPLAY_SCREEN_HEIGHT = 30
TILE_PIXEL_SIZE = $08

; oam offsets
CURSOR_OFFSET_SMALL = $00      ; 4 sprites, -> 4 (sprites) * 4 bytes (per sprite) = 16 bytes
CURSOR_OFFSET_NORMAL = $10     ; 1 sprites, -> 4 bytes
CURSOR_OFFSET_BIG = $14        ; 4 sprites, -> 16 bytes
; Hold Times (in frames)
BUTTON_HOLD_TIME_SLOW = DISPLAY_REFRESH_RATE_HZ
BUTTON_HOLD_TIME_NORMAL = (DISPLAY_REFRESH_RATE_HZ + 1) / 3
BUTTON_HOLD_TIME_FAST = (DISPLAY_REFRESH_RATE_HZ + 1) / 2
BUTTON_HOLD_TIME_INSTANTLY = (DISPLAY_REFRESH_RATE_HZ + 1) / 10

; program modes
MAIN_MENU = 0
CANVAS = 1


; cursor types
TYPE_CURSOR_SMALL = $00
TYPE_CURSOR_NORMAL = $01
TYPE_CURSOR_BIG = $02

; cursor small directions
DIR_CURSOR_SMALL_TOP_LEFT       = $00
DIR_CURSOR_SMALL_TOP_RIGHT      = $04
DIR_CURSOR_SMALL_BOTTOM_LEFT    = $08
DIR_CURSOR_SMALL_BOTTOM_RIGHT   = $0C


; tile indexes
TILEINDEX_CURSOR_SMALL_TOP_LEFT = $10
TILEINDEX_CURSOR_NORMAL = $20
TILEINDEX_CURSOR_BIG_TOP_LEFT = $30 ; top-left corner
TILEINDEX_CURSOR_BIG_TOP = $40
TILEINDEX_CURSOR_BIG_LEFT = $50
TILEINDEX_SMILEY = $60

TILEINDEX_TRANSPARENT_TILE = $FF    ; Last tile in CHR ROM (transparent)
TILEINDEX_OFFSET_COLOR_1 = $00      ; Color Pallet 1
TILEINDEX_OFFSET_COLOR_2 = $01      ; Color Pallet 2
TILEINDEX_OFFSET_COLOR_3 = $02      ; Color Pallet 3


; oam data sizes
OAM_SIZE_CURSOR_SMALL   = $04       ; 4 bytes
OAM_SIZE_CURSOR_NORMAL  = $04       ; 4 bytes
OAM_SIZE_CURSOR_BIG     = $20       ; 32 bytes


; oam offsets are not same as tile indexes
OAM_OFFSET_CURSOR_SMALL     = $00   ; 1 sprite (4 bytes)
OAM_OFFSET_CURSOR_NORMAL    = $04   ; 1 sprite (4 bytes)
OAM_OFFSET_CURSOR_BIG       = $08   ; 8 sprites (32 bytes)
OAM_OFFSET_SMILEY           = $28   ; 1 sprite (4 bytes) 

OAM_OFFSET_CURSOR_BIG_BOTTOM_LEFT   = $00
OAM_OFFSET_CURSOR_BIG_LEFT          = $04
OAM_OFFSET_CURSOR_BIG_TOP_LEFT      = $08
OAM_OFFSET_CURSOR_BIG_TOP           = $0C
OAM_OFFSET_CURSOR_BIG_TOP_RIGHT     = $10
OAM_OFFSET_CURSOR_BIG_RIGHT         = $14
OAM_OFFSET_CURSOR_BIG_BOTTOM_RIGHT  = $18
OAM_OFFSET_CURSOR_BIG_BOTTOM        = $1C


; Brush
MAXIMUM_BRUSH_SIZE   = $03
MINIMUM_BRUSH_SIZE   = $01
ALL_TOOLS_OFF        = %00000000
BRUSH_TOOL_ON        = %00000001
CLEAR_CANVAS_TOOL_ON = $00000010

; Tiles
BACKGROUND_TILE = $00
STAR_TILE = $F0
COLOR_TILE_START_INDEX = $01
COLOR_TILE_END_INDEX = $03

; Selection Star
SELECTION_STAR_OFFSET = $30
SELECTION_STAR_X_OFFSET = $0F
SELECTION_STAR_Y_START_POS = $BF
SELECTION_STAR_Y_END_POS = $D7

; Selection Menu
SELECTION_MENU_0_DRAW = $BF
SELECTION_MENU_1_ERASER = $C7
SELECTION_MENU_2_FILL = $CF
SELECTION_MENU_3_CLEAR = $D7

; OAM
OAM_Y = $00
OAM_TILE = $01
OAM_ATTR = $02
OAM_X = $03
OAM_OFFSCREEN = $FF

; Tool modes
DRAW_MODE = $00
ERASER_MODE = $01

; Canvas mode
CANVAS_MODE = $00
SELECTION_MENU_MODE = $40
; UI overlay
OVERLAY_NAMETABLE_ADDR = $2000
;OVERLAY_X_POS = 0                   ; Column 0
;OVERLAY_Y_POS = 0                   ; Row 0
OVERLAY_TILE_CURSOR_X_LABEL = $D8   ; ASCII 'X'
OVERLAY_TILE_CURSOR_Y_LABEL = $D9   ; ASCII 'Y'
OVERLAY_TILE_COLON = $E5            ; ASCII ':'
OVERLAY_TILE_SPACE = $00            ; ASCII ' '
OVERLAY_TILE_DIGIT_0 = $DB          ; Start of digit tiles in CHR
;OVERLAY_DIGIT_TILE_OFFSET = $00     ; Offset for digit tiles
;OVERLAY_CURSOR_X_LABEL_POS_X = 0    ; First tile in overlay row
;OVERLAY_CURSOR_X_VALUE_POS = 2      ; After label and colon
;OVERLAY_CURSOR_Y_LABEL_POS = 6      ; After X value
;OVERLAY_CURSOR_Y_VALUE_POS = 8      ; After label and colon
