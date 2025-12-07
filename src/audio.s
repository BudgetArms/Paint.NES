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

    ; Start playing first song (song index 0)
    lda #0
    jsr famistudio_music_play

    ; Initialize music state
    lda #0
    sta music_paused

    rts 

.endproc
; Jeronimas


; Jeronimas
.proc PlayToolSoundEffect
    ; Play drawing sound effect based on tool mode
    lda selected_tool
    cmp #BRUSH_TOOL_ACTIVATED
    beq @Play_Draw
    cmp #ERASER_TOOL_ACTIVATED
    beq @Play_Eraser
    cmp #FILL_TOOL_ACTIVATED
    beq @Play_Fill
    cmp #SHAPE_TOOL_ACTIVATED
    beq @Play_Shape
    
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
    
    @Play_Fill:
        ; Fill tool - play fill sound (index 2)
        lda #$02
        ldx #FAMISTUDIO_SFX_CH1  ; Noise channel
        jmp @Play_SFX
        
    @Play_Draw:
        ; Draw/Brush tool - play draw sound (index 3)
        lda #$03
        ldx #FAMISTUDIO_SFX_CH1  ; Noise channel
        
    @Play_SFX:
        jsr famistudio_sfx_play

    rts
.endproc
; Jeronimas


; Jeronimas 
;*********************************************************
; PlaySfx: Play a sound effect
; Input: A = sound effect index to play
; Uses: sfx_channel variable for the channel to play on
; Preserves: X, Y registers
;*********************************************************
.proc PlaySFX

    sta sfx_temp + 9

    tya 
    pha 
    txa 
    pha 
    
    lda sfx_temp + 9
    ; Select channel based on sound effect index
    ; Bird (0) = square (CH0), Splash (1) = noise (CH1)
    tax  ; Use sound index as channel selector
    and #$01
    beq @Ch0
    ldx #FAMISTUDIO_SFX_CH1
    jmp @Play

    @Ch0:
        ldx #FAMISTUDIO_SFX_CH0
    @Play:
        lda sfx_temp + 9
        jsr famistudio_sfx_play
    
    pla 
    tax 
    pla 
    tay 

    rts 

.endproc
; Jeronimas
