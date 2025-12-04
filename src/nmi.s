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

;Try changinng this part to fix the pallette.
    ; loop:
        ;lda palette, x
        ;sta PPU_DATA
        ;inx
        ;cpx #32
        ;bcc loop
;


    ; Khine
    jsr ClearCanvas
    jsr DrawBrush

    jsr UpdateOverlayCursorPosition

    ;Joren
    jsr UpdateColorSelectionOverlay
    jsr UpdateToolSelectionOverlay

    jsr UpdateColorValues
    
    ;LDA #$23 ; high byte of adress in PPU
    ;STA PPU_ADDR
    ;LDA #$C0 ; low byte of adress in PPU
    ;STA PPU_ADDR

    
    ;LDX #$00
    ; LoopAllBlocks:
    ;lda PPU_DATA
    ;and #%11111100
    ;ora #%00000010
    ;;LDA #$FF
    ;STA PPU_DATA
    ;INX
    ;CPX #16 ; cause there are 64 bytes in attribute table
    ;BNE LoopAllBlocks

    ;LDA #$23
    ;STA PPU_ADDR
    ;LDA #$C0
    ;STA PPU_ADDR
;
    ;lda PPU_DATA
    ;and #%11111100
    ;ora #%00000010
;
    ;; write it back
    ;LDA #$23
    ;STA PPU_ADDR
    ;LDA #$C1
    ;STA PPU_ADDR
;
    ;STA PPU_DATA
    jsr SetTopAndBottomRowsColorPallete

    jsr ResetScroll
    
    ;jsr UpdateOverlayCursorPosition

    ;jsr DrawBrush
    jsr UseShapeTool
    jsr UseFillTool

    ;jsr LoadColorPalette


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

