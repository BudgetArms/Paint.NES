.proc reset

    sei			; mask interrupts
    lda #0
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

    wait_vblank:
        bit PPU_STATUS
        bpl wait_vblank

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
    sta scroll_y_position

    lda #$00
    sta current_program_mode

    ; Set multiplayer mode
    lda #02
    sta player_count

    ; ; Write sprite 0 to OAM buffer (4 bytes per sprite)
    ; 	lda cursor_y
    ; 	sta oam+0             ; Byte 0: Y position
    ; 	lda #$20 
    ; 	sta oam+1             ; Byte 1: tile index (which 8x8 tile to display)
    ; 	lda #$00
    ; 	sta oam+2             ; Byte 2: attributes (palette, flip, priority bits)
    ; 	lda cursor_x
    ; 	sta oam+3             ; Byte 3: X position

    ; OAM attribute byte format (%76543210):
    ; Bits 0-1: Palette (0-3)
    ; Bit 5: Priority (0=front, 1=behind background)
    ; Bit 6: Flip horizontal
    ; Bit 7: Flip vertical

    ; wait for second vBlank
    wait_vblank2:
        bit PPU_STATUS
        bpl wait_vblank2

    ; NES is initialized and ready to begin
    ; - enable the NMI for graphical updates and jump to our main program

    jsr InitializeAudio

    lda #%10000000
    sta PPU_CONTROL

    jmp main

.endproc

