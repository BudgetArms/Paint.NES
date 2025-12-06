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

    ; Start playing first song (song index 0)
    lda #0
    jsr famistudio_music_play

    ; Initialize music state
    lda #0
    sta music_paused
    rts
.endproc

.proc PlayBrushSoundEffect

    ; Play drawing sound effect here based on tool mode

    lda selected_tool
    cmp #PENCIL_TOOL_ACTIVATED
    beq @Play_Splash
    
    ; Eraser mode - play bird sound (index 0)
    lda #0
    jmp @Play_Sound
    
    @Play_Splash:
        ; Draw mode - play splash sound (index 1)
        lda #1
    
    @Play_Sound:
        ; Set the appropriate SFX channel based on which sound we're playing
        ; Bird (0) uses square channel, Splash (1) uses noise channel
        cmp #0
        beq @use_square_channel
        
        ; Splash sound - use noise channel (SFX_CH1)
        ldx #FAMISTUDIO_SFX_CH1
        jmp @play_it
        
    @use_square_channel:
        ; Bird sound - use square channel (SFX_CH0)
        ldx #FAMISTUDIO_SFX_CH0
        
    @play_it:
        jsr famistudio_sfx_play  ; Call FamiStudio directly with correct channel
        lda #0
    
    rts
.endproc