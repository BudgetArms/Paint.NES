;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
;*****************************************************************
.proc PollGamepad

        ;lda players_input
        ;sta last_frame_input
        ; strobe the gamepad to latch current button state
        lda #$01
        sta JOYPAD_STROBING
        lda #$00
        sta JOYPAD_STROBING    ; read 8 bytes from the interface at $4016

        ldx current_player_index
        lda #$01
        ;sta players_input, x
        sta player + P_INPUT
        sta player + P_INPUT
        lsr a
        Get_Input_Loop:
            lda JOYPAD1, x
            and #%00000011
            cmp #$01
            ;rol players_input, x
            rol player + P_INPUT
            bcc Get_Input_Loop

    rts

.endproc

;*****************************************************************
; HandleInput: Called every frame, after poll_gamepad. It's used to call 
; the Pressed, Released and Held functions with Help of macro's
; HandleButtonPressed, HandleButtonReleased and HandleButtonHeld.
;*****************************************************************

; Khine
.proc HandleStartMenuInput

    lda player + P_INPUT
    bne Input_Detected

    lda #$00 ; reset frame count to 0
    sta player + P_INPUT_FRAME_COUNT
    rts

    Input_Detected:
    ; Check if the frame count is 0
    lda player + P_INPUT_FRAME_COUNT
    beq Start_Checking_Input
        jmp Stop_Checking

    Start_Checking_Input:
    lda player + P_INPUT

    Check_PAD_A:
        cmp #PAD_A
        bne :+
            jsr PlayMenuSelectSFX
            jsr ConfirmStartMenuSelection
        jmp Stop_Checking
        :

    Check_PAD_UP:
        cmp #PAD_UP
        bne :+
            jsr PlayMenuSelectSFX
            jsr MoveStartMenuCursorUp
        jmp Stop_Checking
        :

    Check_PAD_DOWN:
        cmp #PAD_DOWN
        bne :+
            jsr PlayMenuSelectSFX
            jsr MoveStartMenuCursorDown
        jmp Stop_Checking
        :

    Stop_Checking:
            jsr IncreaseButtonHeldFrameCount
        rts

.endproc
; Khine


; Khine / BudgetArms
.proc HandleHelpMenuInput

    lda player + P_INPUT
    bne Input_Detected

    lda #$00 ; reset frame count to 0
    sta player + P_INPUT_FRAME_COUNT
    rts

    Input_Detected:
    ; Check if the frame count is 0
    lda player + P_INPUT_FRAME_COUNT
    beq Start_Checking_Input
        jmp Stop_Checking

    Start_Checking_Input:
    lda player + P_INPUT

    Check_PAD_START:
        cmp #PAD_START
        bne :+
            ; Override current mode as canvas
            lda #CANVAS_MODE
            sta current_program_mode
            jsr PlayMenuSelectSFX
            TransitionToMode #START_MENU_MODE

            jsr ResetCanvasPalette
            jmp Stop_Checking
        :

    Check_PAD_A:
        cmp #PAD_A
        bne :+
            jsr PlayMenuSelectSFX

            ; if you came from the main menu, you cannot store a canvas
            lda previous_program_mode
            cmp #START_MENU_MODE
            beq No_Canvas_To_Save

                TransitionInstantlyToMode #SAVE_SAVE_MODE
                jmp Stop_Checking

            No_Canvas_To_Save:
            jmp Stop_Checking
        :

    Check_PAD_B:
        cmp #PAD_B
        bne :+
            jsr PlayMenuSelectSFX
            ; cannot use continueprevious mode bc
            ; if help menu -> save menu -> help menu, then previous mode would be save menu
            ; and not canvas_mode
            ; jsr ContinuePreviousMode

            ; if previous mode is start menu, then go to start_menu_mode
            ; else, go to canvas_mode
            lda previous_program_mode
            cmp #START_MENU_MODE
            bne Previous_Mode_Not_Start_Mode
                TransitionToMode #START_MENU_MODE
                jmp Stop_Checking

            Previous_Mode_Not_Start_Mode:

            TransitionToMode #CANVAS_MODE
            jmp Stop_Checking

        :

    Stop_Checking:
    jsr IncreaseButtonHeldFrameCount

    rts 

.endproc
; Khine / BudgetArms


; BudgetArms
.proc HandleLoadSaveMenuInput

    lda player + P_INPUT
    bne Input_Detected

    lda #$00 ; reset frame count to 0
    sta player + P_INPUT_FRAME_COUNT
    rts 

    Input_Detected:
    ; Check if the frame count is 0
    lda player + P_INPUT_FRAME_COUNT
    beq Start_Checking_Input
        jmp Stop_Checking

    Start_Checking_Input:
    lda player + P_INPUT

    Check_PAD_A:
        cmp #PAD_A
        bne :+
            jsr ConfirmLoadSaveMenuSelection
            jmp Stop_Checking
        :

    Check_PAD_UP:
        cmp #PAD_UP
        bne :+
            jsr MoveLoadSaveMenuCursorUp
            jmp Stop_Checking
        :

    Check_PAD_DOWN:
        cmp #PAD_DOWN
        bne :+
            jsr MoveLoadSaveMenuCursorDown
            jmp Stop_Checking
        :

    Stop_Checking:
        jsr IncreaseButtonHeldFrameCount
        rts 

.endproc
; BudgetArms


; BudgetArms
.proc HandleSaveSaveMenuInput

    lda player + P_INPUT
    bne Input_Detected

    lda #$00 ; reset frame count to 0
    sta player + P_INPUT_FRAME_COUNT
    rts 

    Input_Detected:
    ; Check if the frame count is 0
    lda player + P_INPUT_FRAME_COUNT
    beq Start_Checking_Input
        jmp Stop_Checking

    Start_Checking_Input:
    lda player + P_INPUT

    Check_PAD_A:
        cmp #PAD_A
        bne :+
            jsr ConfirmSaveSaveMenuSelection
            jmp Stop_Checking
        :

    Check_PAD_UP:
        cmp #PAD_UP
        bne :+
            jsr MoveSaveSaveMenuCursorUp
            jmp Stop_Checking
        :

    Check_PAD_DOWN:
        cmp #PAD_DOWN
        bne :+
            jsr MoveSaveSaveMenuCursorDown
            jmp Stop_Checking
        :

    Stop_Checking:
        jsr IncreaseButtonHeldFrameCount
        rts 

.endproc
; BudgetArms


; BudgetArms
.proc HandleSelectPlayerMenuInput

    lda player + P_INPUT
    bne Input_Detected

    lda #$00 ; reset frame count to 0
    sta player + P_INPUT_FRAME_COUNT
    rts 

    Input_Detected:
    ; Check if the frame count is 0
    lda player + P_INPUT_FRAME_COUNT
    beq Start_Checking_Input
        jmp Stop_Checking

    Start_Checking_Input:
    lda player + P_INPUT

    Check_PAD_A:
        cmp #PAD_A
        bne :+
            jsr ConfirmSelectPlayerMenuSelection
            jmp Stop_Checking
        :

    Check_PAD_UP:
        cmp #PAD_UP
        bne :+
            jsr MoveSelectPlayerMenuCursorUp
            jmp Stop_Checking
        :

    Check_PAD_DOWN:
        cmp #PAD_DOWN
        bne :+
            jsr MoveSelectPlayerMenuCursorDown
            jmp Stop_Checking
        :

    Stop_Checking:
        jsr IncreaseButtonHeldFrameCount
        rts 

.endproc
; BudgetArms


; Joren / Khine
.proc HandleCanvasInput

    lda player + P_INPUT
    bne Input_Detected

    lda #$00 ; reset frame count to 0
    sta player + P_INPUT_FRAME_COUNT
    rts

    Input_Detected:
    ; Check if the frame count is 0
    lda player + P_INPUT_FRAME_COUNT
    beq Start_Checking_Input
        jmp Stop_Checking

    Start_Checking_Input:
    lda player + P_INPUT

    Check_PAD_A:
        cmp #PAD_A
        bne Check_PAD_A_LEFT
            jsr UseSelectedTool
        jmp Stop_Checking
    
    Check_PAD_A_LEFT:
        cmp #PAD_A_LEFT
        bne Check_PAD_A_RIGHT
            jsr UseSelectedTool
            jsr MoveCursorLeft
        jmp Stop_Checking

    Check_PAD_A_RIGHT:
        cmp #PAD_A_RIGHT
        bne Check_PAD_A_UP
            jsr UseSelectedTool
            jsr MoveCursorRight
        jmp Stop_Checking

    Check_PAD_A_UP:
        cmp #PAD_A_UP
        bne Check_PAD_A_DOWN
            jsr UseSelectedTool
            jsr MoveCursorUp
        jmp Stop_Checking

    Check_PAD_A_DOWN:
        cmp #PAD_A_DOWN
        bne Check_PAD_A_UP_LEFT
            jsr UseSelectedTool
            jsr MoveCursorDown
        jmp Stop_Checking

    Check_PAD_A_UP_LEFT:
        cmp #PAD_A_UP_LEFT
        bne Check_PAD_A_DOWN_LEFT
            jsr UseSelectedTool
            jsr MoveCursorUp
            jsr MoveCursorLeft
        jmp Stop_Checking

    Check_PAD_A_DOWN_LEFT:
        cmp #PAD_A_DOWN_LEFT
        bne Check_PAD_A_UP_RIGHT
            jsr UseSelectedTool
            jsr MoveCursorDown
            jsr MoveCursorLeft
        jmp Stop_Checking

    Check_PAD_A_UP_RIGHT:
        cmp #PAD_A_UP_RIGHT
        bne Check_PAD_A_DOWN_RIGHT
            jsr UseSelectedTool
            jsr MoveCursorUp
            jsr MoveCursorRight
        jmp Stop_Checking

    Check_PAD_A_DOWN_RIGHT:
        cmp #PAD_A_DOWN_RIGHT
        bne Check_PAD_SELECT
            jsr UseSelectedTool
            jsr MoveCursorDown
            jsr MoveCursorRight
        jmp Stop_Checking

    Check_PAD_SELECT:
        cmp #PAD_SELECT
        bne Check_PAD_SELECT_LEFT
        ;code for when SELECT is pressed alone
        jmp Stop_Checking

    Check_PAD_SELECT_LEFT:
        cmp #PAD_SELECT_LEFT
        bne Check_PAD_SELECT_RIGHT
        
            jsr DecreaseChrTileIndex
        jmp Stop_Checking

    Check_PAD_SELECT_RIGHT:
        cmp #PAD_SELECT_RIGHT
        bne Check_PAD_SELECT_UP
        
            jsr IncreaseChrTileIndex
        jmp Stop_Checking

    Check_PAD_SELECT_UP:
        cmp #PAD_SELECT_UP
        bne Check_PAD_SELECT_DOWN
        
            jsr IncreaseColorValueForSelectedTile
        jmp Stop_Checking

    Check_PAD_SELECT_DOWN:
        cmp #PAD_SELECT_DOWN
        bne Check_PAD_START
        
            jsr DecreaseColorValueForSelectedTile
        jmp Stop_Checking

    Check_PAD_START:
        cmp #PAD_START
        bne Check_PAD_START_LEFT
        ;code for when START is pressed alone
        jmp Stop_Checking

    Check_PAD_START_LEFT:
        cmp #PAD_START_LEFT
        bne Check_PAD_START_RIGHT
            jsr DecreaseToolSelection
        jmp Stop_Checking

    Check_PAD_START_RIGHT:
        cmp #PAD_START_RIGHT
        bne Check_PAD_START_UP
            jsr IncreaseToolSelection
        jmp Stop_Checking

    Check_PAD_START_UP:
        cmp #PAD_START_UP
        bne Check_PAD_START_DOWN
        jmp Stop_Checking

    Check_PAD_START_DOWN:
        cmp #PAD_START_DOWN
        bne :+
        jmp Stop_Checking
        :

    Check_PAD_START_SELECT:
        cmp #PAD_START_SELECT
        bne :+
            ;jsr EnterHelpMenuMode
            TransitionToMode #HELP_MENU_MODE

            jsr UpdateCanvasPalette

        jmp Stop_Checking
        :

    Check_PAD_LEFT:
        cmp #PAD_LEFT
        bne Check_PAD_RIGHT
            jsr MoveCursorLeft
        jmp Stop_Checking

    Check_PAD_RIGHT:
        cmp #PAD_RIGHT
        bne Check_PAD_UP
            jsr MoveCursorRight
        jmp Stop_Checking

    Check_PAD_UP:
        cmp #PAD_UP
        bne Check_PAD_DOWN

            jsr MoveCursorUp
        jmp Stop_Checking

    Check_PAD_DOWN:
        cmp #PAD_DOWN
        bne Check_PAD_UP_LEFT

            jsr MoveCursorDown
        jmp Stop_Checking
        
    Check_PAD_UP_LEFT:
        cmp #PAD_UP_LEFT
        bne Check_PAD_DOWN_LEFT
            jsr MoveCursorUp
            jsr MoveCursorLeft
        jmp Stop_Checking

    Check_PAD_DOWN_LEFT:
        cmp #PAD_DOWN_LEFT
        bne Check_PAD_UP_RIGHT
            jsr MoveCursorDown
            jsr MoveCursorLeft
        jmp Stop_Checking

    Check_PAD_UP_RIGHT:
        cmp #PAD_UP_RIGHT
        bne Check_PAD_DOWN_RIGHT
            jsr MoveCursorUp
            jsr MoveCursorRight
        jmp Stop_Checking

    Check_PAD_DOWN_RIGHT:
        cmp #PAD_DOWN_RIGHT
        bne Check_PAD_B
            jsr MoveCursorDown
            jsr MoveCursorRight
        jmp Stop_Checking

    Check_PAD_B:
        cmp #PAD_B
        bne Stop_Checking
            jsr ChangeCursorProperty
        jmp Stop_Checking

    Stop_Checking:
            jsr IncreaseButtonHeldFrameCount
        rts
.endproc
; Joren / Khine


; Khine / BudgetArms
.proc ChangeCursorProperty

    lda player + P_SELECTED_TOOL

    cmp #SHAPE_TOOL_SELECTED
    bne :+
        jsr ChangeShapeToolType
        rts
    :

    cmp #BRUSH_TOOL_SELECTED
    bne :+
        jsr CycleCursorSize
        rts
    :

    cmp #ERASER_TOOL_SELECTED
    bne :+
        jsr CycleCursorSize
        rts
    :

    rts
.endproc
; Khine / BudgetArms


; BudgetArms
.proc UseSelectedTool
    lda player + P_SELECTED_TOOL

    Check_Brush_Tool:
    cmp #BRUSH_TOOL_SELECTED
    bne :+
        ChangeToolFlag #BRUSH_TOOL_ON
        rts
    :

    Check_Eraser_Tool:
    cmp #ERASER_TOOL_SELECTED
    bne :+
        ChangeToolFlag #BRUSH_TOOL_ON
        ChangeToolFlag #ERASER_TOOL_ON
        rts 
    :

    Check_Fill_Tool:
    cmp #FILL_TOOL_SELECTED
    bne :+
        jsr UseFillTool
        rts
    :

    Check_Shape_Tool:
    cmp #SHAPE_TOOL_SELECTED
    bne :+
        jsr UseShapeTool
        rts 
    :

    Check_Clear_Tool:
    cmp #CLEAR_TOOL_SELECTED
    bne :+
        jsr UseClearCanvasTool
        rts 
    :

    rts
.endproc
; BudgetArms
