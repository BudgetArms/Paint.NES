.proc UseTextTool
    lda player + P_TEXT_TOOL_IN_USE

    cmp #TEXT_TOOL_NOT_USED
    bne :+
        lda #TEXT_TOOL_IN_USE
        sta player + P_TEXT_TOOL_IN_USE

        jsr EnableTextToolKeyboard
        inc text_tool_state
        rts
    :

    lda #TEXT_TOOL_NOT_USED
    sta player + P_TEXT_TOOL_IN_USE

    dec text_tool_state
    jsr DisableTextToolKeyboard
    rts
.endproc

.proc EnableTextToolKeyboard
    lda text_tool_state
    cmp #TEXT_TOOL_NOT_USED
    beq :+
        rts
    :

    jsr EnableKeyboardCursor
    jsr PPUOff

    ChangePPUNameTableAddr OVERLAY_BOTTOM_UI_OFFSET

    ldx #OVERLAY_BOTTOM_UI_SIZE
    ldy #$00
    Loop:
        lda Text_Tool_Keyboard, y
        sta PPU_DATA
        iny
        dex
    bne Loop
    rts
.endproc

.proc DisableTextToolKeyboard
    lda text_tool_state
    cmp #TEXT_TOOL_NOT_USED
    beq :+
        rts
    :

    jsr DisableKeyboardCursor
    jsr PPUOff

    ChangePPUNameTableAddr OVERLAY_BOTTOM_UI_OFFSET

    ldx #OVERLAY_BOTTOM_UI_SIZE
    ldy #$00
    Loop:
        lda Canvas_Bottom_UI, y
        sta PPU_DATA
        iny
        dex
    bne Loop

    jsr RefreshToolTextOverlay
    rts
.endproc


.proc EnableKeyboardCursor
    lda player + P_INDEX
    cmp #PLAYER_1
    bne :+
        lda #KEYBOARD_START_Y
        sta oam + OAM_OFFSET_KEYBOARD_P1_CURSOR + OAM_Y
        lda #TILEINDEX_CURSOR_NORMAL
        sta oam + OAM_OFFSET_KEYBOARD_P1_CURSOR + OAM_TILE
        lda #PLAYER_1_OVERLAY_ATTR
        sta oam + OAM_OFFSET_KEYBOARD_P1_CURSOR + OAM_ATTR
        lda #KEYBOARD_START_X
        sta oam + OAM_OFFSET_KEYBOARD_P1_CURSOR + OAM_X
        rts
    :

    cmp #PLAYER_2
    bne :+
        lda #KEYBOARD_START_Y
        sta oam + OAM_OFFSET_KEYBOARD_P2_CURSOR + OAM_Y
        lda #TILEINDEX_CURSOR_NORMAL
        sta oam + OAM_OFFSET_KEYBOARD_P2_CURSOR + OAM_TILE
        lda #PLAYER_2_OVERLAY_ATTR
        sta oam + OAM_OFFSET_KEYBOARD_P2_CURSOR + OAM_ATTR
        lda #KEYBOARD_START_X
        sta oam + OAM_OFFSET_KEYBOARD_P2_CURSOR + OAM_X
        rts
    :

.endproc


.proc DisableKeyboardCursor
    lda player + P_INDEX

    cmp #PLAYER_1
    bne :+
        lda #OAM_OFFSCREEN
        sta oam + OAM_OFFSET_KEYBOARD_P1_CURSOR + OAM_Y
        rts
    :

    cmp #PLAYER_2
    bne :+
        lda #OAM_OFFSCREEN
        sta oam + OAM_OFFSET_KEYBOARD_P2_CURSOR + OAM_Y
        rts
    :
.endproc