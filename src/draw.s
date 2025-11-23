;file for all drawing functions


; BudgetArms
.proc LoadCursor

    ; lda #CURSOR_TYPE_NORMAL   ;test
    ; sta cursor_type           ;test

    lda cursor_type

    cmp #CURSOR_TYPE_SMALL
    beq @smallCursor

    cmp #CURSOR_TYPE_NORMAL
    beq @normalCursor

    cmp #CURSOR_TYPE_BIG
    beq @bigCursor

    ;this should never be reached
    rts

    @smallCursor:
        ; Hide normal and big cursors
        lda #$FF
        sta oam + CURSOR_OFFSET_NORMAL
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_LEFT
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_TOP
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_RIGHT
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_BOTTOM

        jsr LoadSmallCursor
        rts

    @normalCursor:
        ; Hide normal and big cursors
        lda #$FF
        sta oam + CURSOR_OFFSET_SMALL
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_LEFT
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_TOP
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_RIGHT
        sta oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_BOTTOM

        jsr LoadNormalCursor
        rts

    @bigCursor:
        ; Hide normal and big cursors
        lda #$FF
        sta oam + CURSOR_OFFSET_SMALL
        sta oam + CURSOR_OFFSET_NORMAL

        jsr LoadBigCursor
        rts

.endproc


; BudgetArms
.proc LoadSmallCursor

    lda cursor_small_direction

    cmp #CURSOR_SMALL_DIR_TOP_LEFT
    beq @DrawTopLeft

    cmp #CURSOR_SMALL_DIR_TOP_RIGHT
    beq @DrawTopRight

    cmp #CURSOR_SMALL_DIR_BOTTOM_LEFT
    beq @DrawBottomLeft

    cmp #CURSOR_SMALL_DIR_BOTTOM_RIGHT
    beq @DrawBottomRight

    ; this should never be reached
    rts

    ; set x, it's the offset from CURSOR_SMALL_CURSOR to it's current sprite

    @DrawTopLeft:
        ldx #CURSOR_SMALL_DIR_TOP_LEFT
        jmp @DoneSettingStartAddress

    @DrawTopRight:
        ldx #CURSOR_SMALL_DIR_TOP_RIGHT
        jmp @DoneSettingStartAddress

    @DrawBottomLeft:
        ldx #CURSOR_SMALL_DIR_BOTTOM_LEFT
        jmp @DoneSettingStartAddress

    @DrawBottomRight:
        ldx #CURSOR_SMALL_DIR_BOTTOM_RIGHT
        jmp @DoneSettingStartAddress


    @DoneSettingStartAddress:

        ldy #$00

        @Loop: 
            lda CURSOR_SMALL_DATA, X
            sta oam + CURSOR_OFFSET_SMALL, Y

            inx     ; so the next sprite get read/written
            iny     ; to keep track of the Nth byte we are reading

            cpy #$04    ; sprite is 4 bytes
            bne @Loop   ; loop until the whole sprite is loaded in

        rts

.endproc


; BudgetArms
.proc LoadNormalCursor

    ldx #$00

    @Loop:
        lda CURSOR_NORMAL_DATA, X
        sta oam + CURSOR_OFFSET_NORMAL, X
        inx

        ; Each Sprite is 4 bytes, we have one sprite
        ; 4 (byte, 1 sprite) * 1 (amount of sprites in the big sprite) = 4 bytes
        cpx #$04
        bne @Loop  ; loop until all bytes are loaded

    rts

.endproc


; BudgetArms
.proc LoadBigCursor

    ldx #$00

    @Loop:
        lda CURSOR_BIG_DATA, X
        sta oam + CURSOR_OFFSET_BIG, X
        inx

        ; Each Sprite is 4 bytes, we have one sprite
        ; 4 (byte, 1 sprite) * 4 (amount of sprites in the big sprite) = 16 bytes
        cpx #$10
        bne @Loop  ; loop until all bytes are loaded

    rts

.endproc


; Khine
.proc draw_brush
    ; Check if the PAD_A has been pressed
    ; This is not checked in the `input_utils.s` because this can run into issues with
    ; the program updating the PPU even though PPU has not finished drawing on the screen
    ; not waiting for the VBLANK
    lda use_brush
    cmp #USE_BRUSH_ON
    beq @Use_Brush
        rts
    @Use_Brush:
    lda #USE_BRUSH_OFF
    sta use_brush

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
        lda brush_tile_index ; Color index of the tile
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
