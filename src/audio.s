; Jeronimas
; Call when NOT in main menu: ensures Gymnopédie (song 0) is playing.
.proc EnsureCanvasMusic
    lda current_bg_song
    cmp #0
    beq @already_playing

    ; Switch to Gymnopédie
    lda #0
    jsr famistudio_music_play
    lda #0
    sta current_bg_song
    lda #0
    sta menu_music_started
    @already_playing:
        rts
.endproc
; Jeronimas

; Jeronimas
; Call when IN main menu: plays CocoMelon (song 1) one time, does not loop.
.proc PlayMenuMusicOnce
    lda menu_music_started
    bne @done           ; Already started once, don't restart.

    ; Start CocoMelon
    lda #1
    jsr famistudio_music_play
    lda #1
    sta current_bg_song
    lda #1
    sta menu_music_started
    @done:
        rts
.endproc
; Jeronimas

; Jeronimas
; A == 0 => not in menu (canvas), A != 0 => in menu
.proc UpdateMusicForMenuState
    beq @not_in_menu
    jsr PlayMenuMusicOnce
    rts
    @not_in_menu:
        jsr EnsureCanvasMusic
        rts
.endproc
; Jeronimas

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
.proc PlayBrushSoundEffect

    ; Play drawing sound effect here based on tool mode
    lda player + P_SELECTED_TOOL
    cmp #BRUSH_TOOL_SELECTED
    beq @Play_Splash
    
    ; Eraser mode - play bird sound (index 0)
    lda #$00
    jmp @Play_Sound
    
    @Play_Splash:
        ; Draw mode - play splash sound (index 1)
        lda #$01
    
    @Play_Sound:
        ; Set the appropriate SFX channel based on which sound we're playing
        ; Bird (0) uses square channel, Splash (1) uses noise channel
        cmp #$00
        beq @Use_Square_Channel
        
        ; Splash sound - use noise channel (SFX_CH1)
        ldx #FAMISTUDIO_SFX_CH1
        jmp @Play_It
        
    @Use_Square_Channel:
        ; Bird sound - use square channel (SFX_CH0)
        ldx #FAMISTUDIO_SFX_CH0
        
    @Play_It:
        jsr famistudio_sfx_play  ; Call FamiStudio directly with correct channel
        lda #0
    
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
