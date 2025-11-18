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
.proc LoadSmileyFace
    ldx #$00

    @Loop:
        lda SMILEY_DATA, X      ; load byte from smiley data
        sta oam+4, X              ; also store in OAM memory for rendering   
        inx                     ; increment index (next byte)

        ; Each Sprite is 4 bytes, we have one sprite
        ; 4 (byte, 1 sprite) * 1 (amount of sprites in the big sprite) = 4
        cpx #$04                ; Loading the smiley face is 4 bytes
        bne @Loop  ; loop until all bytes are loaded

    ; Now all the smiley face data is loaded into SmileyRam
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
    lda tile_index
    sta temp_swap
    lda tile_index + 1
    sta temp_swap + 1

    ; square brush
    ldy #$00
    @column_loop:

    lda PPU_STATUS ; reset address latch
        lda tile_index + 1 ; High bit of the location
        sta PPU_ADDR
        lda tile_index ; Low bit of the location
        sta PPU_ADDR

    ldx #$00
    lda arguments + 2 ; Color index of the tile
    @row_loop:
        sta PPU_DATA
        inx
        cpx arguments + 3
        bne @row_loop
    clc
    lda tile_index
    adc #32
    sta tile_index
    lda tile_index + 1
    adc #$00
    sta tile_index + 1
    iny
    cpy arguments + 3
    bne @column_loop

    lda temp_swap
    sta tile_index
    lda temp_swap + 1
    sta tile_index + 1
    rts
.endproc
; Khine
