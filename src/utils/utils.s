; Khine
.macro ChangeBrushTileIndex    source_tile
    lda source_tile
    ldx current_player
    sta selected_color_chr_index, x
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
    ldx current_player
    lda tool_use_flag, x
    ora tool_to_turn_on
    sta tool_use_flag, x
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

    ; Reset the tile index
    ldx #$00
    Loop_Controllers:
    cpx #JOYPAD_COUNT
    bne :+
        rts
    :

    lda #$00
    sta temp_tile_position
    sta temp_tile_position + 1

    ; A loop that multiplies the Y coordinate
    ; with 32 since each namespace is 32 tiles wide
    ; and then adding the resultant number to the X coordinate
    ; Simple table to index conversion
    ; For example, X: 2, Y: 6 would convert to (6 * 32) + 2 = 194
    clc 
    lda #$00
    ldy tile_cursor_y, x
    beq SkipLoop

    RowLoop:
    adc #DISPLAY_SCREEN_WIDTH
    ; Check for carry bit and then increment the high bit when carry is set
    bcc @SkipHighBitIncrement
        inc temp_tile_position + 1
        clc 
    @SkipHighBitIncrement:
    dey
    bne RowLoop

    SkipLoop:
    adc tile_cursor_x, x
    sta temp_tile_position ; Low bit of the location

    ; Increment the high bit position if there is a remaining carry flag set
    bcc @SkipHighBitIncrement
        inc temp_tile_position + 1 ; High bit of the location
        clc
    @SkipHighBitIncrement:

    ; Add the offset of nametable 1 to the tile index
    lda #<NAME_TABLE_1
    adc	temp_tile_position
    sta temp_tile_position
    lda #>NAME_TABLE_1
    adc #$00
    adc temp_tile_position + 1
    sta temp_tile_position + 1

    cpx #$00
    beq P1
    P2:
        lda temp_tile_position
        sta p2_cursor_tile_position
        lda temp_tile_position + 1
        sta p2_cursor_tile_position + 1
        jmp End_Loop
    P1:
        lda temp_tile_position
        sta p1_cursor_tile_position
        lda temp_tile_position + 1
        sta p1_cursor_tile_position + 1

    End_Loop:
        inx
        jmp Loop_Controllers

.endproc
; Khine


; Khine / BudgetArms
.proc MoveCursorUp
    ; Move to left (cursor_y - 8, tile_cursor_y - 1)
    ldx current_player
    lda tile_cursor_y, x

    cmp #CURSOR_MIN_Y
    bne @Apply_Move
        rts 

    @Apply_Move:
    sec 
    lda cursor_y, x
    sbc #TILE_PIXEL_SIZE
    sta cursor_y, x

    dec tile_cursor_y, x

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorDown
    ; Move to right (cursor_y + 8, tile_cursor_y + 1)
    ldx current_player
    lda tile_cursor_y, x
    clc
    adc cursor_size, x

    cmp #CURSOR_MAX_Y
    bmi @Apply_Move
        rts 

    @Apply_Move:

    lda cursor_y, x
    clc
    adc #TILE_PIXEL_SIZE
    sta cursor_y, x

    inc tile_cursor_y, x

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorLeft
    ; Move to left (cursor_x - 8, tile_cursor_x - 1)
    ldx current_player
    lda tile_cursor_x, x
    cmp #CURSOR_MIN_X
    bne @Apply_Move
        rts 

    @Apply_Move:

    lda cursor_x, x
    sec
    sbc #TILE_PIXEL_SIZE
    sta cursor_x, x

    dec tile_cursor_x, x

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc MoveCursorRight
    ; Move to right (cursor_x + 8, tile_cursor_x + 1)
    ldx current_player
    lda tile_cursor_x, x
    clc
    adc cursor_size, x

    cmp #CURSOR_MAX_X
    bmi @Apply_Move
        rts 

    @Apply_Move:

    clc 
    lda cursor_x, x
    adc #TILE_PIXEL_SIZE
    sta cursor_x, x

    inc tile_cursor_x, x

    rts 

.endproc
; Khine / BudgetArms


; Khine
.proc CycleCursorSize
    ; Load the brush size and checks if it's already the maximum size
    ; If MAX -> return back to the minimum size
    ; If not -> increment the brush size
    ldx current_player
    lda cursor_size, x
    cmp #MAXIMUM_CURSOR_SIZE
    bne @Not_Max
        lda #MINIMUM_CURSOR_SIZE
        sta cursor_size, x
        jmp Change_Cursor_Sprite 

    @Not_Max:
    inc cursor_size, x

    clc 
    lda tile_cursor_x, x
    adc cursor_size, x
    cmp #DISPLAY_SCREEN_WIDTH
    bcc @No_X_Move_Needed
        dec tile_cursor_x, x
        sec 
        lda cursor_x, x
        sbc #TILE_PIXEL_SIZE
        sta cursor_x, x
    @No_X_Move_Needed:

    clc
    lda tile_cursor_y, x
    adc cursor_size, x
    cmp #DISPLAY_SCREEN_HEIGHT
    bcc @No_Y_Move_Needed
        dec tile_cursor_y, x
        sec
        lda cursor_y, x
        sbc #TILE_PIXEL_SIZE
        sta cursor_y, x

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
    ldx current_player
    lda selected_color_chr_index, x
    clc 
    adc #$01

    ; TODO: use constant
    cmp #$04 ; there are 4 options (including index 0). therefore substracting 4 should always be negative
    bmi Value_Was_Okay ; branch if not negative
        lda #BACKGROUND_TILE_INDEX ; set value back to 0

    Value_Was_Okay:
        sta selected_color_chr_index, x

    jsr UpdateColorSelectionOverlayPosition
    rts 

.endproc
; Joren


;Joren
.proc DecreaseChrTileIndex
    ldx current_player
    lda selected_color_chr_index, x
    sec 
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #COLOR_3_TILE_INDEX ; set value back to max index
    ; TODO: USE CONSTANT

    Value_Was_Okay:
        sta selected_color_chr_index, x

    jsr UpdateColorSelectionOverlayPosition
    rts 

.endproc
;Joren


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
    ldx current_player
    lda frame_count, x
    clc 
    adc #$01
    cmp #FRAMES_BETWEEN_MOVEMENT
    bne Value_Is_Okay
        lda #$00

    Value_Is_Okay:
    sta frame_count, x

    rts 

.endproc
; Joren


; Joren / Khine
.proc IncreaseToolSelection
    ldx current_player
    lda selected_tool, x
    clc 
    adc #$01

    cmp #TOOLS_TOTAL_AMOUNT
    bmi Value_Was_Okay ; branch if not negative

        lda #00 ; set value back to 0

    Value_Was_Okay:
    sta selected_tool, x

    lda update_flag
    ora #UPDATE_TOOL_TEXT_OVERLAY
    sta update_flag

    jsr UpdateToolSelectionOverlayPosition
    rts 

.endproc
; Joren / Khine


; Joren / Khine
.proc DecreaseToolSelection
    ldx current_player
    lda selected_tool, x
    sec 
    sbc #$01

    bpl Value_Was_Okay ; branch if not negative
    lda #TOOLS_TOTAL_AMOUNT - 1 ; set value back to max index

    Value_Was_Okay:
    sta selected_tool, x

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

    lda selected_tool

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
