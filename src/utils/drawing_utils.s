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

; Khine
.proc UseClearCanvasTool
    ldx #$00
    Check_Loop:
    stx current_player
    cpx #JOYPAD_COUNT
    bne :+
        rts
    :
    lda tool_use_flag, x
    and #CLEAR_TOOL_ON
    bne @Use_Fill
        inx
        jmp Check_Loop
    @Use_Fill:
    lda tool_use_flag, x
    eor #CLEAR_TOOL_ON
    sta tool_use_flag, x

    jsr PPUOff

    lda PPU_STATUS ; reset address latch
    lda #>CANVAS_START_ADDRESS ; set PPU address to $2000
    sta PPU_ADDR
    lda #<CANVAS_START_ADDRESS
    sta PPU_ADDR

    ; empty nametable A
    lda #BACKGROUND_TILE_INDEX
    ldy #CANVAS_ROWS ; clear 30 rows
    rowloop:
        ldx #CANVAS_COLUMNS ; 32 columns
        columnloop:
            sta PPU_DATA
            dex 
            bne columnloop
        dey 
        bne rowloop

    rts 

.endproc
; Khine


; Khine
.proc SetupCanvas
    ; Main Canvas
    lda PPU_STATUS ; reset address latch
    lda #>NAME_TABLE_1 ; set PPU address to $2000
    sta PPU_ADDR
    lda #<NAME_TABLE_1
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
    ldx #ATTR_TABLE_SIZE ; attribute table is 64 bytes
    loop:
        sta PPU_DATA
        dex 
        bne loop

    rts 

.endproc
; Khine


; BudgetArms
.macro HideCursor oamOffset, oamSize

    ; to make labels work in macro's
    .local Loop

    ; Hide medium cursor
    lda #OAM_OFFSCREEN
    ldx #$00
    Loop:
        sta oam + oamOffset, X
        
        ; Go to next sprite (Y-pos)
        inx 
        inx 
        inx 
        inx 

        cpx #oamSize
        bne Loop   ; Loop until everything is hidden

.endmacro
; BudgetArms


; BudgetArms
.proc UpdateCursorPosition

    lda cursor_type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor

    ; this should never be reached
    rts 

    Small_Cursor:
        jsr UpdateSmallCursorPosition
        rts 

    Normal_Cursor:
        jsr UpdateNormalCursorPosition
        rts 

    Medium_Cursor:
        jsr UpdateMediumCursorPosition
        rts 

    Big_Cursor:
        jsr UpdateBigCursorPosition
        rts 

.endproc
; BudgetArms


; BudgetArms
.proc UpdateSmallCursorPosition

    ; Increase cursor_y with oam data's y-pos
    clc 
    lda cursor_y
    adc oam + OAM_OFFSET_CURSOR_SMALL

    ; subtract A (y pos) by one bc it's draw on the next scanline  
    clc 
    sbc #$00

    ; Store data to OAM
    sta oam + OAM_OFFSET_CURSOR_SMALL

    ; Increase cursor_x with oam data's x-pos
    clc 
    lda cursor_x
    adc oam + OAM_OFFSET_CURSOR_SMALL + OAM_X
    sta oam + OAM_OFFSET_CURSOR_SMALL + OAM_X

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc UpdateNormalCursorPosition

    ; Increase cursor_y with oam data's y-pos
    clc 
    lda cursor_y
    adc oam + OAM_OFFSET_CURSOR_NORMAL

    ; subtract A (y pos) by one bc it's draw on the next scanline  
    clc 
    sbc #$00

    ; Store data to OAM
    sta oam + OAM_OFFSET_CURSOR_NORMAL

    ; Increase cursor_x with oam data's x-pos
    clc 
    lda cursor_x
    adc oam + OAM_OFFSET_CURSOR_NORMAL + OAM_X
    sta oam + OAM_OFFSET_CURSOR_NORMAL + OAM_X

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc UpdateMediumCursorPosition

    ldx #$00
    Loop:
        ; Increase cursor_y with oam data's y-pos
        clc 
        lda cursor_y
        adc oam + OAM_OFFSET_CURSOR_MEDIUM, X 

        ; subtract A (y pos) by one bc it's draw on the next scanline  
        clc 
        sbc #$00

        ; Store data to OAM
        sta oam + OAM_OFFSET_CURSOR_MEDIUM, X 

        ; Increase cursor_x with oam data's x-pos
        clc 
        lda cursor_x
        adc oam + OAM_OFFSET_CURSOR_MEDIUM + OAM_X, X 
        sta oam + OAM_OFFSET_CURSOR_MEDIUM + OAM_X, X 

        ; x += 4 bytes, to go to the next sprite
        inx 
        inx 
        inx 
        inx 

        cpx #OAM_SIZE_CURSOR_MEDIUM
        bne Loop

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc UpdateBigCursorPosition

    ldx #$00
    Loop:
        ; Increase cursor_y with oam data's y-pos
        clc 
        lda cursor_y
        adc oam + OAM_OFFSET_CURSOR_BIG, X 

        ; subtract A (y pos) by one bc it's draw on the next scanline  
        clc 
        sbc #$00

        ; Store data to OAM
        sta oam + OAM_OFFSET_CURSOR_BIG, X 

        ; Increase cursor_x with oam data's x-pos
        clc 
        lda cursor_x
        adc oam + OAM_OFFSET_CURSOR_BIG + OAM_X, X 
        sta oam + OAM_OFFSET_CURSOR_BIG + OAM_X, X 

        ; x += 4 bytes, to go to the next sprite
        inx 
        inx 
        inx 
        inx 

        cpx #OAM_SIZE_CURSOR_BIG
        bne Loop

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc HideInactiveCursors

    lda cursor_type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor_Jump


    ;this should never be reached
    rts 


    Small_Cursor:
        ; Hide normal, medium and big cursor
        HideCursor OAM_OFFSET_CURSOR_NORMAL,    OAM_SIZE_CURSOR_NORMAL
        HideCursor OAM_OFFSET_CURSOR_MEDIUM,    OAM_SIZE_CURSOR_MEDIUM
        HideCursor OAM_OFFSET_CURSOR_BIG,       OAM_SIZE_CURSOR_BIG

        rts 


    Normal_Cursor:
        ; Hide small, medium and big cursor
        HideCursor OAM_OFFSET_CURSOR_SMALL,     OAM_SIZE_CURSOR_SMALL
        HideCursor OAM_OFFSET_CURSOR_MEDIUM,    OAM_SIZE_CURSOR_MEDIUM
        HideCursor OAM_OFFSET_CURSOR_BIG,       OAM_SIZE_CURSOR_BIG

        rts 

    ; to fix range error
    Big_Cursor_Jump:
        jmp Big_Cursor


    Medium_Cursor:
        ; Hide small, normal and big cursor
        HideCursor OAM_OFFSET_CURSOR_SMALL,     OAM_SIZE_CURSOR_SMALL
        HideCursor OAM_OFFSET_CURSOR_NORMAL,    OAM_SIZE_CURSOR_NORMAL
        HideCursor OAM_OFFSET_CURSOR_BIG,       OAM_SIZE_CURSOR_BIG

        rts 


    Big_Cursor:
        ; Hide small, normal and medium cursor
        HideCursor OAM_OFFSET_CURSOR_SMALL, OAM_SIZE_CURSOR_SMALL
        HideCursor OAM_OFFSET_CURSOR_NORMAL, OAM_SIZE_CURSOR_NORMAL
        HideCursor OAM_OFFSET_CURSOR_MEDIUM, OAM_SIZE_CURSOR_MEDIUM

        rts 


    ; this should never be reached
    rts 

.endproc
; BudgetArms


; BudgetArms
.proc InitializeCursor
        lda #TYPE_CURSOR_STARTUP
        sta cursor_type

        ; set cursor_x/y
        lda #CURSOR_MIN_X * 8
        sta cursor_x

        lda #CURSOR_MIN_Y * 8
        sta cursor_y

        ; set cursor tile x/y
        lda #CURSOR_MIN_X
        sta tile_cursor_x

        lda #CURSOR_MIN_Y
        sta tile_cursor_y
    rts
.endproc
; BudgetArms


; Khine
.proc InitializeOverlayIndicators
    Player_1:
        Color_Indicator_1:
        lda #OVERLAY_P1_COLOR_OFFSET_Y
        sta oam + OAM_OFFSET_OVERLAY_P1_COLOR + OAM_Y
        lda #DIGIT_OFFSET + 1
        sta oam + OAM_OFFSET_OVERLAY_P1_COLOR + OAM_TILE
        lda #PLAYER_1_OVERLAY_ATTR
        sta oam + OAM_OFFSET_OVERLAY_P1_COLOR + OAM_ATTR
        lda #OVERLAY_P1_COLOR_OFFSET_X
        sta oam + OAM_OFFSET_OVERLAY_P1_COLOR + OAM_X

        Tool_Indicator_1:
        lda #OVERLAY_P1_TOOL_OFFSET_Y
        sta oam + OAM_OFFSET_OVERLAY_P1_TOOL + OAM_Y
        lda #DIGIT_OFFSET + 1
        sta oam + OAM_OFFSET_OVERLAY_P1_TOOL + OAM_TILE
        lda #PLAYER_1_OVERLAY_ATTR
        sta oam + OAM_OFFSET_OVERLAY_P1_TOOL + OAM_ATTR
        lda #OVERLAY_P1_TOOL_OFFSET_X
        sta oam + OAM_OFFSET_OVERLAY_P1_TOOL + OAM_X

    Player_2:
        Color_Indicator_2:
        lda #OVERLAY_P2_COLOR_OFFSET_Y
        sta oam + OAM_OFFSET_OVERLAY_P2_COLOR + OAM_Y
        lda #DIGIT_OFFSET + 2
        sta oam + OAM_OFFSET_OVERLAY_P2_COLOR + OAM_TILE
        lda #PLAYER_2_OVERLAY_ATTR
        sta oam + OAM_OFFSET_OVERLAY_P2_COLOR + OAM_ATTR
        lda #OVERLAY_P2_COLOR_OFFSET_X
        sta oam + OAM_OFFSET_OVERLAY_P2_COLOR + OAM_X

        @Tool_Indicator_2:
        lda #OVERLAY_P2_TOOL_OFFSET_Y
        sta oam + OAM_OFFSET_OVERLAY_P2_TOOL + OAM_Y
        lda #DIGIT_OFFSET + 2
        sta oam + OAM_OFFSET_OVERLAY_P2_TOOL + OAM_TILE
        lda #PLAYER_2_OVERLAY_ATTR
        sta oam + OAM_OFFSET_OVERLAY_P2_TOOL + OAM_ATTR
        lda #OVERLAY_P2_TOOL_OFFSET_X
        sta oam + OAM_OFFSET_OVERLAY_P2_TOOL + OAM_X

    jsr UpdateColorSelectionOverlayPosition
    jsr UpdateToolSelectionOverlayPosition
    rts
.endproc
; Khine


; Khine
.proc UpdateColorSelectionOverlayPosition
    Color_Indicator_P1:
        lda #OVERLAY_P1_COLOR_OFFSET_X
        ldx selected_color_chr_index
        beq Skip_Color_Loop_P1

        clc
        Color_Loop_P1:
        adc #OVERLAY_COLOR_MULTIPLIER
        dex
        bne Color_Loop_P1

        Skip_Color_Loop_P1:
        sta oam + OAM_OFFSET_OVERLAY_P1_COLOR + OAM_X

    Color_Indicator_P2:
        lda #OVERLAY_P2_COLOR_OFFSET_X
        ldx selected_color_chr_index + 1
        beq Skip_Color_Loop_P2

        clc
        Color_Loop_P2:
        adc #OVERLAY_COLOR_MULTIPLIER
        dex
        bne Color_Loop_P2

        Skip_Color_Loop_P2:
        sta oam + OAM_OFFSET_OVERLAY_P2_COLOR + OAM_X
    rts
.endproc

.proc UpdateToolSelectionOverlayPosition
    Tool_Indicator_P1:
        lda #OVERLAY_P1_TOOL_OFFSET_X
        ldx selected_tool
        beq Skip_Tool_Loop_P1

        clc
        Tool_Loop_P1:
        adc #OVERLAY_TOOL_MULTIPLIER
        dex
        bne Tool_Loop_P1

        Skip_Tool_Loop_P1:
        sta oam + OAM_OFFSET_OVERLAY_P1_TOOL + OAM_X

    Tool_Indicator_P2:
        lda #OVERLAY_P2_TOOL_OFFSET_X
        ldx selected_tool + 1
        beq Skip_Tool_Loop_P2

        clc
        Tool_Loop_P2:
        adc #OVERLAY_TOOL_MULTIPLIER
        dex
        bne Tool_Loop_P2

        Skip_Tool_Loop_P2:
        sta oam + OAM_OFFSET_OVERLAY_P2_TOOL + OAM_X
    rts
.endproc
; Khine


; BudgetArms
.proc HideActiveCursor

    lda cursor_type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor


    ;this should never be reached
    rts 

    Small_Cursor:
        HideCursor OAM_OFFSET_CURSOR_SMALL,     OAM_SIZE_CURSOR_SMALL
        rts 

    Normal_Cursor:
        HideCursor OAM_OFFSET_CURSOR_NORMAL,    OAM_SIZE_CURSOR_NORMAL
        rts 

    Medium_Cursor:
        HideCursor OAM_OFFSET_CURSOR_MEDIUM,    OAM_SIZE_CURSOR_MEDIUM
        rts 

    Big_Cursor:
        HideCursor OAM_OFFSET_CURSOR_BIG,       OAM_SIZE_CURSOR_BIG
        rts 

    ; this should never be reached
    rts 

.endproc
; BudgetArms


; Jeronimas
.proc UpdateCursorPositionOverlay

    ; Convert cursor_x to three decimal digits
    lda cursor_x
    ldx #100
    jsr DivideByX           ; hundreds in A, remainder in X
    sta cursor_x_digits     ; hundreds digit (0-2)
    txa 
    ldx #10
    jsr DivideByX           ; tens in A, ones in X
    sta cursor_x_digits + 1 ; tens digit (0-9)
    stx cursor_x_digits + 2 ; ones digit (0-9)
    
    ; Convert cursor_y to three decimal digits
    lda cursor_y
    sec
    sbc #OVERLAY_YPOS_OFFSET_FROM_CANVAS
    ldx #100
    jsr DivideByX
    sta cursor_y_digits     ; hundreds digit (0-2)
    txa 
    ldx #10
    jsr DivideByX
    sta cursor_y_digits + 1 ; tens digit (0-9)
    stx cursor_y_digits + 2 ; ones digit (0-9)
    rts 

.endproc
; Jeronimas


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
        tax                    ; Move remainder (in A) to X
        tya                    ; Move quotient (in Y) to A

    rts 

.endproc
; Jeronimas


; Jeronimas
.proc DrawCursorPositionOverlay
    ; Write overlay to nametable during VBlank
    ; Reset PPU address latch
    ; Set PPU address to nametable location

    ChangePPUNameTableAddr OVERLAY_XPOS_OFFSET

    ; Write X digits as decimal (000-255)
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

    ChangePPUNameTableAddr OVERLAY_YPOS_OFFSET

    ; Write Y digits as decimal (000-240)
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


; BudgetArms
.proc ReadPPUAtCurrentAddr
    ; read current tile and output to A

    ; Reset PPU latch
    lda PPU_STATUS

    ; Setting address to PPU

    ; Set high byte
    lda fill_current_addr + 1
    sta PPU_ADDR

    ; Set low byte
    lda fill_current_addr
    sta PPU_ADDR

    ; Read vram (at current address)
    lda PPU_DATA
    lda PPU_DATA

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc WriteBrushToCurrentAddr
    ; write brush_tile_index to current tile

    ; Reset PPU latch
    lda PPU_STATUS

    ; Setting address to PPU

    ; Set high byte
    lda fill_current_addr + 1
    sta PPU_ADDR

    ; Set low byte
    lda fill_current_addr
    sta PPU_ADDR

    ; write brush color (at current address) to vram 
    ldx current_player
    lda selected_color_chr_index, x ;brush_tile_index
    sta PPU_DATA

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc ReadPPUAtNeighbor
    ; read neighbor tile and output to a

    ; Reset PPU latch
    lda PPU_STATUS

    ; Setting address to PPU

    ; set high byte
    lda fill_neighbor_addr + 1
    sta PPU_ADDR

    ; set low byte
    lda fill_neighbor_addr
    sta PPU_ADDR

    ; read vram (at neighbor)
    lda PPU_DATA
    lda PPU_DATA

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc PushToQueue
    ; Push A (low) and X (high) to queue

    ; store low byte
    ldy queue_tail
    sta fill_queue, y

    ; store high byte
    txa 
    sta fill_queue + 256, y

    ; Increase tail index
    inc queue_tail

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc PopFromQueue
    ; Pops and outputs to current tile

    ; head is address to pop
    ldy queue_head

    ; get low byte
    lda fill_queue, y
    sta fill_current_addr

    ; get high byte
    lda fill_queue + 256, y
    sta fill_current_addr + 1

    ; Increase head index
    inc queue_head

    rts 

.endproc
; BudgetArms

