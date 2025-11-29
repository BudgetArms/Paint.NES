; Khine
.macro ChangeBrushTileIndex    source_tile
    lda source_tile
    sta brush_tile_index
.endmacro
; Khine


; Khine
.macro ChangeCanvasMode    new_mode
    lda new_mode
    sta tool_mode
.endmacro
; Khine


; Khine
.macro ChangeToolAttr   tool_to_turn_on
    lda tool_use_attr
    ora tool_to_turn_on
    sta tool_use_attr
.endmacro
; Khine

;*****************************************************************
; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
;*****************************************************************
.proc ppu_update
    lda #1
    sta nmi_ready
    loop:
        lda nmi_ready
        bne loop
    rts
.endproc

;*****************************************************************
; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_DATA)
;*****************************************************************
.proc ppu_off
    lda #2
    sta nmi_ready
    loop:
        lda nmi_ready
        bne loop
    rts
.endproc


; Khine
.proc ConvertCursorPosToTilePositions
    ; Convert the X and Y coordinates of the cursor to
    ; the tile index storied in 'cursor_tile_position' variable
    ; 2 bytes -> LO + HI bytes
    ; parameters: 0 -> Cursor X, 1 -> Cursor Y

    ; Reset the tile index
    lda #$00
    sta cursor_tile_position
    sta cursor_tile_position + 1

    ; A loop that multiplies the Y coordinate
    ; with 32 since each namespace is 32 tiles wide
    ; and then adding the resultant number to the X coordinate
    ; Simple table to index conversion
    ; For example, X: 2, Y: 6 would convert to (6 * 32) + 2 = 194
    clc
    lda #$00
    ldx tile_cursor_y
    beq SkipLoop
    RowLoop:
    adc #DISPLAY_SCREEN_WIDTH
    ; Check for carry bit and then increment the high bit when carry is set
    bcc @SkipHighBitIncrement
        inc cursor_tile_position + 1
        clc
    @SkipHighBitIncrement:
    dex
    bne RowLoop
    SkipLoop:
    adc tile_cursor_x
    sta cursor_tile_position ; Low bit of the location

    ; Increment the high bit position if there is a remaining carry flag set
    bcc @SkipHighBitIncrement
        inc cursor_tile_position + 1 ; High bit of the location
        clc
    @SkipHighBitIncrement:

    ; Add the offset of nametable 1 to the tile index
    lda #<NAME_TABLE_1
    adc	cursor_tile_position
    sta cursor_tile_position
    lda #>NAME_TABLE_1
    adc #$00
    adc cursor_tile_position + 1
    sta cursor_tile_position + 1
    rts
.endproc


; BudgetArms
.macro ResetFrameCounterHolder frameCounterHolder

    ; save register a
    pha 

    lda #$00
    sta frameCounterHolder

    ; restore register a
    pla 

.endmacro


; Khine
.proc MoveCursorUp
    ; Move to left (cursor_y - 8, tile_cursor_y - 1)
    lda tile_cursor_y
    cmp #$00
    bne @Apply_Move
        rts
    @Apply_Move:
    sec
    lda cursor_y
    sbc #TILE_PIXEL_SIZE
    sta cursor_y

    dec tile_cursor_y
    rts
.endproc
; Khine


; Khine
.proc MoveCursorDown
    ; Move to right (cursor_y + 8, tile_cursor_y + 1)
    clc
    lda tile_cursor_y
    adc brush_size
    cmp #DISPLAY_SCREEN_HEIGHT
    bmi @Apply_Move
        rts
    @Apply_Move:
    clc
    lda cursor_y
    adc #TILE_PIXEL_SIZE
    sta cursor_y

    inc tile_cursor_y
    rts
.endproc
; Khine


; Khine
.proc MoveCursorLeft
    ; Move to left (cursor_x - 8, tile_cursor_x - 1)
    lda tile_cursor_x
    cmp #$00
    bne @Apply_Move
        rts
    @Apply_Move:
    sec
    lda cursor_x
    sbc #TILE_PIXEL_SIZE
    sta cursor_x

    dec tile_cursor_x
    rts
.endproc
; Khine


; Khine
.proc MoveCursorRight
    ; Move to right (cursor_x + 8, tile_cursor_x + 1)
    clc
    lda tile_cursor_x
    adc brush_size
    cmp #DISPLAY_SCREEN_WIDTH
    bmi @Apply_Move
        rts
    @Apply_Move:
    clc
    lda cursor_x
    adc #TILE_PIXEL_SIZE
    sta cursor_x

    inc tile_cursor_x
    rts
.endproc
; Khine


; Khine
.proc CycleBrushSize
    ; Load the brush size and checks if it's already the maximum size
    ; If MAX -> return back to the minimum size
    ; If not -> increment the brush size
    lda brush_size
    cmp #MAXIMUM_BRUSH_SIZE
    bne @Not_Max
        lda #MINIMUM_BRUSH_SIZE
        sta brush_size
        rts
    @Not_Max:
    inc brush_size

    clc
    lda tile_cursor_x
    adc brush_size
    cmp #DISPLAY_SCREEN_WIDTH
    bcc @No_X_Move_Needed
        dec tile_cursor_x
        sec
        lda cursor_x
        sbc #TILE_PIXEL_SIZE
        sta cursor_x
    @No_X_Move_Needed:

    clc
    lda tile_cursor_y
    adc brush_size
    cmp #DISPLAY_SCREEN_HEIGHT
    bcc @No_Y_Move_Needed
        dec tile_cursor_y
        sec
        lda cursor_y
        sbc #TILE_PIXEL_SIZE
        sta cursor_y
    @No_Y_Move_Needed:
    rts
.endproc
; Khine


; Khine
.proc CycleToolModes
    lda tool_mode
    cmp #DRAW_MODE
    bne @Not_Draw_Mode
        jsr ToggleEraserTool
        rts
    @Not_Draw_Mode:
    cmp #ERASER_MODE
    bne @Not_Eraser_Mode
        jsr ToggleDrawTool
        rts
    @Not_Eraser_Mode:
    rts
.endproc
; Khine


; Khine
.proc ToggleEraserTool
    ChangeBrushTileIndex #BACKGROUND_TILE
    ChangeCanvasMode #ERASER_MODE
    rts
.endproc
; Khine


; Khine
.proc ToggleDrawTool
    ChangeBrushTileIndex drawing_color_tile_index
    ChangeCanvasMode #DRAW_MODE
    rts
.endproc
; Khine


; Khine
.proc CycleBrushColor
    lda drawing_color_tile_index
    cmp #COLOR_TILE_END_INDEX
    bne @Not_End
        lda #COLOR_TILE_START_INDEX
        sta drawing_color_tile_index
        sta brush_tile_index
        rts
    @Not_End:
    inc drawing_color_tile_index
    inc brush_tile_index
    rts
.endproc
; Khine


; Khine
.proc CycleCanvasModes
    ; Cycle between canvas mode and selection menu mode
    lda scroll_y_position
    cmp #CANVAS_MODE
    bne @Not_Canvas_Mode
        lda #SELECTION_MENU_MODE
        sta scroll_y_position
        lda tool_mode
        cmp #DRAW_MODE
        bne @Not_Draw_Mode
            lda #SELECTION_MENU_0_DRAW
        @Not_Draw_Mode:
        cmp #ERASER_MODE
        bne @Not_Eraser_Mode
            lda #SELECTION_MENU_1_ERASER
        @Not_Eraser_Mode:
        sta oam + SELECTION_STAR_OFFSET + OAM_Y
        rts
    @Not_Canvas_Mode:
    lda #CANVAS_MODE
    sta scroll_y_position
    lda #OAM_OFFSCREEN
    sta oam + SELECTION_STAR_OFFSET + OAM_Y
    rts
.endproc
; Khine


; Khine
.proc MoveSelectionStarUp
    lda oam + SELECTION_STAR_OFFSET + OAM_Y
    cmp #SELECTION_MENU_0_DRAW
    bne @Not_In_Start_Pos
        rts
    @Not_In_Start_Pos:
    sec
    sbc #TILE_PIXEL_SIZE
    sta oam + SELECTION_STAR_OFFSET + OAM_Y
    rts
.endproc
; Khine


; Khine
.proc MoveSelectionStarDown
    lda oam + SELECTION_STAR_OFFSET + OAM_Y
    cmp #SELECTION_MENU_3_CLEAR
    bne @Not_In_End_Pos
        rts
    @Not_In_End_Pos:
    clc
    adc #TILE_PIXEL_SIZE
    sta oam + SELECTION_STAR_OFFSET + OAM_Y
    rts
.endproc
; Khine


; Khine
.proc SelectTool
    lda oam + SELECTION_STAR_OFFSET + OAM_Y
    cmp #SELECTION_MENU_0_DRAW
    bne @Not_On_Draw
        jsr ToggleDrawTool
        rts
    @Not_On_Draw:
    cmp #SELECTION_MENU_1_ERASER
    bne @Not_On_Eraser
        jsr ToggleEraserTool
        rts
    @Not_On_Eraser:
    cmp #SELECTION_MENU_3_CLEAR
    bne @Not_On_Clear_Canvas
        ChangeToolAttr #CLEAR_CANVAS_TOOL_ON
        jsr ppu_off
        rts
    @Not_On_Clear_Canvas:
    rts
.endproc

; Jeronimas 
;*********************************************************
; PlaySfx: Play a sound effect
; Input: A = sound effect index to play
; Uses: sfx_channel variable for the channel to play on
; Preserves: X, Y registers
;*********************************************************
.proc PlaySfx
    sta temp + 9
    tya
    pha
    txa
    pha
    lda temp + 9
    ldx sfx_channel
    jsr famistudio_sfx_play
    pla
    tax
    pla
    tay
    rts
.endproc