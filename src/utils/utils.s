.macro LoadCurrentPlayerProperty property
    ldx current_player_index
    cpx #PLAYER_1
    bne :+
        lda player_1_properties + property
    :

    cpx #PLAYER_2
    bne :+
        lda player_2_properties + property
    :

    sta player + property
.endmacro


.macro SaveCurrentPlayerProperty property
    lda player + property

    ldx current_player_index
    cpx #PLAYER_1
    bne :+
        sta player_1_properties + property
    :

    cpx #PLAYER_2
    bne :+
        sta player_2_properties + property
    :
.endmacro


.macro SaveValueToPlayerProperty property, value
    lda value

    ldx current_player_index
    cpx #PLAYER_1
    bne :+
        sta player_1_properties + property
    :

    cpx #PLAYER_2
    bne :+
        sta player_2_properties + property
    :
.endmacro


; Khine
.macro ChangeBrushTileIndex    source_tile
    lda source_tile
    sta player + P_SELECTED_TOOL
.endmacro
; Khine


; Khine
.macro TransitionToMode     new_mode
    lda current_program_mode
    sta previous_program_mode
    lda #TRANSITION_MODE
    sta current_program_mode
    lda new_mode
    sta next_program_mode

    jsr StartTransitionAnimation
.endmacro
; Khine


; Khine
.proc StartTransitionAnimation
    lda next_program_mode

    cmp #CANVAS_MODE
    bne :+
        lda #<Canvas_Tilemap
        sta abs_address_to_access
        lda #>Canvas_Tilemap
        sta abs_address_to_access + 1
    :

    cmp #START_MENU_MODE
    bne :+
        lda #<Start_Menu_Tilemap
        sta abs_address_to_access
        lda #>Start_Menu_Tilemap
        sta abs_address_to_access + 1
    :

    lda #<NAME_TABLE_1
    sta current_transition_addr
    lda #>NAME_TABLE_1
    sta current_transition_addr + 1
    rts
.endproc
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

; BudgetArms
.macro ConvertPositionToTilePosition position
    
    ; Convert the X and Y coordinates of the input to
    ; the tile index storied in 'x/y' variable
    ; 2 bytes -> LO + HI bytes
    ; parameters: 0 -> position X, 1 -> position Y

    .local @RowLoop
    .local @SkipLoop
    .local @SkipHighBitIncrement1
    .local @SkipHighBitIncrement2

    ; save registers
    pha 
    txa 
    pha 
    tya 
    pha 

    lda #$00 
    sta tile_position_output
    sta tile_position_output + 1


    ; push (save) position to stack
    lda position
    pha 
    lda position + 1
    pha 

    ; convert position to tile x/y
    lda position
    lsr  
    lsr  
    lsr  
    sta position

    lda position + 1
    lsr  
    lsr  
    lsr  
    sta position + 1


    ; A loop that multiplies the Y coordinate
    ; with 32 since each namespace is 32 tiles wide
    ; and then adding the resultant number to the X coordinate
    ; Simple table to index conversion
    ; For example, X: 2, Y: 6 would convert to (6 * 32) + 2 = 194 => #$C2
    ; then add the nametable

    clc 
    lda #$00
    ; ldx tile_cursor_y
    ldx position + 1
    beq @SkipLoop

    @RowLoop:
        adc #DISPLAY_SCREEN_WIDTH
        ; Check for carry bit and then increment the high bit when carry is set
        bcc @SkipHighBitIncrement1
            inc tile_position_output + 1
            clc 

        @SkipHighBitIncrement1:
        dex 
        bne @RowLoop

    @SkipLoop:

    adc position
    sta tile_position_output ; Low bit of the location

    ; Increment the high bit position if there is a remaining carry flag set
    bcc @SkipHighBitIncrement2
        inc tile_position_output + 1 ; High bit of the location
        clc 

    @SkipHighBitIncrement2:

    ; Add the offset of nametable 1 to the tile index
    lda #<NAME_TABLE_1
    adc	tile_position_output
    sta tile_position_output

    lda #>NAME_TABLE_1
    adc #$00
    adc tile_position_output + 1
    sta tile_position_output + 1
    

    ; restore position
    pla 
    sta position + 1
    pla 
    sta position
    
    ; restore registers
    pla 
    tay 
    pla 
    tax 
    pla 


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
        lda #01
        sta player_count
        ;jsr EnterCanvasMode
        TransitionToMode #CANVAS_MODE
        rts
    :

    cmp #START_MENU_2_PLAYERS_SELECTION
    bne :+
        lda #02
        sta player_count
        ;jsr EnterCanvasMode
        TransitionToMode #CANVAS_MODE
        rts
    :

    cmp #START_MENU_CONTROLS_SELECTION
    bne :+
        ;jsr EnterHelpMenuMode
        TransitionToMode #HELP_MENU_MODE
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
.proc InitializeHelpMenuTilemap
    lda #<Help_Menu_Tilemap
    sta abs_address_to_access
    lda #>Help_Menu_Tilemap
    sta abs_address_to_access + 1
    jsr LoadTilemapToNameTable3

    rts
.endproc
; Khine

; Khine
.proc EnterStartMenuMode
    jsr HideAllSprites

    lda #START_MENU_MODE
    sta current_program_mode

    lda #$00
    sta scroll_y_position

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
.proc EnterHelpMenuMode
    lda #HELP_MENU_MODE
    sta current_program_mode

    lda #HELP_MENU_SCROLL_Y
    sta scroll_y_position

    rts
.endproc
; Khine


; Khine
.proc EnterCanvasMode
    jsr HideAllSprites

    lda #CANVAS_MODE
    sta current_program_mode

    lda #NORMAL_SCROLL_Y
    sta scroll_y_position

    jsr InitializeEachPlayer

    lda #$00
    sta current_player_index
    Loop_Players:

        jsr LoadPlayerProperties

        jsr InitializeAllPlayers
        jsr InitializeOverlayIndicators
        jsr LoadCursorSprite

        jsr SavePlayerProperties

    inc current_player_index
    lda current_player_index
    cmp player_count
    bne Loop_Players

    ; jsr LoadCanvasFromWRAM

    lda #<Canvas_Tilemap
    sta abs_address_to_access
    lda #>Canvas_Tilemap
    sta abs_address_to_access + 1
    jsr LoadTilemapToNameTable1

    rts
.endproc
; Khine


; Khine
.proc ContinuePreviousMode
    lda previous_program_mode
    cmp #START_MENU_MODE
    bne :+
        ;jsr EnterStartMenuMode
        TransitionToMode #START_MENU_MODE
    :

    cmp #CANVAS_MODE
    bne :+
        TransitionToMode #CANVAS_MODE
    :

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

        lda #SHAPE_TOOL_TYPE_DEFAULT
        sta player + P_SHAPE_TOOL_TYPE

        lda #BRUSH_TOOL_SELECTED
        sta player + P_SELECTED_TOOL

        lda #CURSOR_STARTUP_SIZE
        sta player + P_CURSOR_SIZE

        lda #CURSOR_MIN_X + 16
        sta player + P_TILE_X_POS

        lda #CURSOR_MIN_Y + 12
        sta player + P_TILE_Y_POS

        lda #UPDATE_ALL_OFF
        sta player + P_UPDATE_FLAG

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
    cmp #DISPLAY_SCREEN_HEIGHT - 1
    bcc @No_Y_Move_Needed
        dec player + P_TILE_Y_POS

    @No_Y_Move_Needed:

    Change_Cursor_Sprite:
    jsr LoadCursorSprite
    rts

.endproc
; Khine


; Khine / BudgetArms
.proc ChangeShapeToolType

    lda player + P_SHAPE_TOOL_TYPE

    cmp #SHAPE_TOOL_TYPE_RECTANGLE
    bne :+
        ldx #SHAPE_TOOL_TYPE_CIRCLE
        stx player + P_SHAPE_TOOL_TYPE
    :

    cmp #SHAPE_TOOL_TYPE_CIRCLE
    bne :+
        ldx #SHAPE_TOOL_TYPE_RECTANGLE
        stx player + P_SHAPE_TOOL_TYPE
    :

    jsr LoadShapeToolCursorSprite
    rts

.endproc
; Khine / BudgetArms


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


; Khine
.proc UpdateCursorAfterToolSelection
    lda player + P_SELECTED_TOOL
    
    ldx #MINIMUM_CURSOR_SIZE

    cmp #BRUSH_TOOL_SELECTED
    bne :+
        ldx player + P_CURSOR_SIZE
    :

    cmp #ERASER_TOOL_SELECTED
    bne :+
        ldx player + P_CURSOR_SIZE
    :

    stx player + P_CURSOR_SIZE

    jsr LoadCursorSprite

    lda player + P_UPDATE_FLAG
    ora #UPDATE_TOOL_TEXT_OVERLAY
    sta player + P_UPDATE_FLAG

    rts
.endproc
; Khine


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

    jsr UpdateCursorAfterToolSelection
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

    jsr UpdateCursorAfterToolSelection
    jsr UpdateToolSelectionOverlayPosition
    rts

.endproc
; Joren / Khine


; Khine
.proc RefreshToolTextOverlay
    lda player + P_UPDATE_FLAG
    eor #UPDATE_TOOL_TEXT_OVERLAY
    sta player + P_UPDATE_FLAG

    ldx player + P_INDEX

    cpx #PLAYER_1
    bne Not_Player_1
        ChangePPUNameTableAddr OVERLAY_P1_TOOL_TEXT_OFFSET
    Not_Player_1:

    cpx #PLAYER_2
    bne Not_Player_2
        ChangePPUNameTableAddr OVERLAY_P2_TOOL_TEXT_OFFSET
    Not_Player_2:

    ; Clear the tiles before drawing again
    ldx #$06
    lda #COLOR_1_TILE_INDEX
    @Clear_Loop:
        sta PPU_DATA
        dex
        bne @Clear_Loop

    ldx player + P_INDEX

    cpx #PLAYER_1
    bne Not_Player__1
        ChangePPUNameTableAddr OVERLAY_P1_TOOL_TEXT_OFFSET
    Not_Player__1:

    cpx #PLAYER_2
    bne Not_Player__2
        ChangePPUNameTableAddr OVERLAY_P2_TOOL_TEXT_OFFSET
    Not_Player__2:

    lda player + P_SELECTED_TOOL

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
.proc MagicPaletteCopyingSubroutine

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

    lda palette + PALETTE_COLOR_BG
    sta palette + PALETTE_COLOR_BG_COPY_01
    sta palette + PALETTE_COLOR_BG_COPY_02

    lda palette + PALETTE_COLOR_00
    sta palette + PALETTE_COLOR_00_COPY

    lda palette + PALETTE_COLOR_01
    sta palette + PALETTE_COLOR_01_COPY

    lda palette + PALETTE_COLOR_02
    sta palette + PALETTE_COLOR_02_COPY

    rts 

.endproc
; Khine


; Khine
.proc LoadPalette
    lda current_program_mode
    
    cmp #START_MENU_MODE
    bne :+
        ldx #$00
        Start_Menu_Loop:
            lda color_palette_startup_menu, x
            sta palette, x
            inx
            cpx #PALETTE_SIZE
            bcc Start_Menu_Loop
        rts
    :

    cmp #CANVAS_MODE
    bne :+
        ldx #$00
        Canvas_Loop:
            ; lda color_palette_ui_overlay, x
            lda canvas_palette, x
            sta palette, x
            inx
            cpx #PALETTE_SIZE
            bcc Canvas_Loop
        rts
    :

    cmp #HELP_MENU_MODE
    bne :+
        ldx #$00
        Help_Menu_Loop:
            lda color_palette_help_menu, x
            sta palette, x
            inx
            cpx #PALETTE_SIZE
            bcc Help_Menu_Loop
        rts
    :
    rts
.endproc
; Khine


; BudgetArms
.proc LoadCanvasFromWRAM
    
    jsr PPUOff

    ; Store save ptr
    lda #<SAVE_ADDR_START
    sta save_ptr
    
    lda #>SAVE_ADDR_START
    sta save_ptr + 1

    ; Check if canvas is saved or not
    ldy #$00

    lda (save_ptr), y
    cmp #SAVE_HEADER_BYTE_1
    bne Canvas_Is_Not_Saved

    iny 
    lda (save_ptr), y
    cmp #SAVE_HEADER_BYTE_2
    bne Canvas_Is_Not_Saved

    jmp Canvas_Is_Saved

    Canvas_Is_Not_Saved:
        rts 

    Canvas_Is_Saved:


    ; Load color palette   
    ldx #$00
    ldy #SAVE_DATA_START_OFFSET
    Load_Header_Color_Palette:

        lda (save_ptr), y
        sta canvas_palette, x 

        inx 
        iny 

        cpx #SAVE_HEADER_COLOR_VALUE_SIZE
        bne Load_Header_Color_Palette


    Prepare_PPU:

        ; Reset latch
        lda PPU_STATUS

        lda #>CANVAS_START_ADDRESS
        sta PPU_ADDR

        lda #<CANVAS_START_ADDRESS
        sta PPU_ADDR

        ; dummy read


    ; used for offset from save_ptr
    ldy #SAVE_DATA_START_OFFSET

    Load_Colors_Indexes:

        ; load temp byte
        lda (save_ptr), y
        sta save_temp_byte

        ldx #$00

    @Load_Color_Index_Loop:
        
        lda save_temp_byte
        and #SAVE_COLOR_INDEX_LOAD_MASK

        ; rotate right, the save bytes (containing color index)
        ; bit 6-7 to bit 0-1
        rol 
        rol 
        rol 

        ; Wrtite color index to VRAM
        sta PPU_DATA

        ; Shift left twice, to set for next two bits 
        lda save_temp_byte
        asl 
        asl 
        sta save_temp_byte

        ; if byte not fully loaded, keep looping
        inx 
        cpx #SAVE_COLOR_INDEXES_PER_BYTE
        bne @Load_Color_Index_Loop 


    @Load_Color_Index:

        iny 
        cpy #(SAVE_COLOR_DATA_SIZE + SAVE_DATA_START_OFFSET)
        bne Load_Colors_Indexes

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc SaveCanvasToWRAM

    jsr PPUOff

    ; Store save ptr
    lda #<SAVE_ADDR_START
    sta save_ptr
    
    lda #>SAVE_ADDR_START
    sta save_ptr + 1

    ; Save header
    ldy #$00
    lda #SAVE_HEADER_BYTE_1
    sta (save_ptr), y

    iny 
    lda #SAVE_HEADER_BYTE_2
    sta (save_ptr), y


    ; Save color palette   
    ldx #$00
    ldy #SAVE_DATA_START_OFFSET
    Save_Header_Color_Palette:

        ; lda canvas_palette, y 
        ; sta (save_ptr + SAVE_DATA_START_OFFSET), y
        lda canvas_palette, x
        sta (save_ptr), y

        inx 
        iny 

        cpx #SAVE_HEADER_COLOR_VALUE_SIZE
        bne Save_Header_Color_Palette


    Prepare_PPU:    

        ; Reset latch
        lda PPU_STATUS

        lda #>CANVAS_START_ADDRESS
        sta PPU_ADDR

        lda #<CANVAS_START_ADDRESS
        sta PPU_ADDR

        ; dummy read
        lda PPU_DATA

    
    ; used for offset from save_ptr
    ldy #SAVE_DATA_START_OFFSET

    Save_Colors_Indexes:

        ; Clear temp byte
        lda #$00
        sta save_temp_byte

        ldx #$00

    @Save_Color_Index_Loop:
        
        ; left shift the save bytes (containing color index)
        asl save_temp_byte
        asl save_temp_byte

        ; get color index
        lda PPU_DATA
        and  #SAVE_COLOR_INDEX_SAVE_MASK
        
        ; add color index to save_temp_byte
        ora save_temp_byte
        sta save_temp_byte

        ; if byte not fully loaded, keep looping
        inx 
        cpx #SAVE_COLOR_INDEXES_PER_BYTE
        bne @Save_Color_Index_Loop 

    @Save_Color_Index:
        lda save_temp_byte
        sta (save_ptr), y

        iny 
        cpy #(SAVE_COLOR_DATA_SIZE + SAVE_DATA_START_OFFSET)
        bne Save_Colors_Indexes

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc ResetCanvasPalette

    ldx #$00
    Canvas_Loop:
        lda color_palette_ui_overlay, x
        sta canvas_palette, x

        inx 

        cpx #PALETTE_SIZE
        bcc Canvas_Loop

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc UpdateCanvasPalette

    ldx #$00
    Canvas_Loop:
        lda palette, x
        sta canvas_palette, x

        inx 

        cpx #PALETTE_SIZE
        bcc Canvas_Loop

    rts 

.endproc
; BudgetArms

