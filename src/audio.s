; ; Jeronimas
; ; Call when NOT in main menu: ensures Gymnopédie (song 0) is playing.
; .proc EnsureCanvasMusic
;     lda current_bg_song
;     cmp #0
;     beq @already_playing

;     ; Switch to Gymnopédie
;     lda #0
;     jsr famistudio_music_play
;     lda #0
;     sta current_bg_song
;     lda #0
;     sta menu_music_started
;     @already_playing:
;         rts
; .endproc
; ; Jeronimas

; ; Jeronimas
; ; Call when IN main menu: plays CocoMelon (song 1) one time, does not loop.
; .proc PlayMenuMusicOnce
;     lda menu_music_started
;     bne @done           ; Already started once, don't restart.

;     ; Start CocoMelon
;     lda #1
;     jsr famistudio_music_play
;     lda #1
;     sta current_bg_song
;     lda #1
;     sta menu_music_started
;     @done:
;         rts
; .endproc
; ; Jeronimas

; ; Jeronimas
; ; A == 0 => not in menu (canvas), A != 0 => in menu
; .proc UpdateMusicForMenuState
;     beq @not_in_menu
;     jsr PlayMenuMusicOnce
;     rts
;     @not_in_menu:
;         jsr EnsureCanvasMusic
;         rts
; .endproc
; ; Jeronimas

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

