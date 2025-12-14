mainloop:
    ; skip reading controls if and change has not been drawn
    lda nmi_ready
    cmp #0
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

    cmp #LOAD_SAVE_SELECTION_MODE
    bne :+
        jsr LoadSaveMenuLoop
        jmp End_Of_Loop
    :

    cmp #SAVE_SAVE_SELECTION_MODE
    bne :+
        jsr SaveSaveMenuLoop
        jmp End_Of_Loop
    :

    cmp #SELECT_PLAYER_SELECTION_MODE
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
    lda #1
    sta nmi_ready
    jmp mainloop


; Khine
.proc StartMenuLoop
    lda #$00
    sta current_player_index

    ; Play CocoMelon (song 1) when entering start menu
    lda current_bg_song
    cmp #1
    beq @skip_music_start
        lda #1
        jsr famistudio_music_play
        lda #1
        sta current_bg_song
        lda #0
        sta menu_music_started  ; Reset this when leaving menu
    @skip_music_start:

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
        bne Next_Not_Canvas

            lda previous_program_mode
            cmp #HELP_MENU_MODE
            bne :+
                lda next_program_mode
                sta current_program_mode


                jmp Transition_Done
            :

            jsr EnterCanvasMode
            jmp Transition_Done
        Next_Not_Canvas:

        cmp #START_MENU_MODE
        bne Next_Not_Start_Menu

            lda previous_program_mode
            cmp #HELP_MENU_MODE
            bne :+
                lda next_program_mode
                sta current_program_mode
                jmp Transition_Done
            :

            jsr EnterStartMenuMode
            jmp Transition_Done
        Next_Not_Start_Menu:

        cmp #HELP_MENU_MODE
        bne Next_Not_Help_Menu
            jsr EnterHelpMenuMode
            jmp Transition_Done
        Next_Not_Help_Menu:

        cmp #LOAD_SAVE_SELECTION_MODE
        bne Next_Not_Load_Save_Selection_Menu
            jsr EnterLoadSaveSelectionMenuMode
            jsr Transition_Done
        Next_Not_Load_Save_Selection_Menu:

        cmp #SAVE_SAVE_SELECTION_MODE
        bne Next_Not_Save_Save_Selection_Menu
            jsr EnterSaveSaveSelectionMenuMode
            jsr Transition_Done
        Next_Not_Save_Save_Selection_Menu:

        cmp #SELECT_PLAYER_SELECTION_MODE
        bne Next_Not_Select_Player_Selection_Menu
            jsr EnterSelectPlayerSelectionMenuMode
            jsr Transition_Done
        Next_Not_Select_Player_Selection_Menu:

        Transition_Done:
            jsr LoadPalette
            rts 

    No_Transition_Yet:

    lda next_program_mode
    cmp #HELP_MENU_MODE
    bne Next_Not_Help_Mode
        lda scroll_y_position
        cmp #HELP_MENU_SCROLL_Y
        beq :+
            inc scroll_y_position
            rts
        :
    Next_Not_Help_Mode:

    lda next_program_mode
    cmp #SAVE_SAVE_SELECTION_MODE
    bne Next_Not_Save_Save_Mode
        lda previous_program_mode
        cmp #HELP_MENU_MODE
        bne :+
            rts 
        :
    Next_Not_Save_Save_Mode:


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
    lda #$00
    sta current_player_index

    ; Play Gymnopédie (song 0) when entering canvas
    lda current_bg_song
    cmp #0
    beq @skip_music_start
        lda #0
        jsr famistudio_music_play
        lda #0
        sta current_bg_song
    @skip_music_start:

    ; Reset menu_music_started so CocoMelon can play again next time
    ; lda #0
    ; sta menu_music_started

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
        jsr DrawShapeToolCursor

        jsr SavePlayerProperties
    inc current_player_index
    lda current_player_index
    cmp player_count
    bne Loop_Players

    @Cursor:

    jsr MagicPaletteCopyingSubroutine

    rts 

.endproc
; Khine / BudgetArms

