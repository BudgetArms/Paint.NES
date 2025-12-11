.proc LoadPlayerBrushProperties
    lda current_player_index

    cmp #PLAYER_1
    bne :+
        lda player_1_properties + P_SELECTED_TOOL
        sta current_player_properties + P_SELECTED_TOOL
        lda player_1_properties + P_SELECTED_COLOR_INDEX
        sta current_player_properties + P_SELECTED_COLOR_INDEX
        lda player_1_properties + P_CURSOR_SIZE
        sta current_player_properties + P_CURSOR_SIZE
        lda player_1_properties + P_TILE_ADDR
        sta current_player_properties + P_TILE_ADDR
        lda player_1_properties + P_TILE_ADDR + 1
        sta current_player_properties + P_TILE_ADDR + 1
    rts
    :

    cmp #PLAYER_2
    bne :+
        lda player_2_properties + P_SELECTED_TOOL
        sta current_player_properties + P_SELECTED_TOOL
        lda player_2_properties + P_SELECTED_COLOR_INDEX
        sta current_player_properties + P_SELECTED_COLOR_INDEX
        lda player_2_properties + P_CURSOR_SIZE
        sta current_player_properties + P_CURSOR_SIZE
        lda player_2_properties + P_TILE_ADDR
        sta current_player_properties + P_TILE_ADDR
        lda player_2_properties + P_TILE_ADDR + 1
        sta current_player_properties + P_TILE_ADDR + 1
    rts
    :
.endproc


.macro LoadCurrentPlayerProperty property
    ldx current_player_index
    cpx #PLAYER_1
    bne :+
        lda player_1_properties + property
    :

    cpx #PLAYER_2
    bne :+
        lda player_2_properties + property
    :

    sta current_player_properties + property
.endmacro


.macro SaveCurrentPlayerProperty property
    lda current_player_properties + property

    ldx current_player_index
    cpx #PLAYER_1
    bne :+
        sta player_1_properties + property
    :

    cpx #PLAYER_2
    bne :+
        sta player_2_properties + property
    :
.endmacro


.macro SaveValueToPlayerProperty property, value
    lda value

    ldx current_player_index
    cpx #PLAYER_1
    bne :+
        sta player_1_properties + property
    :

    cpx #PLAYER_2
    bne :+
        sta player_2_properties + property
    :
.endmacro


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

    lda #$00
    sta current_player_index
    Loop_Players:

        LoadCurrentPlayerProperty P_TOOL_USE_FLAG

        cmp #BRUSH_TOOL_ON
        bne Brush_Not_Use
            jsr LoadPlayerBrushProperties
            jsr UseBrushTool

            SaveValueToPlayerProperty P_TOOL_USE_FLAG, #ALL_TOOLS_OFF
        Brush_Not_Use:

    inc current_player_index
    lda current_player_index
    cmp player_count
    bne Loop_Players

    ;jsr UseShapeTool

    Overlay:
    jsr DrawCursorPositionOverlay
    jsr RefreshToolTextOverlay

    jsr ResetScroll

    ; enable rendering
    lda #%00011110
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

