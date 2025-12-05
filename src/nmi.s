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
    lda #$3F ; set PPU address to $3F00
    sta PPU_ADDR
    stx PPU_ADDR
    ldx #0 ; transfer the 32 bytes to VRAM


    ; Khine
    jsr ClearCanvas
    jsr DrawBrush

    jsr UpdateOverlayCursorPosition

    ;Joren
    jsr UpdateColorSelectionOverlay
    jsr UpdateToolSelectionOverlay

    jsr UpdateColorValues
    
    ; jsr SetTopAndBottomRowsColorPallete    
    ; jsr SetCollorPaletteForUI


    jsr ResetScroll
    

    jsr UseShapeTool
    jsr UseFillTool


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
