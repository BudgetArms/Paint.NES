; Define PPU Registers
PPU_CONTROL = $2000 ; PPU Control Register 1 (Write)
PPU_MASK    = $2001 ; PPU Control Register 2 (Write)
PPU_STATUS  = $2002; PPU Status Register (Read)
PPU_OAMADDR = $2003 ; PPU SPR-RAM Address Register (Write)
PPU_OAMDATA = $2004 ; PPU SPR-RAM I/O Register (Write)
PPU_SCROLL  = $2005 ; PPU VRAM Address Register 1 (Write)
PPU_ADDR    = $2006 ; PPU VRAM Address Register 2 (Write)
PPU_DATA    = $2007 ; VRAM I/O Register (Read/Write)
PPU_OAMDMA  = $4014 ; Sprite DMA Register

; PPU Memory Map
PPU_PATTERN_TABLE_0 = $0000
PPU_PATTERN_TABLE_1 = $1000

PPU_NAMETABLE_0         = $2000
PPU_ATTRIBUTE_TABLE_0   = $23C0
PPU_NAMETABLE_1         = $2400
PPU_ATTRIBUTE_TABLLE_1  = $27C0
PPU_NAMETABLE_2         = $2800
PPU_ATTRIBUTE_TABLLE_2  = $2BC0
PPU_NAMETABLE_3         = $2C00
PPU_ATTRIBUTE_TABLLE_3  = $2FC0

PPU_PALLETE_START = $3F00


; Define APU Registers
APU_DM_CONTROL  = $4010 ; APU Delta Modulation Control Register (Write)
APU_CLOCK       = $4015 ; APU Sound/Vertical Clock Signal Register (Read/Write)

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

PAD_UP_LEFT     = $50
PAD_DOWN_LEFT   = $60
PAD_UP_RIGHT    = $90
PAD_DOWN_RIGHT  = $a0

PAD_A_UP    = $11
PAD_A_DOWN  = $21
PAD_A_LEFT  = $41
PAD_A_RIGHT = $81

PAD_A_UP_LEFT       = $51
PAD_A_DOWN_LEFT     = $61
PAD_A_UP_RIGHT      = $91
PAD_A_DOWN_RIGHT    = $a1

PAD_START_UP    = $18
PAD_START_DOWN  = $28
PAD_START_LEFT  = $48
PAD_START_RIGHT = $88

PAD_SELECT_UP       = $14
PAD_SELECT_DOWN     = $24
PAD_SELECT_LEFT     = $44
PAD_SELECT_RIGHT    = $84

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
DISPLAY_SCREEN_WIDTH    = 32
DISPLAY_SCREEN_HEIGHT   = 30
TILE_PIXEL_SIZE         = $08

; oam offsets
CURSOR_OFFSET_SMALL     = $00       ; 4 sprites, -> 4 (sprites) * 4 bytes (per sprite) = 16 bytes
CURSOR_OFFSET_NORMAL    = $10       ; 1 sprites, -> 4 bytes
CURSOR_OFFSET_BIG       = $14       ; 4 sprites, -> 16 bytes

; Hold Times (in frames)
BUTTON_HOLD_TIME_SLOW       = DISPLAY_REFRESH_RATE_HZ
BUTTON_HOLD_TIME_NORMAL     = (DISPLAY_REFRESH_RATE_HZ + 1) / 3
BUTTON_HOLD_TIME_FAST       = (DISPLAY_REFRESH_RATE_HZ + 1) / 2
BUTTON_HOLD_TIME_INSTANTLY  = 1
FRAMES_BETWEEN_MOVEMENT     = 8

; program modes
MAIN_MENU = 0
CANVAS = 1


; Cursor locks (can't go lower/higher)
CURSOR_MIN_X = 0
CURSOR_MAX_X = 32

CURSOR_MIN_Y = 2
CURSOR_MAX_Y = 28


; cursor types
TYPE_CURSOR_SMALL   = $00
TYPE_CURSOR_NORMAL  = $01
TYPE_CURSOR_MEDIUM  = $02
TYPE_CURSOR_BIG     = $03

; cursor start type (at startup)
TYPE_CURSOR_STARTUP = TYPE_CURSOR_NORMAL

; cursor types min/max
TYPE_CURSOR_MINIMUM = TYPE_CURSOR_NORMAL
TYPE_CURSOR_MAXIMUM = TYPE_CURSOR_BIG


; cursor small directions
DIR_CURSOR_SMALL_TOP_LEFT       = $00
DIR_CURSOR_SMALL_TOP_RIGHT      = $04
DIR_CURSOR_SMALL_BOTTOM_LEFT    = $08
DIR_CURSOR_SMALL_BOTTOM_RIGHT   = $0C


; tile indexes
TILEINDEX_CURSOR_SMALL_TOP_LEFT = $10
TILEINDEX_CURSOR_NORMAL         = $20
TILEINDEX_CURSOR_BIG_TOP_LEFT   = $30
TILEINDEX_CURSOR_BIG_TOP        = $40
TILEINDEX_CURSOR_BIG_LEFT       = $50

TILEINDEX_SMILEY = $60

TILEINDEX_CURSOR_SHAPE_TOOL_FIRST   = $A0
TILEINDEX_CURSOR_SHAPE_TOOL_SECOND  = $B0


; oam data sizes
OAM_SIZE_CURSOR_SMALL   = $04       ; 4 bytes
OAM_SIZE_CURSOR_NORMAL  = $04       ; 4 bytes
OAM_SIZE_CURSOR_MEDIUM  = $10       ; 16 bytes
OAM_SIZE_CURSOR_BIG     = $20       ; 32 bytes
OAM_SIZE_CURSOR_SHAPE   = $04       ; 4 bytes


; oam offsets are not same as tile indexes
OAM_OFFSET_CURSOR_SMALL     = $00   ; 1 sprite (4 bytes)
OAM_OFFSET_CURSOR_NORMAL    = $04   ; 1 sprite (4 bytes)
OAM_OFFSET_CURSOR_MEDIUM    = $08   ; 4 sprite (16 bytes), different location to avoid overwriting star
OAM_OFFSET_CURSOR_BIG       = $18   ; 8 sprites (32 bytes)
OAM_OFFSET_SMILEY           = $28   ; 1 sprite (4 bytes) 

OAM_OFFSET_CURSOR_BIG_BOTTOM_LEFT   = $00
OAM_OFFSET_CURSOR_BIG_LEFT          = $04
OAM_OFFSET_CURSOR_BIG_TOP_LEFT      = $08
OAM_OFFSET_CURSOR_BIG_TOP           = $0C
OAM_OFFSET_CURSOR_BIG_TOP_RIGHT     = $10
OAM_OFFSET_CURSOR_BIG_RIGHT         = $14
OAM_OFFSET_CURSOR_BIG_BOTTOM_RIGHT  = $18
OAM_OFFSET_CURSOR_BIG_BOTTOM        = $1C

OAM_OFFSET_CURSOR_SHAPE_TOOL        = $44


; Brush
MAXIMUM_BRUSH_SIZE   = $03
MINIMUM_BRUSH_SIZE   = $01

; Shape
MINIMUM_SHAPE_SIZE   = $01

SHAPE_TOOL_TYPE_RECTANGLE   = %00000001
SHAPE_TOOL_TYPE_CIRCLE      = %00000010

SHAPE_TOOL_TYPE_DEFAULT     = SHAPE_TOOL_TYPE_RECTANGLE


; Tools
ALL_TOOLS_OFF   = %00000000
BRUSH_TOOL_ON   = %00000001
ERASER_TOOL_ON  = %00000010
SHAPE_TOOL_ON   = %00000100
FILL_TOOL_ON    = %00001000
CLEAR_TOOL_ON   = %00010000


; Tiles
BACKGROUND_TILE = $00

; OAM
OAM_Y           = $00
OAM_TILE        = $01
OAM_ATTR        = $02
OAM_X           = $03
OAM_OFFSCREEN   = $FF

; Tool modes
DRAW_MODE   = %00000000
SHAPE_MODE  = %00000001
ERASER_MODE = %00000010
FILL_MODE   = %00000100

; Canvas mode
CANVAS_MODE = $00

; UI overlay
OVERLAY_NAMETABLE_ADDR      = $2022
OVERLAY_TILE_CURSOR_X_LABEL = $D8   ; ASCII 'X'
OVERLAY_TILE_CURSOR_Y_LABEL = $D9   ; ASCII 'Y'
OVERLAY_TILE_COLON          = $E5   ; ASCII ':'
OVERLAY_TILE_SPACE          = $00   ; ASCII ' '
OVERLAY_TILE_DIGIT_0        = $DB   ; Start of digit tiles in CHR


; Fill Tool VRAM structure
PPU_VRAM_MASK_X_POS         = %00011111
PPU_VRAM_MASK_Y_POS_LOW     = %11100000
PPU_VRAM_MASK_Y_POS_HIGH    = %00000011

FIRST_COLOR_TILE_INDEX      = $04 ; also known as the background color tile
SECOND_COLOR_TILE_INDEX     = $05
THIRD_COLOR_TILE_INDEX      = $06
FOURTH_COLOR_TILE_INDEX     = $07

FIRST_COLOR_ONSCREEN_ADRESS     = $2030
SECOND_COLOR_ONSCREEN_ADRESS    = $2031
THIRD_COLOR_ONSCREEN_ADRESS     = $2032
FOURTH_COLOR_ONSCREEN_ADRESS    = $2033

BRUSH_TOOL_ONSCREEN_ADRESS  = $2037
ERASER_TOOL_ONSCREEN_ADRESS = $2039
FILL_TOOL_ONSCREEN_ADRESS   = $203b
CLEAR_TOOL_ONSCREEN_ADRESS  = $203d
BRUSH_ICON_TILE_INDEX       = $08 ; also known as the background color tile
ERASER_ICON_TILE_INDEX      = $09
FILL_ICON_TILE_INDEX        = $0a
CLEAR_ICON_TILE_INDEX       = $0b

; Tools
; TODO: now it's 5: draw, eraser (doesn't do shit), fill, shape, clear
; TODO: reduce this to 4: draw, shape, fill, clear
TOOLS_TOTAL_AMOUNT = 5

BRUSH_TOOL_ACTIVATED    = $00
ERASER_TOOL_ACTIVATED   = $01
FILL_TOOL_ACTIVATED     = $02
SHAPE_TOOL_ACTIVATED    = $03
CLEAR_TOOL_ACTIVATED    = $04





;Color values
WHITE       = $30
OFFWHITE    = $10
GRAY        = $00
RED         = $05
GREEN       = $0a
BLUE        = $01

