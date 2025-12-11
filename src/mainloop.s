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

    cmp #HELP_MENU
    bne :+
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
