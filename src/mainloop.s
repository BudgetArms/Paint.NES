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


.proc StartMenuLoop
    lda #$00
    sta current_player_index

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


; Khine
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
                rts
            :
            jsr EnterCanvasMode
            rts
        Next_Not_Canvas:

        cmp #START_MENU_MODE
        bne Next_Not_Start_Menu
            lda previous_program_mode
            cmp #HELP_MENU_MODE
            bne :+
                lda next_program_mode
                sta current_program_mode
                rts
            :
            jsr EnterStartMenuMode
            rts
        Next_Not_Start_Menu:

        cmp #HELP_MENU_MODE
        bne Next_Not_Help_Menu
            jsr EnterHelpMenuMode
            rts
        Next_Not_Help_Menu:
    No_Transition_Yet:

    lda next_program_mode
    cmp #HELP_MENU_MODE
    bne Next_Not_Help_Mode
        lda scroll_y_position
        cmp #HELP_MENU_SCROLL_Y
        beq :+
            inc scroll_y_position
        :
    Next_Not_Help_Mode:

    lda previous_program_mode
    cmp #HELP_MENU_MODE
    bne Previous_Not_Help_Mode
        lda scroll_y_position
        cmp #NORMAL_SCROLL_Y
        beq :+
            dec scroll_y_position
        :
    Previous_Not_Help_Mode:

    rts
.endproc
; Khine


; Khine
.proc CanvasLoop
    lda #$00
    sta current_player_index

    Loop_Players:
        jsr LoadPlayerProperties
        ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )

        jsr PollGamepad
        jsr HandleCanvasInput

        jsr ConvertCursorPosToTilePositions
        jsr UpdateCursorSpritePosition

        jsr SavePlayerProperties
    inc current_player_index
    lda current_player_index
    cmp player_count
    bne Loop_Players

    @Cursor:
    ;jsr UpdateCursorPositionOverlay
    ;jsr DrawShapeToolCursor

    jsr OverwriteAllBackgroundColorIndex
    rts
.endproc
; Khine