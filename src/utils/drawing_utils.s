;*****************************************************************
; clear_nametable: clears the entire nametable A ($2000) and its
;   corresponding attribute table on the NES PPU
; 
;   Operation:
;     - Resets the PPU address latch by reading PPU_STATUS
;     - Sets the PPU address to $2000 (start of nametable A)
;     - Writes 0s to all 960 bytes of nametable data (32x30 tiles)
;     - Writes 0s to all 64 bytes of the attribute table
;     - Leaves the PPU ready to receive further data if needed
;*****************************************************************
.proc clear_nametable
    lda PPU_STATUS ; reset address latch
    lda #$20 ; set PPU address to $2000
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

    ; empty nametable A
    lda #0
    ldy #DISPLAY_SCREEN_HEIGHT ; clear 30 rows
    rowloop:
        ldx #DISPLAY_SCREEN_WIDTH ; 32 columns
        columnloop:
            sta PPU_DATA
            dex
            bne columnloop
        dey
        bne rowloop

    ; empty attribute table
    ldx #64 ; attribute table is 64 bytes
    loop:
        sta PPU_DATA
        dex
        bne loop    

    rts
.endproc


; Khine
.proc setup_canvas
    lda PPU_STATUS ; reset address latch
    lda #$20 ; set PPU address to $2000
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

    ; setup nametable 0 with index 1
    lda #$00
    ldy #DISPLAY_SCREEN_HEIGHT ; clear 30 rows
    rowloop:
        ldx #DISPLAY_SCREEN_WIDTH ; 32 columns
        columnloop:
            sta PPU_DATA
            dex
            bne columnloop
        dey
        bne rowloop

    ; setting up palette 0 for all the background tiles
    lda #$00
    ldx #64 ; attribute table is 64 bytes
    loop:
        sta PPU_DATA
        dex
        bne loop

	rts
.endproc
; Khine



; BudgetArms
.proc UpdateCursorPosition

    lda cursor_type

    cmp #CURSOR_TYPE_SMALL
    beq @smallCursor

    cmp #CURSOR_TYPE_NORMAL
    beq @normalCursor

    cmp #CURSOR_TYPE_BIG
    beq @bigCursor

    ; this should never be reached
    rts

    @smallCursor:
        jsr UpdateSmallCursorPosition
        rts

    @normalCursor:
        jsr UpdateNormalCursorPosition
        rts

    @bigCursor:
        jsr UpdateBigCursorPosition
        rts

.endproc


; BudgetArms
.proc UpdateSmallCursorPosition

    ; load cursor_y
    lda cursor_y    

    ; overwrite the Small Cursor's default y-pos with the cursor y-Position 
    ; sta oam + CURSOR_OFFSET_SMALL
    sta oam + CURSOR_OFFSET_SMALL

    ; load cursor_x
    lda cursor_x

    ; overwrite the Small Small Cursor's default x-pos with the cursor x-Position 
    ; sta oam + CURSOR_OFFSET_SMALL + 3  
    sta oam + CURSOR_OFFSET_SMALL + 3

    rts

.endproc

; BudgetArms
.proc UpdateNormalCursorPosition
    lda cursor_y
    sta oam + CURSOR_OFFSET_NORMAL

    lda cursor_x
    sta oam + CURSOR_OFFSET_NORMAL + 3

    rts

.endproc

; BudgetArms
.proc UpdateBigCursorPosition
    ldx cursor_y

    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_LEFT
    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_RIGHT

    ; top is stored on cursor_y - 1
    dex
    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_TOP

    ; bottom is stored on cursor_y + 1
    inx
    inx
    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_BOTTOM

    ldx cursor_x
    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_TOP     + 3
    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_BOTTOM  + 3

    ; left is stored on cursor_x - 1
    dex
    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_LEFT    + 3

    ; right is stored on cursor_x + 1
    inx
    inx
    stx oam + CURSOR_OFFSET_BIG + CURSOR_OFFSET_BIG_RIGHT   + 3

    rts

.endproc


; BudgetArms
.proc UpdateSmileyPosition
    lda cursor_y 
    sta oam + SMILEY_OFFSET

    lda cursor_x
    sta oam + SMILEY_OFFSET + 3

    rts

.endproc

; Jeronimas
.proc UpdateOverlayCursorPosition
    ; Convert cursor_x to three decimal digits
    lda cursor_x
    ldx #100
    jsr DivideByX ; hundreds in A, remainder in X
    sta cursor_x_digits      ; hundreds digit
    txa
    ldx #10
    jsr DivideByX ; tens in A, ones in X
    sta cursor_x_digits + 1  ; tens digit
    stx cursor_x_digits + 2  ; ones digit
    
    ; Convert cursor_y to three decimal digits
    lda cursor_y
    ldx #100
    jsr DivideByX
    sta cursor_y_digits      ; hundreds digit
    txa
    ldx #10
    jsr DivideByX
    sta cursor_y_digits + 1  ; tens digit
    stx cursor_y_digits + 2  ; ones digit
    
    ; Write overlay to nametable
    ; Calculate nametable address: $2000 + (Y * 32) + X
    ; For top-left, this is $2000 + 0 = $2000
    lda PPU_STATUS           ; reset address latch
    lda #>OVERLAY_NAMETABLE_ADDR
    sta PPU_ADDR
    lda #<OVERLAY_NAMETABLE_ADDR
    sta PPU_ADDR
    
    ; Write "X: " label
    lda #OVERLAY_TILE_CURSOR_X_LABEL
    sta PPU_DATA
    lda #OVERLAY_TILE_COLON
    sta PPU_DATA
    lda #OVERLAY_TILE_SPACE
    sta PPU_DATA
    
    ; Write X digits (3 decimal digits)
    lda cursor_x_digits
    clc
    adc #OVERLAY_TILE_DIGIT_0
    sta PPU_DATA
    lda cursor_x_digits + 1
    clc
    adc #OVERLAY_TILE_DIGIT_0
    sta PPU_DATA
    lda cursor_x_digits + 2
    clc
    adc #OVERLAY_TILE_DIGIT_0
    sta PPU_DATA
    
    ; Write " Y: " label
    lda #OVERLAY_TILE_SPACE
    sta PPU_DATA
    lda #OVERLAY_TILE_CURSOR_Y_LABEL
    sta PPU_DATA
    lda #OVERLAY_TILE_COLON
    sta PPU_DATA
    lda #OVERLAY_TILE_SPACE
    sta PPU_DATA
    
    ; Write Y digits (3 decimal digits)
    lda cursor_y_digits
    clc
    adc #OVERLAY_TILE_DIGIT_0
    sta PPU_DATA
    lda cursor_y_digits + 1
    clc
    adc #OVERLAY_TILE_DIGIT_0
    sta PPU_DATA
    lda cursor_y_digits + 2
    clc
    adc #OVERLAY_TILE_DIGIT_0
    sta PPU_DATA
    
    rts
.endproc

; Jeronimas
; Simple division: divides A by X, returns quotient in A, remainder in X
.proc DivideByX
    ; Input: A = dividend, X = divisor
    ; Output: A = quotient, X = remainder

    stx divide_by_x_divisor   ; Store divisor in zero page
    ldy #0                   ; Y will hold quotient

Divide_Loop:
    cmp divide_by_x_divisor   ; Compare A with divisor
    bcc Divide_Done           ; If A < divisor, we're done
    sbc divide_by_x_divisor   ; Subtract divisor from A
    iny                      ; Increment quotient
    jmp Divide_Loop

Divide_Done:
    tya                    ; Move quotient from Y to A
    tax                    ; Move remainder to X (A already holds remainder after loop)
    rts
.endproc