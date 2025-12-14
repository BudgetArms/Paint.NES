; Players
PLAYER_1 = 0
PLAYER_2 = 1

; Player property offsets
P_INDEX                 = 0      ; 1 byte
P_INPUT                 = 1      ; 1 byte
P_INPUT_FRAME_COUNT     = 2      ; 1 byte
P_X_POS                 = 3      ; 1 byte
P_Y_POS                 = 4      ; 1 byte
P_TILE_X_POS            = 5      ; 1 byte
P_TILE_Y_POS            = 6      ; 1 byte
P_CURSOR_SIZE           = 7      ; 1 byte
P_TILE_ADDR             = 8      ; 2 bytes
P_SELECTED_TOOL         = 10     ; 1 byte
P_SELECTED_COLOR_INDEX  = 11     ; 1 byte
P_TOOL_USE_FLAG         = 12     ; 1 byte
P_SHAPE_TOOL_TYPE       = 13     ; 1 byte
P_SHAPE_TOOL_FIRST_SET  = 14     ; 1 byte
P_SHAPE_TOOL_FIRST_POS  = 15     ; 2 bytes
P_SHAPE_TOOL_SECOND_POS = 17     ; 2 bytes
P_UPDATE_FLAG           = 19     ; 1 byte
P_TEXT_TOOL_IN_USE      = 20     ; 1 byte
P_PROPERTY_SIZE         = 21     ; ALWAYS UPDATE THIS AFTER MAKING CHANGES TO THE PROPERTIES


; Players
PLAYER_1_OVERLAY_ATTR = $00000000
PLAYER_2_OVERLAY_ATTR = $00000001