;file for all drawing functions


; BudgetArms
.proc LoadCursor

    lda cursor_type

    cmp #TYPE_CURSOR_SMALL
    beq @smallCursor

    cmp #TYPE_CURSOR_NORMAL
    beq @normalCursor

    cmp #TYPE_CURSOR_BIG
    beq @bigCursor

    ;this should never be reached
    rts 

    @smallCursor:
        ; Hide normal and big cursors
        lda #$FF
        sta oam + OAM_OFFSET_CURSOR_NORMAL
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_LEFT
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_TOP
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_RIGHT
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_BOTTOM

        jsr LoadSmallCursor
        rts

    @normalCursor:
        ; Hide normal and big cursors
        lda #$FF
        sta oam + OAM_OFFSET_CURSOR_SMALL
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_LEFT
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_TOP
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_RIGHT
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_OFFSET_CURSOR_BIG_BOTTOM

        jsr LoadNormalCursor
        rts

    @bigCursor:
        ; Hide normal and big cursors
        lda #$FF
        sta oam + OAM_OFFSET_CURSOR_SMALL
        sta oam + OAM_OFFSET_CURSOR_NORMAL

        jsr LoadBigCursor
        rts

.endproc


; BudgetArms
.proc LoadSmallCursor

    lda cursor_small_direction

    cmp #DIR_CURSOR_SMALL_TOP_LEFT
    beq @DrawTopLeft

    cmp #DIR_CURSOR_SMALL_TOP_RIGHT
    beq @DrawTopRight

    cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
    beq @DrawBottomLeft

    cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
    beq @DrawBottomRight

    ; this should never be reached
    rts

    ; set x, it's the offset from CURSOR_SMALL_CURSOR to it's current sprite

    @DrawTopLeft:
        ldx #DIR_CURSOR_SMALL_TOP_LEFT
        jmp @DoneSettingStartAddress

    @DrawTopRight:
        ldx #DIR_CURSOR_SMALL_TOP_RIGHT
        jmp @DoneSettingStartAddress

    @DrawBottomLeft:
        ldx #DIR_CURSOR_SMALL_BOTTOM_LEFT
        jmp @DoneSettingStartAddress

    @DrawBottomRight:
        ldx #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        jmp @DoneSettingStartAddress


    @DoneSettingStartAddress:

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
        ; lda CURSOR_BIG_DATA, X
        lda CURSOR_BIG_DATA_META, X
        sta oam + OAM_OFFSET_CURSOR_BIG, X
        inx 

        cpx #OAM_SIZE_CURSOR_BIG
        bne @Loop  ; loop until all bytes are loaded

    rts

.endproc


; Khine/BudgetArms
.proc draw_brush
    
    lda cursor_tile_position
    sta temp_swap
    lda cursor_tile_position + 1
    sta temp_swap + 1

    ; square brush
    ldy #$00
    @column_loop:
        lda PPU_STATUS ; reset address latch
        lda cursor_tile_position + 1 ; High bit of the location
        sta PPU_ADDR
        lda cursor_tile_position ; Low bit of the location
        sta PPU_ADDR

        ldx #$00
        lda arguments + 2 ; Color index of the tile
        @row_loop:
            sta PPU_DATA
            inx
            cpx brush_size
            bne @row_loop
        clc
        lda cursor_tile_position
        adc #32
        sta cursor_tile_position
        lda cursor_tile_position + 1
        adc #$00
        sta cursor_tile_position + 1
        iny
        cpy brush_size
        bne @column_loop

    lda temp_swap
    sta cursor_tile_position
    lda temp_swap + 1
    sta cursor_tile_position + 1
    rts 
    
.endproc
; Khine
