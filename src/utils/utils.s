; Khine
.macro ChangeBrushTileIndex    source_tile
   lda source_tile
   ;sta brush_tile_index
   sta selected_color_chrIndex
.endmacro
; Khine


; Khine
.macro ChangeToolMode    new_mode
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


; Khine / BudgetArms
.proc MoveCursorUp

; Code to slow down cursor movement
    lda frame_count
    bne DontMoveYet

    ; Move to left (cursor_y - 8, tile_cursor_y - 1)
    lda tile_cursor_y

    cmp #CURSOR_MIN_Y
    bne @Apply_Move
        rts 

    @Apply_Move:
    sec
    lda cursor_y
    sbc #TILE_PIXEL_SIZE
    sta cursor_y

    dec tile_cursor_y

DontMoveYet:
    rts
.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorDown

; Code to slow down cursor movement
    lda frame_count
    bne DontMoveYet
    ; Move to right (cursor_y + 8, tile_cursor_y + 1)
    clc 

    lda tile_cursor_y
    adc brush_size

    cmp #CURSOR_MAX_Y
    bmi @Apply_Move
        rts 

    @Apply_Move:

    clc 
    lda cursor_y
    adc #TILE_PIXEL_SIZE
    sta cursor_y

    inc tile_cursor_y

DontMoveYet:
    rts
    
.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorLeft

; Code to slow down cursor movement
    lda frame_count
    bne DontMoveYet
    ; Move to left (cursor_x - 8, tile_cursor_x - 1)
    lda tile_cursor_x

    cmp #CURSOR_MIN_X
    bne @Apply_Move
        rts 

    @Apply_Move:

    sec 
    lda cursor_x
    sbc #TILE_PIXEL_SIZE
    sta cursor_x

    dec tile_cursor_x

DontMoveYet:
    rts
    
.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorRight

; Code to slow down cursor movement
    lda frame_count
    bne DontMoveYet
    ; Move to right (cursor_x + 8, tile_cursor_x + 1)
    clc 

    lda tile_cursor_x
    adc brush_size

    cmp #CURSOR_MAX_X
    bmi @Apply_Move
        rts 

    @Apply_Move:

    clc 
    lda cursor_x
    adc #TILE_PIXEL_SIZE
    sta cursor_x

    inc tile_cursor_x

DontMoveYet:
    rts

.endproc
; Khine / BudgetArms


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


; Khine / BudgetArms
.proc CycleToolModes

    lda tool_mode
    cmp #DRAW_MODE
    bne @Not_Draw_Mode
        jsr ToggleShapeTool
        rts 

    @Not_Draw_Mode:

    cmp #SHAPE_MODE
    bne @Not_Shape_Mode
        jsr ToggleEraserTool
        rts 

    @Not_Shape_Mode:

    cmp #ERASER_MODE
    bne @Not_Eraser_Mode
        jsr ToggleFillTool
        rts 

    @Not_Eraser_Mode:

    cmp #FILL_MODE
    bne @Not_Fill_Mode
        jsr ToggleDrawTool
        rts 

    @Not_Fill_Mode:

    rts 
.endproc
; Khine / BudgetArms


; BudgetArms
.proc ToggleShapeTool
    ChangeBrushTileIndex drawing_color_tile_index
    ChangeToolMode #SHAPE_MODE
    rts 
.endproc
; BudgetArms


; Khine
.proc ToggleEraserTool
    ; ChangeBrushTileIndex #BACKGROUND_TILE
    ; ChangeToolMode #ERASER_MODE
    ; rts 
    lda #$00
    sta selected_color_chrIndex
    ;ChangeBrushTileIndex #BACKGROUND_TILE
    ;ChangeCanvasMode #ERASER_MODE
    rts
.endproc
; Khine


; BudgetArms
.proc ToggleFillTool
    ChangeBrushTileIndex drawing_color_tile_index
    ChangeToolMode #FILL_MODE
    rts 
.endproc
; BudgetArms


; Khine
.proc ToggleDrawTool
    ; ChangeBrushTileIndex drawing_color_tile_index
    ; ChangeToolMode #DRAW_MODE
    ; rts 
    ;ChangeBrushTileIndex drawing_color_tile_index
    ;ChangeBrushTileIndex chrTileIndex
    ;ChangeBrushTileIndex selected_color_chrIndex
    ;ChangeCanvasMode #DRAW_MODE
    rts
.endproc
; Khine


; Khine
;.proc CycleBrushColor
;    lda drawing_color_tile_index
;    cmp #COLOR_TILE_END_INDEX
;    bne @Not_End
;        lda #COLOR_TILE_START_INDEX
;        sta drawing_color_tile_index
;        sta brush_tile_index
;        rts
;    @Not_End:
;    inc drawing_color_tile_index
;    inc brush_tile_index
;    rts
;.endproc
; Khine


; Khine / BudgetArms
.proc CycleCanvasModes
; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet

    ; Cycle between canvas mode and selection menu mode
    lda scroll_y_position
    cmp #CANVAS_MODE
    bne @Not_Canvas_Mode

        ; In selection menu mode
        lda #SELECTION_MENU_MODE
        sta scroll_y_position

        ; Check what tool mode
        lda tool_mode

        cmp #DRAW_MODE
        bne @Not_Draw_Mode
            lda #SELECTION_MENU_0_DRAW
            jmp @End

        @Not_Draw_Mode:

        cmp #SHAPE_MODE
        bne @Not_Shape_Mode
            lda #SELECTION_MENU_1_SHAPE
            jmp @End

        @Not_Shape_Mode:

        cmp #ERASER_MODE
        bne @Not_Eraser_Mode
            lda #SELECTION_MENU_2_ERASER
            jmp @End

        @Not_Eraser_Mode:

        cmp #FILL_MODE
        bne @Not_Fill_Mode
            lda #SELECTION_MENU_3_FILL
            jmp @End

        @Not_Fill_Mode:

        @End:
        ;lda tool_mode
        ;cmp #DRAW_MODE
        ;bne @Not_Draw_Mode
        ;    lda #SELECTION_MENU_0_DRAW
        ; @Not_Draw_Mode:
        ;cmp #ERASER_MODE
        ;bne @Not_Eraser_Mode
        ;    lda #SELECTION_MENU_1_ERASER
        ; @Not_Eraser_Mode:
        sta oam + SELECTION_STAR_OFFSET + OAM_Y
        rts 

    @Not_Canvas_Mode:
    lda #CANVAS_MODE
    sta scroll_y_position
    lda #OAM_OFFSCREEN
    sta oam + SELECTION_STAR_OFFSET + OAM_Y

DontRegisterYet:
    rts

.endproc
; Khine / BudgetArms


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

    cmp #SELECTION_MENU_4_CLEAR
    bne @Not_In_End_Pos
        rts 

    @Not_In_End_Pos:

    clc 
    adc #TILE_PIXEL_SIZE
    sta oam + SELECTION_STAR_OFFSET + OAM_Y
    rts 

.endproc
; Khine


; Khine / BudgetArms
.proc SelectTool

    lda oam + SELECTION_STAR_OFFSET + OAM_Y

    cmp #SELECTION_MENU_0_DRAW
    bne @Not_On_Draw
        jsr ToggleDrawTool
        rts 

    @Not_On_Draw:

    cmp #SELECTION_MENU_1_SHAPE
    bne @Not_On_Shape
        jsr ToggleShapeTool
        rts 

    @Not_On_Shape:

    cmp #SELECTION_MENU_2_ERASER
    bne @Not_On_Eraser
        jsr ToggleEraserTool
        rts 

    @Not_On_Eraser:

    cmp #SELECTION_MENU_3_FILL
    bne @Not_On_Fill
        jsr ToggleFillTool
        rts 

    @Not_On_Fill:

    cmp #SELECTION_MENU_4_CLEAR
    bne @Not_On_Clear_Canvas
        ChangeToolAttr #CLEAR_CANVAS_TOOL_ON
        rts 

    @Not_On_Clear_Canvas:

    rts 
.endproc
; Khine / BudgetArms

; Jeronimas 
;*********************************************************
; PlaySfx: Play a sound effect
; Input: A = sound effect index to play
; Uses: sfx_channel variable for the channel to play on
; Preserves: X, Y registers
;*********************************************************
.proc PlaySfx
    sta sfx_temp + 9
    tya
    pha
    txa
    pha
    
    lda sfx_temp + 9
    ; Select channel based on sound effect index
    ; Bird (0) = square (CH0), Splash (1) = noise (CH1)
    tax  ; Use sound index as channel selector
    and #$01
    beq @ch0
    ldx #FAMISTUDIO_SFX_CH1
    jmp @play
@ch0:
    ldx #FAMISTUDIO_SFX_CH0
@play:
    lda sfx_temp + 9
    jsr famistudio_sfx_play
    
    pla
    tax
    pla
    tay
    rts
.endproc
; Jeronimas

; BudgetArms / Joren
.proc IncreaseColorPaletteIndex

    lda newPaletteColor
    clc 
    adc #$01
    sta newPaletteColor

    ;ldx selected_color_chrIndex
    ;lda newColorValueForSelectedTile
    ;sta four_color_values, x

    rts 

.endproc

; BudgetArms / Joren
;.proc DecreaseColorPaletteIndex
;
    ;lda newPaletteColor
    ;sec 
    ;sbc #$01
    ;sta newPaletteColor
;
    ;rts 
;
;.endproc

; BudgetArms / Joren
;.proc LoadColorPalette
;
    ;lda #$3F        ;high byte of 16-bit PPU address
    ;sta PPU_ADDR    ;write to PPU
    ;lda #$02        ;low byte of 16-bit PPU address
    ;sta PPU_ADDR    ;write to PPU
;
    ;lda newPaletteColor ;load collorpalette value
    ;sta PPU_DATA        ;write to PPU data register
;
    ;rts 
;
;.endproc


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




;Joren
; .proc IncreaseColorPalleteIndex
; ; Code to slow input registration down
    ; lda frame_count
    ; bne DontRegisterYet
; 
    ; ;ldx chrTileIndex
    ; ;ldx selected_color_chrIndex
    ; ;lda four_color_values, X
    ; lda newColorValueForSelectedTile
    ; clc
    ; adc #$01
    ; ;sta four_color_values, X
    ; sta newColorValueForSelectedTile
; 
    ; ;sta palette, X
; 
; 
; ;remove{
    ; ;lda newPalleteColor
    ; ;clc
    ; ;adc #$01
    ; ;sta newPalleteColor
; ;}
; 
    ; DontRegisterYet:
    ; rts
; .endproc
; 
; .proc DecreaseColorPalleteIndex
; ; Code to slow input registration down
    ; lda frame_count
    ; bne DontRegisterYet
; 
    ; ;ldx chrTileIndex
    ; ;ldx selected_color_chrIndex
    ; ;lda four_color_values, X
    ; lda newColorValueForSelectedTile
    ; sec
    ; sbc #$01
    ; ;sta four_color_values, X
    ; sta newColorValueForSelectedTile
;     
    ; ldx selected_color_chrIndex
    ; lda newColorValueForSelectedTile
    ; sta four_color_values, x
; 
    ; ;sta palette, X
; 
    ; ; loop:
    ; ;    lda palette, x
    ; ;    sta PPU_DATA
    ; ;    inx
    ; ;    cpx #32
    ; ;    bcc loop
; 
; 
; 
; ;remove{
    ; ;lda newPalleteColor
    ; ;sec
    ; ;sbc #$01
    ; ;sta newPalleteColor
; ;}
; 
    ; DontRegisterYet:
    ; rts
; .endproc

.proc IncreaseChrTileIndex
; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet

    ;lda chrTileIndex
    lda selected_color_chrIndex
    clc
    adc #$01

    cmp #$04 ; there are 4 options (including index 0). therefore substracting 4 should always be negative
    bmi Value_Was_Okay ; branch if not negative
    lda #00 ; set value back to 0

    Value_Was_Okay:
    ;sta chrTileIndex
    sta selected_color_chrIndex
    ;lda four_color_values, selected_color_chrIndex
    
    ;beq Pencil
    ;Eraser:
    ;    lda #ERASER_MODE
    ;    sta tool_mode
    ;    RTS

    ;Pencil:
    ;    LDA #DRAW_MODE
    ;    sta tool_mode

    DontRegisterYet:
    rts
.endproc

.proc DecreaseChrTileIndex
    ; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet

    ;lda chrTileIndex
    lda selected_color_chrIndex
    sec
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #03 ; set value back to max index

    Value_Was_Okay:
    ;sta chrTileIndex
    sta selected_color_chrIndex

    ;beq Pencil
    ;Eraser:
    ;    lda #ERASER_MODE
    ;    sta tool_mode
    ;    RTS

    ;Pencil:
    ;    LDA #DRAW_MODE
    ;    sta tool_mode

    DontRegisterYet:
    rts
    
.endproc
;Joren

.proc UpdateColorSelectionOverlay
    ; FIRST tile = background tile
    lda #>FIRST_COLOR_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<FIRST_COLOR_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #FIRST_COLOR_TILE_INDEX
    sta PPU_DATA

    ; SECOND tile
    lda #>SECOND_COLOR_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<SECOND_COLOR_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #SECOND_COLOR_TILE_INDEX
    sta PPU_DATA

    ; THIRD tile
    lda #>THIRD_COLOR_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<THIRD_COLOR_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #THIRD_COLOR_TILE_INDEX
    sta PPU_DATA

    ; FOURTH tile
    lda #>FOURTH_COLOR_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<FOURTH_COLOR_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #FOURTH_COLOR_TILE_INDEX
    sta PPU_DATA

    ; SELECTED tile
    lda #$20 ; same as all previous ones
    sta PPU_ADDR
    
    lda selected_color_chrIndex
    CLC
    adc #<FIRST_COLOR_ONSCREEN_ADRESS
    ;lda #<FOURTH_COLOR_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR

    lda selected_color_chrIndex
    sta PPU_DATA
    ;selected_color_chrIndex

    rts
.endproc

.proc IncButtonHeldFrameCount
    lda frame_count
    clc
    adc #$01
    cmp #FRAMES_BETWEEN_MOVEMENT
    bne Value_Is_Okay
        lda #$00

    Value_Is_Okay:
    sta frame_count

    rts

.endproc

.proc IncreaseToolSelection
    ; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet

    lda selected_tool
    clc
    adc #$01

    cmp #$04 ; there are 4 options (including index 0). therefore substracting 4 should always be negative
    bmi Value_Was_Okay ; branch if not negative
    lda #00 ; set value back to 0

    Value_Was_Okay:
    sta selected_tool

    DontRegisterYet:
    rts

.endproc

.proc DecreaseToolSelection
    ; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet

    lda selected_tool
    sec
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #03 ; set value back to max index

    Value_Was_Okay:
    sta selected_tool

    DontRegisterYet:
    rts

.endproc

.proc UpdateToolSelectionOverlay
    ; FIRST tile = pencil tool
    lda #>PENCIL_TOOL_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<PENCIL_TOOL_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #PENCIL_ICON_TILE_INDEX
    sta PPU_DATA

    ; SECOND tile = eraser tool
    lda #>ERASER_TOOL_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<ERASER_TOOL_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #ERASER_ICON_TILE_INDEX
    sta PPU_DATA

    ; THIRD tile = fill tool
    lda #>FILL_TOOL_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<FILL_TOOL_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #FILL_ICON_TILE_INDEX
    sta PPU_DATA

    ; FOURTH tile = clear tool
    lda #>CLEAR_TOOL_ONSCREEN_ADRESS ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<CLEAR_TOOL_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    sta PPU_ADDR
    lda #CLEAR_ICON_TILE_INDEX
    sta PPU_DATA

    ; SELECTED tile
    lda #$20 ; > takes highbyte of 16 bit value
    sta PPU_ADDR
    lda #<PENCIL_TOOL_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    CLC
    adc selected_tool
    CLC
    adc selected_tool
    sta PPU_ADDR
    lda selected_tool
    CLC
    adc #PENCIL_ICON_TILE_INDEX
    clc
    adc #$10 ; +16 = +1 row on chr file
    sta PPU_DATA

    rts

.endproc

.proc UpdateColorValues
    
    

    LDA #$3F ;high byte of 16-bit PPU address
    STA $2006   ;write to PPU
    lda selected_color_chrIndex ;lda chrTileIndex ;low byte of 16-bit PPU address
    STA $2006   ;write to PPU

    ; loop:
        ldx selected_color_chrIndex
        lda four_color_values, x
        STA $2007 ;write to PPU data register
        ;inx
        ;cpx #4
        ;bne loop

    

    ;lda newColorValueForSelectedTile ;load collorpallete value
    ;STA $2007 ;write to PPU data register
    ;Joren

    rts

.endproc



.proc IncreaseColorValueForSelectedTile
    ; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet
    
    ldx selected_color_chrIndex
    lda four_color_values, X
    clc
    adc #$01
    sta four_color_values, X

    DontRegisterYet:
    rts
.endproc

.proc DecreaseColorValueForSelectedTile
    ; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet
    
    ldx selected_color_chrIndex
    lda four_color_values, X
    sec
    sbc #$01
    sta four_color_values, X

    DontRegisterYet:
    rts
.endproc