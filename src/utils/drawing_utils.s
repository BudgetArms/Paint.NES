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
    lda tool_use_attr
    and #CLEAR_TOOL_ON
    bne @Use_Brush
        rts 
    @Use_Brush:
    lda tool_use_attr
    eor #CLEAR_TOOL_ON
    sta tool_use_attr

    jsr PPUOff

    lda PPU_STATUS ; reset address latch
    lda #>CANVAS_START_ADDRESS ; set PPU address to $2000
    sta PPU_ADDR
    lda #<CANVAS_START_ADDRESS
    sta PPU_ADDR

    ; empty nametable A
    lda #BACKGROUND_TILE
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
.proc UpdateOverlayCursorPosition

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
.proc DrawOverlayCursorPosition
    ; Write overlay to nametable during VBlank
    ; Reset PPU address latch
    ; Set PPU address to nametable location

    ChangePPUNameTableAddr OVERLAY_NAMETABLE_ADDR
    
    ; Write "X:"
    lda #OVERLAY_TILE_CURSOR_X_LABEL
    sta PPU_DATA
    lda #OVERLAY_TILE_COLON
    sta PPU_DATA

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

    ; Write " Y:"
    lda #OVERLAY_TILE_SPACE
    sta PPU_DATA
    lda #OVERLAY_TILE_CURSOR_Y_LABEL
    sta PPU_DATA
    lda #OVERLAY_TILE_COLON
    sta PPU_DATA

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
    lda selected_color_chr_index ;brush_tile_index
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

; Jeronimas
; Load MainMenu tilemap into nametable 2
.proc LoadMainMenuTilemap
    ; Disable rendering first
    lda #%00000000
    sta PPU_MASK
    
    lda #%10000000
    sta PPU_CONTROL

    ; Load palette data first
    lda PPU_STATUS
    lda #>PPU_PALETTE_START
    sta PPU_ADDR
    lda #<PPU_PALETTE_START
    sta PPU_ADDR

    ldx #$00
LoadPaletteLoop:
        lda palette, x
        sta PPU_DATA
        inx
        cpx #PALETTE_SIZE
        bcc LoadPaletteLoop

    ; Load nametable data (960 bytes of tiles)
    lda PPU_STATUS
    lda #>PPU_NAMETABLE_2
    sta PPU_ADDR
    lda #<PPU_NAMETABLE_2
    sta PPU_ADDR

    ; Use 16-bit pointer for data source
    lda #<MainMenu_Tilemap
    sta $00
    lda #>MainMenu_Tilemap
    sta $01

    ; Load tiles - 960 bytes (30 rows * 32 columns)
    ldx #$00
    ldy #$00
    
LoadTilesLoop:
    lda ($00), y
    sta PPU_DATA
    iny
    bne LoadTilesLoop
    
    inc $01
    inx
    cpx #$03        ; 3 * 256 = 768 bytes
    bne LoadTilesLoop

    ; Load remaining 192 bytes (960 - 768 = 192)
    ldy #$00
LoadRemainingTiles:
    lda ($00), y
    sta PPU_DATA
    iny
    cpy #192
    bne LoadRemainingTiles

    ; Now load attributes from the .nam file (64 bytes)
    lda PPU_STATUS
    lda #>PPU_ATTRIBUTE_TABLLE_2
    sta PPU_ADDR
    lda #<PPU_ATTRIBUTE_TABLLE_2
    sta PPU_ADDR

    ; Attributes start at byte 960 in the .nam file
    lda #<(MainMenu_Tilemap + 960)
    sta $00
    lda #>(MainMenu_Tilemap + 960)
    sta $01

    ldy #$00
LoadAttributeLoop:
    lda ($00), y
    sta PPU_DATA
    iny
    cpy #$40        ; 64 attribute bytes
    bne LoadAttributeLoop

LoadMainMenuDone:
    ; Set PPU_CONTROL to display nametable 2
    lda #%10001000  ; Enable NMI, use nametable 2
    sta PPU_CONTROL
    
    rts
.endproc
; Jeronimas