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


;WRAM
WRAM_START = $6000
WRAM_END   = $7FFF


; display
DISPLAY_SCREEN_WIDTH  = 32
DISPLAY_SCREEN_HEIGHT = 30
TILE_PIXEL_SIZE = $08

; oam offsets
CURSOR_OFFSET_SMALL = $00      ; 4 sprites, -> 4 (sprites) * 4 bytes (per sprite) = 16 bytes
CURSOR_OFFSET_NORMAL = $10     ; 1 sprites, -> 4 bytes
CURSOR_OFFSET_BIG = $14        ; 4 sprites, -> 16 bytes
SMILEY_OFFSET = $24

; program modes
MAIN_MENU = 0
CANVAS = 1

CURSOR_OFFSET_BIG_LEFT = $00
CURSOR_OFFSET_BIG_TOP = $04 
CURSOR_OFFSET_BIG_RIGHT = $08     
CURSOR_OFFSET_BIG_BOTTOM = $0C

; cursor type
CURSOR_TYPE_SMALL = $00
CURSOR_TYPE_NORMAL = $01
CURSOR_TYPE_BIG = $02

CURSOR_SMALL_DIR_TOP_LEFT= $00
CURSOR_SMALL_DIR_TOP_RIGHT = $04
CURSOR_SMALL_DIR_BOTTOM_LEFT = $08
CURSOR_SMALL_DIR_BOTTOM_RIGHT = $0C


; tile indexes
CURSOR_TILE_SMALL_TOP_LEFT = $10
CURSOR_TILE_SMALL_TOP_RIGHT = $11
CURSOR_TILE_SMALL_BOTTOM_LEFT = $12
CURSOR_TILE_SMALL_BOTTOM_RIGHT = $13

CURSOR_TILE_NORMAL = $14

CURSOR_TILE_BIG_LEFT = $20
CURSOR_TILE_BIG_TOP = $21
CURSOR_TILE_BIG_RIGHT = $22
CURSOR_TILE_BIG_BOTTOM = $23


SMILEYFACE_TILE = $24


; Brush
MAXIMUM_BRUSH_SIZE = $03
MINIMUM_BRUSH_SIZE = $01

; Tiles
BACKGROUND_TILE = $00

; Canvas Modes
DRAW_MODE = $00
ERASER_MODE = $01