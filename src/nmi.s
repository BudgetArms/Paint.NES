.proc LoadPlayerBrushProperties
    lda current_player_index

    cmp #PLAYER_1
    bne :+
        lda player_1_properties + P_SELECTED_TOOL
        sta player + P_SELECTED_TOOL
        lda player_1_properties + P_SELECTED_COLOR_INDEX
        sta player + P_SELECTED_COLOR_INDEX
        lda player_1_properties + P_CURSOR_SIZE
        sta player + P_CURSOR_SIZE
        lda player_1_properties + P_TILE_ADDR
        sta player + P_TILE_ADDR
        lda player_1_properties + P_TILE_ADDR + 1
        sta player + P_TILE_ADDR + 1
        rts
    :

    cmp #PLAYER_2
    bne :+
        lda player_2_properties + P_SELECTED_TOOL
        sta player + P_SELECTED_TOOL
        lda player_2_properties + P_SELECTED_COLOR_INDEX
        sta player + P_SELECTED_COLOR_INDEX
        lda player_2_properties + P_CURSOR_SIZE
        sta player + P_CURSOR_SIZE
        lda player_2_properties + P_TILE_ADDR
        sta player + P_TILE_ADDR
        lda player_2_properties + P_TILE_ADDR + 1
        sta player + P_TILE_ADDR + 1
        rts 
    :
    
    rts
.endproc


.proc LoadPlayerToolTypeProperties

    lda current_player_index

    cmp #PLAYER_1
    bne :+
        lda player_1_properties + P_INDEX
        sta player + P_INDEX
        lda player_1_properties + P_SELECTED_TOOL
        sta player + P_SELECTED_TOOL
        rts
    :

    cmp #PLAYER_2
    bne :+
        lda player_2_properties + P_INDEX
        sta player + P_INDEX
        lda player_2_properties + P_SELECTED_TOOL
        sta player + P_SELECTED_TOOL
        rts 
    :
    
    rts

.endproc

.proc nmi
    ; save registers
    pha 
    txa 
    pha 
    tya 
    pha 

    lda nmi_ready
    bne :+ ; nmi_ready == 0 not ready to update PPU
        jmp ppu_update_end
    :
    cmp #2 ; nmi_ready == 2 turns rendering off
    bne cont_render
        lda #%00000000
        sta PPU_MASK
        ldx #0
        stx nmi_ready
        jmp ppu_update_end

    cont_render:

    ; transfer sprite OAM data using DMA
    ldx #0
    stx PPU_OAMADDR
    lda #>oam
    sta PPU_OAMDMA

    ; transfer current palette to PPU
    lda #%10001000 ; set horizontal nametable increment
    sta PPU_CONTROL

    lda PPU_STATUS
    lda #>PPU_PALETTE_START
    sta PPU_ADDR
    ldx #$00 ; transfer the 32 bytes to VRAM
    stx PPU_ADDR

    loop:
        lda palette, x
        sta PPU_DATA
        inx 
        cpx #PALETTE_SIZE
        bcc loop

    lda current_program_mode
    
    cmp #START_MENU_MODE
    bne :+
        jsr StartMenuNMI
    :

    cmp #CANVAS_MODE
    bne :+
        jsr CanvasNMI
    :

    cmp #TRANSITION_MODE
    bne :+
        jsr TransitionNMI
    :

    End_Of_NMI:
    jsr ResetScroll

    ; enable rendering
    lda current_program_mode
    and #HELP_OR_TRANSITION_MODE
    beq :+
        lda #%00001110
        jmp :++
    :
        lda #%00011110
    :
    sta PPU_MASK
    ; flag PPU update complete
    ldx #0
    stx nmi_ready
    ppu_update_end:

    ; update FamiStudio sound engine
    jsr famistudio_update

    ; restore registers and return
    pla 
    tay 
    pla 
    tax 
    pla 

    rti 

.endproc

.proc StartMenuNMI
    rts
.endproc


.proc TransitionNMI
    lda previous_program_mode
    cmp #HELP_MENU_MODE
    bne :+
        rts
    :

    lda next_program_mode
    cmp #HELP_MENU_MODE
    bne :+
        rts
    :

    jsr LoadTilemapWithTransition
    rts
.endproc

.proc CanvasNMI
    lda #$00
    sta current_player_index

    Loop_Players:
        LoadCurrentPlayerProperty P_TOOL_USE_FLAG

        and #BRUSH_TOOL_ON
        beq :+
            jsr LoadPlayerBrushProperties
            jsr UseBrushTool

            SaveValueToPlayerProperty P_TOOL_USE_FLAG, #ALL_TOOLS_OFF
        :

        LoadCurrentPlayerProperty P_UPDATE_FLAG

        cmp #UPDATE_ALL_OFF
        beq :+
            jsr LoadPlayerToolTypeProperties
            jsr RefreshToolTextOverlay

            SaveCurrentPlayerProperty P_UPDATE_FLAG
        :

        inc current_player_index

        lda current_player_index
        cmp player_count
        bne Loop_Players

        
        jsr DrawCursorPositionOverlay

    rts 

.endproc
