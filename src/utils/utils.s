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
.proc convert_cursor_coordinates_to_cursor_tile_position
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
    bne @ApplyMove
        rts
    @ApplyMove:
    sec
    lda cursor_y
    sbc #$08
    sta cursor_y

    dec tile_cursor_y
    rts
.endproc
; Khine


; Khine
.proc MoveCursorDown
    ; Move to right (cursor_y + 8, tile_cursor_y + 1)
    lda tile_cursor_y
    cmp #DISPLAY_SCREEN_HEIGHT - 1
    bmi @ApplyMove
        rts
    @ApplyMove:
    clc
    lda cursor_y
    adc #$08
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
    bne @ApplyMove
        rts
    @ApplyMove:
    sec
    lda cursor_x
    sbc #$08
    sta cursor_x

    dec tile_cursor_x
    rts
.endproc
; Khine


; Khine
.proc MoveCursorRight
    ; Move to right (cursor_x + 8, tile_cursor_x + 1)
    lda tile_cursor_x
    cmp #DISPLAY_SCREEN_WIDTH - 1
    bmi @ApplyMove
        rts
    @ApplyMove:
    clc
    lda cursor_x
    adc #$08
    sta cursor_x

    inc tile_cursor_x
    rts
.endproc
; Khine