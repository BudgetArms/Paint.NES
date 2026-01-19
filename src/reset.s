.proc reset

    sei			; mask interrupts
    lda #$00
    sta PPU_CONTROL	; disable NMI
    sta PPU_MASK	; disable rendering
    sta APU_DM_CONTROL	; disable DMC IRQ

    ; Initialize APU 
    lda #$40
    sta JOYPAD2		; disable APU frame IRQ

    ldx #$FF 
    stx $4015 ; Disable all channels 


    cld			; disable decimal mode
    ldx #$FF
    txs			; initialise stack

    Wait_Vblank:
        bit PPU_STATUS
        bpl Wait_Vblank

    ; clear all RAM to 0
    lda #$00
    ldx #$00
    Clear_Ram:
        sta $0000,x
        sta $0100,x
        sta $0200,x
        sta $0300,x
        sta $0400,x
        sta $0500,x
        sta $0600,x
        sta $0700,x

        inx 

        bne Clear_Ram

    ; handy for debugging if a clean page is needed
    ; jsr clear_wram_p1

    jsr HideAllSprites

    ; Initialize scroll positions
    lda #$00
    sta scroll_x_position

    lda #NO_MODE
    sta previous_program_mode

    ; wait for second vBlank
    Wait_Vblank_2:
        bit PPU_STATUS
        bpl Wait_Vblank_2

    ; NES is initialized and ready to begin
    ; - enable the NMI for graphical updates and jump to our main program

    jsr InitializeAudio

    lda #%10000000
    sta PPU_CONTROL

    jmp main

.endproc

