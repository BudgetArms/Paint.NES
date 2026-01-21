mainloop:
    ; skip reading controls if and change has not been drawn
    lda nmi_ready
    cmp #$00
    bne mainloop

    lda current_program_mode

    cmp #START_MENU_MODE
    bne :+
        jsr StartMenuLoop
        jmp End_Of_Loop
    :

    cmp #CANVAS_MODE
    bne :+
        jsr CanvasLoop
        jmp End_Of_Loop
    :

    cmp #HELP_MENU_MODE
    bne :+
        jsr HelpMenuLoop
        jmp End_Of_Loop
    :

    cmp #LOAD_SAVE_MODE
    bne :+
        jsr LoadSaveMenuLoop
        jmp End_Of_Loop
    :

    cmp #SAVE_SAVE_MODE
    bne :+
        jsr SaveSaveMenuLoop
        jmp End_Of_Loop
    :

    cmp #SELECT_PLAYER_MODE
    bne :+
        jsr SelectPlayerMenuLoop
        jmp End_Of_Loop
    :

    cmp #TRANSITION_MODE
    bne :+
        jsr TransitionLoop
        jmp End_Of_Loop
    :

    End_Of_Loop:
    ; ensure our changes are rendered
    lda #$01
    sta nmi_ready
    jmp mainloop


; Khine
.proc StartMenuLoop
    lda #$00
    sta current_player_index

    ; Play CocoMelon (song 1) when entering start menu
    lda current_bg_song
    cmp #$01
    beq @Skip_Music_Start
        lda #$01
        jsr famistudio_music_play
        lda #$01
        sta current_bg_song

    @Skip_Music_Start:

        Loop_Players:
            jsr LoadPlayerProperties
            ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )
            jsr PollGamepad
            jsr HandleStartMenuInput

            jsr SavePlayerProperties

            inc current_player_index

            lda current_player_index
            cmp player_count
            bne Loop_Players

    rts 

.endproc
; Khine


; Khine
.proc HelpMenuLoop
    lda #$00
    sta current_player_index

    Loop_Players:
        jsr LoadPlayerProperties
        ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )
        jsr PollGamepad
        jsr HandleHelpMenuInput

        jsr SavePlayerProperties

        inc current_player_index

        lda current_player_index
        cmp player_count
        bne Loop_Players

    rts 

.endproc
; Khine


; BudgetArms
.proc LoadSaveMenuLoop
    lda #$00
    sta current_player_index

    Loop_Players:
        jsr LoadPlayerProperties
        ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )
        jsr PollGamepad
        jsr HandleLoadSaveMenuInput

        jsr SavePlayerProperties

        inc current_player_index

        lda current_player_index
        cmp player_count
        bne Loop_Players

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc SaveSaveMenuLoop
    lda #$00
    sta current_player_index

    Loop_Players:
        jsr LoadPlayerProperties
        ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )
        jsr PollGamepad
        jsr HandleSaveSaveMenuInput

        jsr SavePlayerProperties

        inc current_player_index

        lda current_player_index
        cmp player_count
        bne Loop_Players

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc SelectPlayerMenuLoop
    lda #$00
    sta current_player_index

    Loop_Players:
        jsr LoadPlayerProperties
        ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )
        jsr PollGamepad
        jsr HandleSelectPlayerMenuInput

        jsr SavePlayerProperties
        
        inc current_player_index
        
        lda current_player_index
        cmp player_count
        bne Loop_Players

    rts 

.endproc
; BudgetArms


; Khine / BudgetArms
.proc TransitionLoop
    inc mode_transition_time
    bne No_Transition_Yet
        lda next_program_mode

        cmp #CANVAS_MODE
        bne :++

            lda previous_program_mode
            cmp #HELP_MENU_MODE
            bne :+
                lda next_program_mode
                sta current_program_mode
                jmp Transition_Done
            :

            jsr EnterCanvasMode
            jmp Transition_Done
        :

        cmp #START_MENU_MODE
        bne :++

            lda previous_program_mode
            cmp #HELP_MENU_MODE
            bne :+
                lda next_program_mode
                sta current_program_mode
                jmp Transition_Done
            :

            jsr EnterStartMenuMode
            jmp Transition_Done
        :

        cmp #HELP_MENU_MODE
        bne :+
            jsr EnterHelpMenuMode
            jmp Transition_Done
        :

        cmp #LOAD_SAVE_MODE
        bne :+
            jsr EnterLoadSaveSelectionMenuMode
            jsr Transition_Done
        :

        cmp #SAVE_SAVE_MODE
        bne :+
            jsr EnterSaveSaveSelectionMenuMode
            jsr Transition_Done
        :

        cmp #SELECT_PLAYER_MODE
        bne :+
            jsr EnterSelectPlayerSelectionMenuMode
            jsr Transition_Done
        :

        Transition_Done:
            jsr LoadPalette
            rts 

    No_Transition_Yet:

    lda next_program_mode
    cmp #HELP_MENU_MODE
    bne :++
        lda scroll_y_position
        cmp #HELP_MENU_SCROLL_Y
        beq :+
            inc scroll_y_position
        :

        rts 

    :

    lda next_program_mode
    cmp #SAVE_SAVE_MODE
    bne :++
        lda previous_program_mode
        cmp #HELP_MENU_MODE
        bne :+
            rts 
        :
    :


    lda scroll_y_position
    cmp #NORMAL_SCROLL_Y
    beq :+
        dec scroll_y_position
    :

    rts 

.endproc
; Khine / BudgetArms


; Khine / BudgetArms
.proc CanvasLoop
    ; Play Gymnopédie (song 0) when entering canvas
    lda current_bg_song
    cmp #$00
    beq :+
        lda #$00
        jsr famistudio_music_play
        lda #$00
        sta current_bg_song
    :


    lda #$00
    sta current_player_index
    Loop_Players:
        jsr LoadPlayerProperties
        ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )

        jsr PollGamepad
        jsr HandleCanvasInput

        lda #OAM_OFFSCREEN
        sta oam + OAM_OFFSET_START_MENU_CURSOR + OAM_Y

        jsr UpdateSelectionOverlaysYPos

        jsr ConvertCursorPosToTilePositions
        jsr UpdateCursorSpritePosition

        jsr SavePlayerProperties

        inc current_player_index

        lda current_player_index
        cmp player_count
        bne Loop_Players

    jsr MagicPaletteCopyingSubroutine
    jsr UpdatePlayersCursorPalette

    rts 

.endproc
; Khine / BudgetArms

