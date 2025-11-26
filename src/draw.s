;file for all drawing functions


; BudgetArms
.proc LoadCursor

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
        jsr LoadSmallCursor
        rts 

    Normal_Cursor:
        jsr LoadNormalCursor
        rts 

    Medium_Cursor:
        jsr LoadMediumCursor
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
.proc LoadMediumCursor

    ldx #$00

    @Loop:
        lda CURSOR_MEDIUM_DATA, X
        sta oam + OAM_OFFSET_CURSOR_MEDIUM, X
        inx 

        cpx #OAM_SIZE_CURSOR_MEDIUM
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


; Khine / BudgetArms
.proc draw_brush
    ; Check if the PAD_A has been pressed
    ; This is not checked in the `input_utils.s` because this can run into issues with
    ; the program updating the PPU even though PPU has not finished drawing on the screen
    ; not waiting for the VBLANK

    ; If tool_use_attr does not have brush tool ON, return
    lda tool_use_attr
    and #BRUSH_TOOL_ON
    bne Use_Brush
        rts 

    Use_Brush:

    ; Remove BRUSH_TOOL_ON from the tool_use_attributes
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

    ; Is Fill Mode Selected
    lda tool_mode
    and #FILL_MODE
    beq Not_Fill_Mode

        jsr UseFillTool
        rts 


    Not_Fill_Mode:
    ; If not fill mode, then it's Draw/Erase mode

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
; Khine / BudgetArms


; BudgetArms
.proc UseFillTool
    
    ; Flood Fill

    ; VRAM DATA:
    ;    HIGH       LOW
    ; 7654 3210   7654 3210
    ; ---- --YY   YYYX XXXX

    ; Resets the scroll, so the window
    ; doesn't x doesn't change when doing stuff 
    jsr ResetScroll
    
    ; turn ppu off
    jsr ppu_off

    ; Store the current tile position to the cursor_pos 
    lda cursor_tile_position + 1
    sta fill_current_addr + 1
    lda cursor_tile_position
    sta fill_current_addr

    ; Set target color 
    jsr ReadPPUAtCurrentAddr
    sta fill_target_color

    ; if the brush tile index is not transparent, Start_Fill
    lda fill_target_color
    cmp brush_tile_index
    bne Start_Fill
        ; if transparent, Finish
        jmp Finish


    Start_Fill:
        ; initialize/Reset ring queue
        lda #$0
        sta queue_head
        sta queue_tail

        ; draw tile
        lda fill_current_addr
        ldx fill_current_addr + 1
        jsr PushToQueue


    Fill_Loop:
        
        ; if head == tail -> Finish, else Not_Finish
        lda queue_head
        cmp queue_tail
        bne Not_Finish 

            jmp Finish

        Not_Finish:

        ; get current color 
        jsr PopFromQueue 

        ; If color is same as target color, Fill_Loop (check next tile in queue)
        jsr ReadPPUAtCurrentAddr
        cmp fill_target_color
        bne Fill_Loop

        ; fill the tile in the target color
        jsr WriteBrushToCurrentAddr

        ; If tile not on top of screen, check up
        GetNametableTileY fill_current_addr
        cmp #$00
        bne Check_Up

        ; if tile on right side of screen, check down
        GetNametableTileX fill_current_addr
        cmp #DISPLAY_SCREEN_WIDTH
        bcc Try_Down


    Check_Up:

        ; Move up, by subtracing (screen_width + 1)
        sec 
        lda fill_current_addr
        sbc #DISPLAY_SCREEN_WIDTH
        sta fill_neighbor_addr

        ; Move Up
        lda fill_current_addr + 1
        sbc #0
        sta fill_neighbor_addr + 1
        
        ; If neighbor tile (up) is filled, try down
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Try_Down

        ; Draw tile
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue


    Try_Down:

        ; if not last row, do  
        GetNametableTileY fill_current_addr
        cmp #DISPLAY_SCREEN_HEIGHT - 1
        beq Try_Left

        ; else do down
        jmp Do_Down


    Do_Down:

        ; Move down, by adding (screen_width)
        ; set neighbor tile (low)
        clc 
        lda fill_current_addr
        adc #DISPLAY_SCREEN_WIDTH
        sta fill_neighbor_addr

        ; set neighbor tile (high)
        lda fill_current_addr + 1
        adc #0
        sta fill_neighbor_addr + 1

        ; If neighbor tile (down) is filled, try left
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Try_Left

        ; draw tile
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue


    Try_Left:

        ; if first column, try right
        GetNametableTileX fill_current_addr
        beq Try_Right

        ; set neighbor tile (low) 
        sec 
        lda fill_current_addr
        sbc #1
        sta fill_neighbor_addr

        ; set neighbor tile (high) 
        lda fill_current_addr + 1
        sbc #0
        sta fill_neighbor_addr + 1


        ; If neighbor tile (left) is filled, try right
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Try_Right
        
        ; draw tile
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue


    Try_Right:

        ; If last column, LoopEnd
        GetNametableTileX fill_current_addr
        cmp #DISPLAY_SCREEN_WIDTH - 1 
        beq Loop_End


        ; Set fill_neighbor low byte address to right neighbor
        clc 
        lda fill_current_addr
        adc #1
        sta fill_neighbor_addr

        ; Set fill_neighbor high byte address to right neighbor
        lda fill_current_addr + 1
        adc #0
        sta fill_neighbor_addr + 1

        ; Check if color right is target color, if not LoopEnd
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Loop_End

        ; Add right tile to queue
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue


    Loop_End:
        jmp Fill_Loop


    Finish:
        ; update to fix white flash & update screen
        jsr ppu_update

        rts 

.endproc
; BudgetArms