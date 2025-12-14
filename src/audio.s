; Jeronimas
.proc InitializeAudio

    ; Initialize FamiStudio sound engine
    ldx #.lobyte(music_data_untitled) ; Sets the address of the background music
    ldy #.hibyte(music_data_untitled)
    lda #1  ; 0 = NTSC, 1 = PAL
    jsr famistudio_init

    ; Initialize SFX
    ldx #.lobyte(sounds)    ; Sets the address of sound effects
    ldy #.hibyte(sounds)
    jsr famistudio_sfx_init

    ; Start playing first song (song index 1)
    lda #1
    jsr famistudio_music_play

    ; Initialize music state
    lda #0
    sta music_paused
    sta current_bg_song
    sta menu_music_started

    rts 

.endproc
; Jeronimas


; Jeronimas
.proc PlayToolSoundEffect
    
    ; Play drawing sound effect based on tool mode
    lda player + P_SELECTED_TOOL
    cmp #BRUSH_TOOL_SELECTED
    beq @Play_Draw

    cmp #ERASER_TOOL_SELECTED
    beq @Play_Eraser

    cmp #FILL_TOOL_SELECTED
    beq @Play_Fill

    cmp #SHAPE_TOOL_SELECTED
    beq @Play_Shape

    cmp #CLEAR_TOOL_SELECTED
    beq @Play_Clear

    cmp #TEXT_TOOL_SELECTED
    beq @Play_Text
    
    ; Default - no sound
    rts 
    
    @Play_Shape:
        ; Shape tool - play shape sound (index 0) on both Square and Noise channels
        lda #$00
        ldx #FAMISTUDIO_SFX_CH0  ; Square channel
        jsr famistudio_sfx_play  ; this is here so we can play on multiple sound channels
        
        lda #$00
        ldx #FAMISTUDIO_SFX_CH1  ; Noise channel
        ; Fall through to @Play_SFX
        jmp @Play_SFX
    
    @Play_Eraser:
        ; Eraser tool - play eraser sound (index 1)
        lda #$01
        ldx #FAMISTUDIO_SFX_CH0  ; Square channel
        jmp @Play_SFX
    
    @Play_Clear:
        ; Clear tool - play clear sound (index 2)
        lda #$02
        ldx #FAMISTUDIO_SFX_CH0  ; Square channel
        jmp @Play_SFX

    @Play_Fill:
        ; Fill tool - play fill sound (index 2)
        lda #$03
        ldx #FAMISTUDIO_SFX_CH1  ; Noise channel
        jmp @Play_SFX
        
    @Play_Draw:
        ; Draw/Brush tool - play draw sound (index 3)
        lda #$04
        ldx #FAMISTUDIO_SFX_CH1  ; Noise channel
        jmp @Play_SFX

    @Play_Text:
        ; Text tool - play keypress DPCM sample
        lda #$05
        jsr famistudio_sfx_sample_play
        
    @Play_SFX:
        jsr famistudio_sfx_play

    rts 

.endproc
; Jeronimas

; Jeronimas
.proc PlayMenuSelectSFX
    ; Play the same DPCM sample used by the Text tool on menu selection
    ; Also play on the square channel
    lda #$05
    ldx #FAMISTUDIO_SFX_CH0  ; Square channel
    jsr famistudio_sfx_play
    
    lda #$05
    jsr famistudio_sfx_sample_play
    rts
.endproc
; Jeronimas