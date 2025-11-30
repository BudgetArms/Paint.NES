;file for all drawing functions


; BudgetArms
.proc LoadCursor

    lda cursor_type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor

    ;this should never be reached
    rts 

    Small_Cursor:
        jsr LoadSmallCursor
        rts 

    Normal_Cursor:
        jsr LoadNormalCursor
        rts 

    Big_Cursor:
        jsr LoadBigCursor
        rts 

    ; this should never be reached
    rts 

.endproc


; BudgetArms
.proc LoadSmallCursor

    lda cursor_small_direction

    cmp #DIR_CURSOR_SMALL_TOP_LEFT
    beq DrawTopLeft

    cmp #DIR_CURSOR_SMALL_TOP_RIGHT
    beq DrawTopRight

    cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
    beq DrawBottomLeft

    cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
    beq DrawBottomRight

    ; this should never be reached
    rts 

    ; set x, it's the offset from CURSOR_SMALL_CURSOR to it's current sprite

    DrawTopLeft:
        ldx #DIR_CURSOR_SMALL_TOP_LEFT
        jmp DoneSettingStartAddress

    DrawTopRight:
        ldx #DIR_CURSOR_SMALL_TOP_RIGHT
        jmp DoneSettingStartAddress

    DrawBottomLeft:
        ldx #DIR_CURSOR_SMALL_BOTTOM_LEFT
        jmp DoneSettingStartAddress

    DrawBottomRight:
        ldx #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        jmp DoneSettingStartAddress


    DoneSettingStartAddress:

        ldy #$00

        @Loop: 
            lda CURSOR_SMALL_DATA, X
            sta oam + OAM_OFFSET_CURSOR_SMALL, Y

            inx     ; so the next sprite get read/written
            iny     ; to keep track of the Nth byte we are reading

            cpy #OAM_SIZE_CURSOR_SMALL
            bne @Loop   ; loop until the whole sprite is loaded in

        rts 

.endproc


; BudgetArms
.proc LoadNormalCursor

    ldx #$00

    @Loop:
        lda CURSOR_NORMAL_DATA, X
        sta oam + OAM_OFFSET_CURSOR_NORMAL, X
        inx

        cpx #OAM_SIZE_CURSOR_NORMAL
        bne @Loop  ; loop until all bytes are loaded

    rts

.endproc


; BudgetArms
.proc LoadBigCursor

    ldx #$00

    @Loop:
        lda CURSOR_BIG_DATA, X
        sta oam + OAM_OFFSET_CURSOR_BIG, X
        inx 

        cpx #OAM_SIZE_CURSOR_BIG
        bne @Loop  ; loop until all bytes are loaded

    rts 

.endproc


; Khine/BudgetArms
.proc draw_brush
    ; Check if the PAD_A has been pressed
    ; This is not checked in the `input_utils.s` because this can run into issues with
    ; the program updating the PPU even though PPU has not finished drawing on the screen
    ; not waiting for the VBLANK
    lda tool_use_attr
    and #BRUSH_TOOL_ON
    bne @Use_Brush
        rts
    @Use_Brush:
    lda tool_use_attr
    eor #BRUSH_TOOL_ON
    sta tool_use_attr

    ; Store the tile position in a different var
    ; This is done so that the cursor position can stay on the original spot
    ; after drawing has completed.
    lda cursor_tile_position
    sta drawing_tile_position
    lda cursor_tile_position + 1
    sta drawing_tile_position + 1

    ; square brush
    ldy #$00
    @column_loop:
        lda PPU_STATUS ; reset address latch
        lda drawing_tile_position + 1 ; High bit of the location
        sta PPU_ADDR
        lda drawing_tile_position ; Low bit of the location
        sta PPU_ADDR

        ldx #$00
        ;lda brush_tile_index ; Color index of the tile
        lda selected_color_chrIndex
        @row_loop:
            sta PPU_DATA
            inx
            cpx brush_size
            bne @row_loop
        clc
        lda drawing_tile_position
        adc #32
        sta drawing_tile_position
        lda drawing_tile_position + 1
        adc #$00
        sta drawing_tile_position + 1
        iny
        cpy brush_size
        bne @column_loop
    rts
.endproc
; Khine
