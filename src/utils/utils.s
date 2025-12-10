; Khine
.macro ChangeBrushTileIndex    source_tile
    lda source_tile
    sta selected_color_chr_index
.endmacro
; Khine


; BudgetArms
.macro ChangeBrushTileIndexFromA
    sta selected_color_chr_index
.endmacro
; BudgetArms


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
; Khine


; Khine / BudgetArms
.proc MoveCursorUp
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

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorDown
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

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorLeft
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

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorRight
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


; BudgetArms / Jeronimas
.proc ResetScroll 

    ; Set nametable based on scroll position
    lda scroll_y_position
    cmp #$80
    bcc @UseNametable0
        lda #%10001000  ; Nametable 2
        jmp @SetControl
    @UseNametable0:
        lda #%10000000  ; Nametable 0
    @SetControl:
    sta PPU_CONTROL

    lda PPU_STATUS      ; Reset PPU address latch

    lda scroll_x_position
    sta PPU_SCROLL      ; X scroll
    lda scroll_y_position
    sta PPU_SCROLL      ; Y scroll

    rts 

.endproc
; BudgetArms / Jeronimas


; Joren
.proc IncreaseChrTileIndex

    lda selected_color_chr_index
    clc 
    adc #$01

    ; TODO: use constant
    cmp #$04 ; there are 4 options (including index 0). therefore substracting 4 should always be negative
    bmi Value_Was_Okay ; branch if not negative
        lda #00 ; set value back to 0

    Value_Was_Okay:
    ChangeBrushTileIndexFromA

    rts 

.endproc
; Joren


;Joren
.proc DecreaseChrTileIndex

    lda selected_color_chr_index
    sec 
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #03 ; set value back to max index
    ; TODO: USE CONSTANT

    Value_Was_Okay:
    ChangeBrushTileIndexFromA

    rts 

.endproc
;Joren


; Joren
.proc InitializeColorSelectionOverlay

    ; FIRST tile = background tile
    ChangePPUNameTableAddr FIRST_COLOR_ONSCREEN_ADRESS
    lda #FIRST_COLOR_TILE_INDEX
    sta PPU_DATA

    ; SECOND tile
    ChangePPUNameTableAddr SECOND_COLOR_ONSCREEN_ADRESS
    lda #SECOND_COLOR_TILE_INDEX
    sta PPU_DATA

    ; THIRD tile
    ChangePPUNameTableAddr THIRD_COLOR_ONSCREEN_ADRESS
    lda #THIRD_COLOR_TILE_INDEX
    sta PPU_DATA

    ; FOURTH tile
    ChangePPUNameTableAddr FOURTH_COLOR_ONSCREEN_ADRESS
    lda #FOURTH_COLOR_TILE_INDEX
    sta PPU_DATA

    rts 

.endproc
; Joren


; Joren
.proc InitializeToolSelectionOverlay

    ; FIRST tile = brush tool
    ChangePPUNameTableAddr BRUSH_TOOL_ONSCREEN_ADRESS
    lda #BRUSH_ICON_TILE_INDEX
    sta PPU_DATA

    ; SECOND tile = eraser tool
    ChangePPUNameTableAddr ERASER_TOOL_ONSCREEN_ADRESS
    lda #ERASER_ICON_TILE_INDEX
    sta PPU_DATA

    ; THIRD tile = fill tool
    ChangePPUNameTableAddr FILL_TOOL_ONSCREEN_ADRESS
    lda #FILL_ICON_TILE_INDEX
    sta PPU_DATA

    ; TODO: Add shape tool

    ; FOURTH tile = clear tool
    ChangePPUNameTableAddr CLEAR_TOOL_ONSCREEN_ADRESS
    lda #CLEAR_ICON_TILE_INDEX
    sta PPU_DATA

    rts 

.endproc
;Joren


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


.proc UpdateColorSelectionOverlay
    ; SELECTED tile
    lda #$20 ; same as all previous ones
    sta PPU_ADDR
    
    lda selected_color_chr_index
    clc 
    adc #<FIRST_COLOR_ONSCREEN_ADRESS
    sta PPU_ADDR

    lda selected_color_chr_index
    sta PPU_DATA

    rts 

.endproc


; Joren
.proc UpdateToolSelectionOverlay

    ; SELECTED tile
    lda #$20 ; > takes highbyte of 16 bit value
    sta PPU_ADDR

    lda #<BRUSH_TOOL_ONSCREEN_ADRESS ; < takes lowbyte of 16 bit value
    clc 
    adc selected_tool
    clc 
    adc selected_tool
    sta PPU_ADDR

    lda selected_tool
    clc 
    adc #BRUSH_ICON_TILE_INDEX
    clc 
    adc #$10 ; +16 = +1 row on chr file
    sta PPU_DATA

    rts 

.endproc
; Joren


; Joren
.proc IncreaseColorValueForSelectedTile
    
    ldx selected_color_chr_index

    lda palette, x
    clc 
    adc #$01
    sta palette, x

    rts 

.endproc
; Joren


; Joren
.proc DecreaseColorValueForSelectedTile

    ldx selected_color_chr_index
    lda palette, x
    sec 
    sbc #$01
    sta palette, x

    rts 

.endproc
; Joren


; Joren
.proc IncreaseButtonHeldFrameCount

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
; Joren


; Joren
.proc IncreaseToolSelection

    lda selected_tool
    clc 
    adc #$01

    cmp #TOOLS_TOTAL_AMOUNT
    bmi Value_Was_Okay ; branch if not negative

        lda #00 ; set value back to 0

    Value_Was_Okay:
    sta selected_tool

    rts 

.endproc
; Joren


; Joren
.proc DecreaseToolSelection

    ; Code to slow input registration down
    lda selected_tool
    sec 
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #TOOLS_TOTAL_AMOUNT - 1 ; set value back to max index

    Value_Was_Okay:
    sta selected_tool

    rts 

.endproc
; Joren
