mainloop:
    ; skip reading controls if and change has not been drawn
    lda nmi_ready
    cmp #0
    bne mainloop

    lda #$00
    sta current_player_index

    Loop_Players:
        jsr LoadPlayerProperties
        ; read the gamepad (updates players_input, input_pressed_this_frame and input_released_this_frame )
        jsr PollGamepad
        jsr HandleInput

        jsr ConvertCursorPosToTilePositions
        ;jsr UpdateCursorPositionFromTilePosition
        jsr UpdateCursorSpritePosition

        jsr SavePlayerProperties
    inc current_player_index
    lda current_player_index
    cmp player_count
    bne Loop_Players

    @Cursor:
    jsr UpdateCursorPositionOverlay
    jsr DrawShapeToolCursor

    jsr OverwriteAllBackgroundColorIndex

    ; ensure our changes are rendered
    lda #1
    sta nmi_ready
    jmp mainloop
