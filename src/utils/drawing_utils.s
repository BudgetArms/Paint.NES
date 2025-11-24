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

    cmp #TYPE_CURSOR_SMALL
    beq @smallCursor

    cmp #TYPE_CURSOR_NORMAL
    beq @normalCursor

    cmp #TYPE_CURSOR_BIG
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
    ; sta oam + OAM_OFFSET_CURSOR_SMALL
    sta oam + OAM_OFFSET_CURSOR_SMALL

    ; load cursor_x
    lda cursor_x

    ; overwrite the Small Small Cursor's default x-pos with the cursor x-Position 
    ; sta oam + OAM_OFFSET_CURSOR_SMALL + 3  
    sta oam + OAM_OFFSET_CURSOR_SMALL + 3

    rts 

.endproc

; BudgetArms
.proc UpdateNormalCursorPosition
    lda cursor_y
    sta oam + OAM_OFFSET_CURSOR_NORMAL

    lda cursor_x
    sta oam + OAM_OFFSET_CURSOR_NORMAL + 3

    rts 

.endproc

; BudgetArms
.proc UpdateBigCursorPosition

    ldx #$00
    @Loop:
        ; Increase cursor_y with oam data's y-pos
        lda cursor_y
        adc oam + OAM_OFFSET_CURSOR_BIG, X 
        sta oam + OAM_OFFSET_CURSOR_BIG, X 

        ; Increase cursor_x with oam data's x-pos
        lda cursor_x
        adc oam + OAM_OFFSET_CURSOR_BIG + 3, X 
        sta oam + OAM_OFFSET_CURSOR_BIG + 3, X 

        ; x += 4 bytes, to go to the next sprite
        inx 
        inx 
        inx 
        inx 

        cpx #OAM_SIZE_CURSOR_BIG
        bne @Loop

    rts 

.endproc


; BudgetArms
.proc UpdateSmileyPosition
    lda cursor_y 
    sta oam + OAM_OFFSET_SMILEY

    lda cursor_x
    sta oam + OAM_OFFSET_SMILEY + 3

    rts 

.endproc


; BudgetArms
.proc HideInactiveCursors

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
        ; Hide normal cursor
        lda #$FF
        sta oam + OAM_OFFSET_CURSOR_NORMAL

        jmp HideBigCursor 


    Normal_Cursor:
        ; Hide small cursor
        lda #$FF
        sta oam + OAM_OFFSET_CURSOR_SMALL

        jmp HideBigCursor


    Big_Cursor:
        ; Hide small and normal cursor
        lda #$FF
        sta oam + OAM_OFFSET_CURSOR_SMALL
        sta oam + OAM_OFFSET_CURSOR_NORMAL

        rts 


    HideBigCursor:
        ; Hide big cursor
        ldx #$FF
        @Loop:
            sta oam + OAM_OFFSET_CURSOR_BIG, X
            inx 

            cpx #OAM_SIZE_CURSOR_BIG
            bne @Loop   ; Loop until everything is hidden
        
        rts 


.endproc

