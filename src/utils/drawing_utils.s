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



; BudgetArms
.macro DrawTile colorIndex, position

    ; position is 2 bytes
    .local @In_Canvas 
    .local @Not_In_Canvas 
    .local @Skip_Drawing 

    ; discard if position not in between canvas position

    ; if posX (converted to tile) < cursor_min_x
    clc 
    lda position
    lsr 
    lsr 
    lsr 
    cmp #CURSOR_MIN_X
    bcc @Not_In_Canvas  

    ; if posX (tile) > cursor_max_x
    clc 
    lda position
    lsr 
    lsr 
    lsr 
    cmp #CURSOR_MAX_X 
    bcs @Not_In_Canvas  

    ; if posY (tile) < cursor_min_y
    clc 
    lda position + 1
    lsr 
    lsr 
    lsr 
    cmp #CURSOR_MIN_Y
    bcc @Not_In_Canvas  

    ; if posX (tile) > cursor_max_y
    clc 
    lda position + 1
    lsr 
    lsr 
    lsr 
    cmp #CURSOR_MAX_Y
    bcs @Not_In_Canvas  

    
    jmp @In_Canvas


    @Not_In_Canvas:
        jmp @Skip_Drawing


    @In_Canvas:


    ; reset ppu lash
    lda PPU_STATUS
    
    ConvertPositionToTilePosition position

    lda tile_position_output + 1
    sta PPU_ADDR
    lda tile_position_output
    sta PPU_ADDR

    lda colorIndex     
    sta PPU_DATA 

    @Skip_Drawing:
    lda #$00


.endmacro
; BudgetArms


; Khine / Template
.proc HideAllSprites
    ; place all sprites offscreen at Y=255
    lda #OAM_OFFSCREEN
    ldx #$00

    Clear_Oam:
        sta oam,x
        inx 
        inx 
        inx 
        inx 
        bne Clear_Oam
    
    rts
.endproc
; Khine / Template

; Khine
.proc UseClearCanvasTool
    jsr PPUOff

    lda PPU_STATUS ; reset address latch
    lda #>CANVAS_START_ADDRESS ; set PPU address to $2000
    sta PPU_ADDR
    lda #<CANVAS_START_ADDRESS
    sta PPU_ADDR

    jsr PlayToolSoundEffect

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


; BudgetArms
.proc UpdateCursorSpritePosition
    ; Multiply TILE_X/TILE_Y POS by 8 to get X/Y POS
    lda #$00
    ldx player + P_TILE_X_POS
    beq :+
        clc
        Adding_X_Loop:
        adc #TILE_PIXEL_SIZE
        dex
        bne Adding_X_Loop
    :
    sta player + P_X_POS

    lda #$00
    ldx player + P_TILE_Y_POS
    beq :+
        clc
        Adding_Y_Loop:
        adc #TILE_PIXEL_SIZE
        dex
        bne Adding_Y_Loop
    :
    sta player + P_Y_POS

    lda player + P_CURSOR_SIZE

    cmp #TYPE_CURSOR_NORMAL
    bne :+
        lda #<CURSOR_NORMAL_DATA
        sta abs_address_to_access
        lda #>CURSOR_NORMAL_DATA
        sta abs_address_to_access + 1
        ldx #OAM_SPRITE_SIZE_CURSOR_NORMAL
        jmp Start_Update
    :

    cmp #TYPE_CURSOR_MEDIUM
    bne :+
        lda #<CURSOR_MEDIUM_DATA
        sta abs_address_to_access
        lda #>CURSOR_MEDIUM_DATA
        sta abs_address_to_access + 1
        ldx #OAM_SPRITE_SIZE_CURSOR_MEDIUM
        jmp Start_Update
    :

    cmp #TYPE_CURSOR_BIG
    bne :+
        lda #<CURSOR_BIG_DATA
        sta abs_address_to_access
        lda #>CURSOR_BIG_DATA
        sta abs_address_to_access + 1
        ldx #OAM_SPRITE_SIZE_CURSOR_BIG
        jmp Start_Update
    :

    Start_Update:

    Start_Loop:
    ldy player + P_INDEX
    cpy #PLAYER_1
    bne P2

    P1:
        ldy #$00
        P1_Loop:
            lda player + P_Y_POS
            clc
            adc (abs_address_to_access), y

            sec
            sbc #$01
            sta oam + OAM_OFFSET_P1_CURSOR, y

            iny
            iny
            iny

            lda player + P_X_POS
            clc
            adc (abs_address_to_access), y
            sta oam + OAM_OFFSET_P1_CURSOR, y

            iny
            dex
            bne P1_Loop
            jmp End_Loop

    P2:
        ldy #$00
        P2_Loop:
            lda player + P_Y_POS
            clc
            adc (abs_address_to_access), y

            sec
            sbc #$01
            sta oam + OAM_OFFSET_P2_CURSOR, y

            iny
            iny
            iny

            lda player + P_X_POS
            clc
            adc (abs_address_to_access), y
            sta oam + OAM_OFFSET_P2_CURSOR, y
            
            iny
            dex
            bne P2_Loop
    End_Loop:

    jsr UpdateCursorPositionOverlay

    rts
.endproc
; BudgetArms


; Khine
.proc HideCursorSprite

    lda #OAM_OFFSCREEN
    ldx #$00
    ldy #OAM_SPRITE_SIZE_CURSOR_ALL * 2 ; For both players
    Hide_Loop:
        sta oam + OAM_OFFSET_P1_CURSOR + OAM_Y, X

        inx
        inx
        inx
        inx

        dey
        bne Hide_Loop
    rts 

.endproc
; Khine


; Khine
.proc InitializeOverlayIndicators
    ldx current_player_index
    bne Player_2

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
    jmp End_Load

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
    End_Load:

    jsr UpdateColorSelectionOverlayPosition
    jsr UpdateToolSelectionOverlayPosition
    rts
.endproc
; Khine


; Khine
.proc UpdateColorSelectionOverlayPosition
    ldx player + P_INDEX
    bne Color_Indicator_P2

    Color_Indicator_P1:
        lda #OVERLAY_P1_COLOR_OFFSET_X
        ldx player + P_SELECTED_COLOR_INDEX
        beq Skip_Color_Loop_P1

        clc
        Color_Loop_P1:
        adc #OVERLAY_COLOR_MULTIPLIER
        dex
        bne Color_Loop_P1

        Skip_Color_Loop_P1:
        sta oam + OAM_OFFSET_OVERLAY_P1_COLOR + OAM_X
        rts

    Color_Indicator_P2:
        lda #OVERLAY_P2_COLOR_OFFSET_X
        ldx player + P_SELECTED_COLOR_INDEX
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


; Khine
.proc UpdateToolSelectionOverlayPosition
    ldx player + P_INDEX
    bne Tool_Indicator_P2

    Tool_Indicator_P1:
        lda #OVERLAY_P1_TOOL_OFFSET_X
        ldx player + P_SELECTED_TOOL
        beq Skip_Tool_Loop_P1

        clc
        Tool_Loop_P1:
        adc #OVERLAY_TOOL_MULTIPLIER
        dex
        bne Tool_Loop_P1

        Skip_Tool_Loop_P1:
        sta oam + OAM_OFFSET_OVERLAY_P1_TOOL + OAM_X
        rts

    Tool_Indicator_P2:
        lda #OVERLAY_P2_TOOL_OFFSET_X
        ldx player + P_SELECTED_TOOL
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


; Jeronimas
.proc UpdateCursorPositionOverlay

    ; Convert cursor_x to three decimal digits
    ;lda cursor_x
    lda player_1_properties + P_X_POS
    ldx #100
    jsr DivideByX           ; hundreds in A, remainder in X
    sta cursor_x_digits     ; hundreds digit (0-2)
    txa 
    ldx #10
    jsr DivideByX           ; tens in A, ones in X
    sta cursor_x_digits + 1 ; tens digit (0-9)
    stx cursor_x_digits + 2 ; ones digit (0-9)
    
    ; Convert cursor_y to three decimal digits
    lda player_1_properties + P_Y_POS
    sec
    sbc #CURSOR_MIN_Y * TILE_PIXEL_SIZE
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
    lda player + P_SELECTED_COLOR_INDEX
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
