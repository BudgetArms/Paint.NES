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
DISPLAY_REFRESH_RATE_HZ = 50
DISPLAY_SCREEN_WIDTH  = 32
DISPLAY_SCREEN_HEIGHT = 30

BUTTON_HOLD_TIME = DISPLAY_REFRESH_RATE_HZ / 2

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


; oam offsets are not same as tile indexes
OAM_OFFSET_CURSOR_SMALL = $00       ; 1 sprite (4 bytes)
OAM_OFFSET_CURSOR_NORMAL = $04      ; 1 sprite (4 bytes)
OAM_OFFSET_CURSOR_BIG = $14         ; 3 sprites (12 bytes), top-left, top, left
OAM_OFFSET_SMILEY = $24             ; 1 sprite (4 bytes) 

OAM_OFFSET_CURSOR_BIG_TOP_LEFT      = $00
OAM_OFFSET_CURSOR_BIG_TOP_RIGHT     = $04
OAM_OFFSET_CURSOR_BIG_BOTTOM_LEFT   = $08
OAM_OFFSET_CURSOR_BIG_BOTTOM_RIGHT  = $0C
OAM_OFFSET_CURSOR_BIG_TOP           = $10
OAM_OFFSET_CURSOR_BIG_BOTTOM        = $14
OAM_OFFSET_CURSOR_BIG_LEFT          = $18
OAM_OFFSET_CURSOR_BIG_RIGHT         = $1C

