; Khine
.macro ChangeBrushTileIndex    source_tile
    lda source_tile
    sta player + P_SELECTED_TOOL
.endmacro
; Khine


; Khine
.macro ChangePPUNameTableAddr address_to_change
    lda PPU_STATUS ; reset address latch
    lda #>address_to_change ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<address_to_change ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
.endmacro
; Khine


; Khine
.macro ChangePPUNameTableAddr2 high_byte, low_byte
    lda PPU_STATUS ; reset address latch
    lda #>high_byte ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<low_byte ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
.endmacro
; Khine


; Khine
.macro ChangeToolFlag   tool_to_turn_on
    lda player + P_TOOL_USE_FLAG
    ora tool_to_turn_on
    sta player + P_TOOL_USE_FLAG
.endmacro
; Khine


; BudgetArms
.macro ResetFrameCounterHolder frameCounterHolder
    ; Save register A
    pha 

    lda #$00
    sta frameCounterHolder

    ; Restore register A
    pla 
.endmacro
; BudgetArms


; BudgetArms
.macro GetNametableTileX addr_low
    lda addr_low
    and #PPU_VRAM_MASK_X_POS
.endmacro
; BudgetArms


; BudgetArms
.macro GetNametableTileY addr_lo

    ; Get the 3-bits of addr_lo
    lda addr_lo
    and #PPU_VRAM_MASK_Y_POS_LOW      

    ; bit-shift right: 5–7 to 0–2
    lsr 
    lsr 
    lsr 
    lsr 
    lsr 

    ; save a
    sta fill_temp

    ; Get the 2-bits from addr_high (addr_lo + 1)
    lda addr_lo + 1
    and #PPU_VRAM_MASK_Y_POS_HIGH
    
    ; bit-shift left: 0-1 to 3-5
    asl 
    asl 
    asl 

    ora fill_temp

.endmacro
; BudgetArms


;*****************************************************************
; PPUUpdate: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
;*****************************************************************
.proc PPUUpdate

    lda #$01
    sta nmi_ready

    loop:
        lda nmi_ready
        bne loop

    rts 

.endproc

;*****************************************************************
; PPUOff: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_DATA)
;*****************************************************************
.proc PPUOff

    lda #$02
    sta nmi_ready

    loop:
        lda nmi_ready
        bne loop

    rts 

.endproc


; Khine
.proc InitializeStartMenuCursor
    ldx #$00
    ldy #OAM_BYTE_SIZE_START_MENU_CURSOR
    Loop:
        lda CURSOR_START_MENU, x
        sta oam + OAM_OFFSET_START_MENU_CURSOR, x
        inx
        dey
        bne Loop

    rts
.endproc
; Khine


; Khine
.proc ConfirmStartMenuSelection
    lda oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y

    cmp #START_MENU_1_PLAYER_SELECTION
    bne :+
        lda #OAM_OFFSCREEN
        sta oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y

        lda #01
        sta player_count
        jsr EnterCanvasMode
        rts
    :

    cmp #START_MENU_2_PLAYERS_SELECTION
    bne :+
        lda #OAM_OFFSCREEN
        sta oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y

        lda #02
        sta player_count
        jsr EnterCanvasMode
        rts
    :

    cmp #START_MENU_CONTROLS_SELECTION
    bne :+
        rts
    :
    rts
.endproc
; Khine


; Khine
.proc MoveStartMenuCursorUp
    lda oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y

    cmp #START_MENU_1_PLAYER_SELECTION
    bne :+
        rts
    :

    sec
    sbc #TILE_PIXEL_SIZE * 2
    sta oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y
    rts
.endproc
; Khine


; Khine
.proc MoveStartMenuCursorDown
    lda oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y

    cmp #START_MENU_CONTROLS_SELECTION
    bne :+
        rts
    :

    clc
    adc #TILE_PIXEL_SIZE * 2
    sta oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y
    rts
.endproc
; Khine


; Khine
.proc EnterStartMenuMode

    lda #START_MENU_MODE
    sta current_program_mode

    jsr InitializeStartMenuCursor

    lda #<Start_Menu_Tilemap
    sta abs_address_to_access
    lda #>Start_Menu_Tilemap
    sta abs_address_to_access + 1
    jsr LoadTilemapToNameTable1

    rts
.endproc
; Khine


; Khine
.proc EnterCanvasMode

    lda #CANVAS_MODE
    sta current_program_mode

    lda #UPDATE_ALL_OFF
    sta update_flag

    jsr InitializeEachPlayer

    lda #$00
    sta current_player_index
    Loop_Players:

        jsr LoadPlayerProperties

        jsr InitializeAllPlayers
        ;jsr UpdateCursorPositionFromTilePosition
        jsr InitializeOverlayIndicators
        jsr LoadCursorSprite

        jsr SavePlayerProperties

    inc current_player_index
    lda current_player_index
    cmp player_count
    bne Loop_Players

    Initialize_Shape_Tool_Type:
        lda #SHAPE_TOOL_TYPE_DEFAULT
        sta shape_tool_type

    lda #<Canvas_Tilemap
    sta abs_address_to_access
    lda #>Canvas_Tilemap
    sta abs_address_to_access + 1
    jsr LoadTilemapToNameTable1

    rts
.endproc
; Khine


; Khine
.proc InitializeEachPlayer
    lda #PLAYER_1
    sta player_1_properties + P_INDEX

    lda #PLAYER_2
    sta player_2_properties + P_INDEX

    rts
.endproc
; Khine


; Khine
.proc InitializeAllPlayers
        lda #$02
        sta player + P_SELECTED_COLOR_INDEX

        lda #UPDATE_ALL_OFF
        sta player + P_TOOL_USE_FLAG

        lda #BRUSH_TOOL_SELECTED
        sta player + P_SELECTED_TOOL

        lda #CURSOR_STARTUP_SIZE
        sta player + P_CURSOR_SIZE

        lda #CURSOR_MIN_X
        sta player + P_TILE_X_POS

        lda #CURSOR_MIN_Y
        sta player + P_TILE_Y_POS

    rts

.endproc
; Khine


; Khine
.proc LoadPlayerProperties

    lda current_player_index

    cmp #PLAYER_1
    bne :+
        ldx #$00
        P1_Loop:
            lda player_1_properties, x
            sta player, x
            inx
            cpx #P_PROPERTY_SIZE
            bne P1_Loop
        rts
    :

    cmp #PLAYER_2
    bne :+
        ldx #$00
        P2_Loop:
            lda player_2_properties, x
            sta player, x
            inx
            cpx #P_PROPERTY_SIZE
            bne P2_Loop
        rts
    :

.endproc
; Khine


; Khine
.proc SavePlayerProperties

    lda current_player_index

    cmp #PLAYER_1
    bne :+
        ldx #$00
        P1_Loop:
            lda player, x
            sta player_1_properties, x
            inx
            cpx #P_PROPERTY_SIZE
            bne P1_Loop
        rts
    :

    cmp #PLAYER_2
    bne :+
        ldx #$00
        P2_Loop:
            lda player, x
            sta player_2_properties, x
            inx
            cpx #P_PROPERTY_SIZE
            bne P2_Loop
        rts
    :

.endproc
; Khine


; Khine
.proc ConvertCursorPosToTilePositions
    ; Convert the X and Y coordinates of the cursor to
    ; the tile index storied in 'cursor_tile_position' variable
    ; 2 bytes -> LO + HI bytes

    ; Reset the tile index
    lda #$00
    sta player + P_TILE_ADDR
    sta player + P_TILE_ADDR + 1

    ; A loop that multiplies the Y coordinate
    ; with 32 since each namespace is 32 tiles wide
    ; and then adding the resultant number to the X coordinate
    ; Simple table to index conversion
    ; For example, X: 2, Y: 6 would convert to (6 * 32) + 2 = 194
    clc 
    lda #$00
    ldy player + P_TILE_Y_POS
    beq SkipLoop

    RowLoop:
    adc #DISPLAY_SCREEN_WIDTH
    ; Check for carry bit and then increment the high bit when carry is set
    bcc @SkipHighBitIncrement
        inc player + P_TILE_ADDR + 1
        clc 
    @SkipHighBitIncrement:
    dey
    bne RowLoop

    SkipLoop:
    adc player + P_TILE_X_POS
    ;sta temp_tile_position ; Low bit of the location
    sta player + P_TILE_ADDR

    ; Increment the high bit position if there is a remaining carry flag set
    bcc @SkipHighBitIncrement
        inc player + P_TILE_ADDR + 1 ; High bit of the location
        clc
    @SkipHighBitIncrement:

    ; Add the offset of nametable 1 to the tile index
    lda #<NAME_TABLE_1
    adc	player + P_TILE_ADDR
    sta player + P_TILE_ADDR
    lda #>NAME_TABLE_1
    adc #$00
    adc player + P_TILE_ADDR + 1
    sta player + P_TILE_ADDR + 1

    rts

.endproc
; Khine


; Khine / BudgetArms
.proc MoveCursorUp
    ; Move to left (cursor_y - 8, tile_cursor_y - 1)
    lda player + P_TILE_Y_POS

    cmp #CURSOR_MIN_Y
    bne @Apply_Move
        rts 

    @Apply_Move:
    dec player + P_TILE_Y_POS

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorDown
    ; Move to right (cursor_y + 8, tile_cursor_y + 1)
    lda player + P_TILE_Y_POS
    clc
    adc player + P_CURSOR_SIZE

    cmp #CURSOR_MAX_Y
    bmi @Apply_Move
        rts 

    @Apply_Move:
    inc player + P_TILE_Y_POS

    rts

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorLeft
    ; Move to left (cursor_x - 8, tile_cursor_x - 1)
    lda player + P_TILE_X_POS
    cmp #CURSOR_MIN_X
    bne @Apply_Move
        rts 

    @Apply_Move:
    dec player + P_TILE_X_POS

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorRight
    ; Move to right (cursor_x + 8, tile_cursor_x + 1)
    lda player + P_TILE_X_POS
    clc
    adc player + P_CURSOR_SIZE

    cmp #CURSOR_MAX_X
    bmi @Apply_Move
        rts 

    @Apply_Move:
    inc player + P_TILE_X_POS

    rts 

.endproc
; Khine / BudgetArms


; Khine
.proc CycleCursorSize
    ; Load the brush size and checks if it's already the maximum size
    ; If MAX -> return back to the minimum size
    ; If not -> increment the brush size
    lda player + P_CURSOR_SIZE
    cmp #MAXIMUM_CURSOR_SIZE
    bne @Not_Max
        lda #MINIMUM_CURSOR_SIZE
        sta player + P_CURSOR_SIZE
        jmp Change_Cursor_Sprite 

    @Not_Max:
    inc player + P_CURSOR_SIZE

    clc
    lda player + P_TILE_X_POS
    adc player + P_CURSOR_SIZE
    cmp #DISPLAY_SCREEN_WIDTH
    bcc @No_X_Move_Needed
        dec player + P_TILE_X_POS
    @No_X_Move_Needed:

    clc
    lda player + P_TILE_Y_POS
    adc player + P_CURSOR_SIZE
    cmp #DISPLAY_SCREEN_HEIGHT
    bcc @No_Y_Move_Needed
        dec player + P_TILE_Y_POS

    @No_Y_Move_Needed:

    Change_Cursor_Sprite:
    jsr LoadCursorSprite
    rts

.endproc
; Khine


; BudgetArms
.proc ResetScroll

    lda #%10000000
    sta PPU_CONTROL

    lda PPU_STATUS      ; Reset PPU address latch

    lda scroll_x_position
    sta PPU_SCROLL      ; X scroll
    lda scroll_y_position
    sta PPU_SCROLL      ; Y scroll

    rts 

.endproc
; BudgetArms


; Joren
.proc IncreaseChrTileIndex
    lda player + P_SELECTED_COLOR_INDEX
    clc 
    adc #$01

    ; TODO: use constant
    cmp #$04 ; there are 4 options (including index 0). therefore substracting 4 should always be negative
    bmi Value_Was_Okay ; branch if not negative
        lda #BACKGROUND_TILE_INDEX ; set value back to 0

    Value_Was_Okay:
        sta player + P_SELECTED_COLOR_INDEX

    jsr UpdateColorSelectionOverlayPosition
    rts 

.endproc
; Joren


;Joren
.proc DecreaseChrTileIndex
    lda player + P_SELECTED_COLOR_INDEX
    sec 
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #COLOR_3_TILE_INDEX ; set value back to max index
    ; TODO: USE CONSTANT

    Value_Was_Okay:
        sta player + P_SELECTED_COLOR_INDEX

    jsr UpdateColorSelectionOverlayPosition
    rts 

.endproc
;Joren


; Joren / Khine
.proc IncreaseColorValueForSelectedTile

    ldx player + P_SELECTED_COLOR_INDEX

    lda palette, x
    clc 
    adc #$01
    sta palette, x

    rts 

.endproc
; Joren / Khine


; Joren / Khine
.proc DecreaseColorValueForSelectedTile

    ldx player + P_SELECTED_COLOR_INDEX

    lda palette, x
    sec 
    sbc #$01
    sta palette, x

    rts 

.endproc
; Joren / Khine


; Joren
.proc IncreaseButtonHeldFrameCount
    lda player + P_INPUT_FRAME_COUNT
    clc 
    adc #$01
    cmp #FRAMES_BETWEEN_MOVEMENT
    bne Value_Is_Okay
        lda #$00

    Value_Is_Okay:
    sta player + P_INPUT_FRAME_COUNT

    rts 

.endproc
; Joren


; Joren / Khine
.proc IncreaseToolSelection
    lda player + P_SELECTED_TOOL
    clc 
    adc #$01

    cmp #TOOLS_TOTAL_AMOUNT
    bmi Value_Was_Okay ; branch if not negative

        lda #00 ; set value back to 0

    Value_Was_Okay:
    sta player + P_SELECTED_TOOL

    lda update_flag
    ora #UPDATE_TOOL_TEXT_OVERLAY
    sta update_flag

    jsr UpdateToolSelectionOverlayPosition
    rts 

.endproc
; Joren / Khine


; Joren / Khine
.proc DecreaseToolSelection
    lda player + P_SELECTED_TOOL
    sec 
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #TOOLS_TOTAL_AMOUNT - 1 ; set value back to max index

    Value_Was_Okay:
    sta player + P_SELECTED_TOOL

    lda update_flag
    ora #UPDATE_TOOL_TEXT_OVERLAY
    sta update_flag

    jsr UpdateToolSelectionOverlayPosition
    rts

.endproc
; Joren / Khine


; Khine
.proc RefreshToolTextOverlay
    lda update_flag
    and #UPDATE_TOOL_TEXT_OVERLAY
    bne @Update_Text
        rts
    @Update_Text:
    lda update_flag
    eor #UPDATE_TOOL_TEXT_OVERLAY
    sta update_flag

    ; Clear the tiles before drawing again
    ChangePPUNameTableAddr OVERLAY_TOOL_TEXT_OFFSET
    ldx #$06
    lda #COLOR_1_TILE_INDEX
    @Clear_Loop:
        sta PPU_DATA
        dex
        bne @Clear_Loop

    ; Reset the PPU location after the clear
    ChangePPUNameTableAddr OVERLAY_TOOL_TEXT_OFFSET

    lda player_1_properties + P_SELECTED_TOOL

    cmp #BRUSH_TOOL_SELECTED
    bne :+
        lda #<Brush_Text
        sta abs_address_to_access
        lda #>Brush_Text
        sta abs_address_to_access + 1
        jmp @Change_Text
    :

    cmp #ERASER_TOOL_SELECTED
    bne :+
        lda #<Eraser_Text
        sta abs_address_to_access
        lda #>Eraser_Text
        sta abs_address_to_access + 1
        jmp @Change_Text
    :

    cmp #FILL_TOOL_SELECTED
    bne :+
        lda #<Fill_Text
        sta abs_address_to_access
        lda #>Fill_Text
        sta abs_address_to_access + 1
        jmp @Change_Text
    :
    
    cmp #SHAPE_TOOL_SELECTED
    bne :+
        lda #<Shape_Text
        sta abs_address_to_access
        lda #>Shape_Text
        sta abs_address_to_access + 1
        jmp @Change_Text
    :

    cmp #CLEAR_TOOL_SELECTED
    bne :+
        lda #<Clear_Text
        sta abs_address_to_access
        lda #>Clear_Text
        sta abs_address_to_access + 1
        jmp @Change_Text
    :

    @Change_Text:
    ldy #$00
        @Write_Loop:
        lda (abs_address_to_access), y
        cmp #$00
        bne :+
            rts
        :
        sta PPU_DATA
        iny
        jmp @Write_Loop

    rts
.endproc
; Khine


; Khine
.proc OverwriteAllBackgroundColorIndex

    ldx #$00
    lda palette

    @Loop:
        sta palette, x
        inx 
        inx 
        inx 
        inx 
        cpx #PALETTE_SIZE
        bcc @Loop

    rts 

.endproc
; Khine
