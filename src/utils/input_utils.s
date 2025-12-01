;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
;*****************************************************************
.proc PollGamepad

    ; strobe the gamepad to latch current button state
    lda #1
    sta JOYPAD1
    lda #0
    sta JOYPAD1
    ; read 8 bytes from the interface at $4016
    ldx #8

    poll_loop:
        pha
        lda JOYPAD1
        ; combine low two bits and store in carry bit
        and #%00000011
        cmp #%00000001
        pla
        ; rotate carry into gamepad variable
        ror
        dex
        bne poll_loop

    sta input

    rts

.endproc

;*****************************************************************
; HandleInput: Called every frame, after poll_gamepad. It's used to call 
; the Pressed, Released and Held functions with Help of macro's
; HandleButtonPressed, HandleButtonReleased and HandleButtonHeld.
;*****************************************************************

; BudgetArms
.proc HandleInput

    ;input holding = 
    ; check if input last frame = same as input current frame

    ; if in menu
    lda #01
    cmp #MAIN_MENU
    bne Not_In_Menu

        jsr HandleMenuInput
        rts 

    Not_In_Menu:

    ; else
    ; if in canvas
    lda scroll_y_position
    cmp #CANVAS_MODE
    bne Not_In_Canvas

        jsr HandleCanvasInput
        rts 

    Not_In_Canvas:
    rts 
.endproc

; BudgetArms
.proc HandleMenuInput

    rts 

.endproc

; BudgetArms
.proc HandleCanvasInput

    lda input
    bne Check_PAD_A

    lda #$00 ; reset frame count to 0
    sta frame_count
    rts ; if no buttons are pressed, skip all checks.

    Check_PAD_A:
        cmp #PAD_A
        bne Check_PAD_A_LEFT
        jsr HandleCursorPressedA
        jmp StopChecking
    
    Check_PAD_A_LEFT:
        cmp #PAD_A_LEFT
        bne Check_PAD_A_RIGHT
        jsr HandleCursorPressedA
        jsr MoveCursorLeft
        jmp StopChecking

    Check_PAD_A_RIGHT:
        cmp #PAD_A_RIGHT
        bne Check_PAD_A_UP
        jsr HandleCursorPressedA
        jsr MoveCursorRight
        jmp StopChecking

    Check_PAD_A_UP:
        cmp #PAD_A_UP
        BNE Check_PAD_A_DOWN
        jsr HandleCursorPressedA
        jsr MoveCursorUp
        jmp StopChecking

    Check_PAD_A_DOWN:
        cmp #PAD_A_DOWN
        bne Check_PAD_A_UP_LEFT
        jsr HandleCursorPressedA
        jsr HandleCursorPressedA
        jsr MoveCursorDown
        jmp StopChecking

    Check_PAD_A_UP_LEFT:
        cmp #PAD_A_UP_LEFT
        bne Check_PAD_A_DOWN_LEFT
        jsr HandleCursorPressedA
        jsr MoveCursorUp
        jsr MoveCursorLeft
        jmp StopChecking

    Check_PAD_A_DOWN_LEFT:
        cmp #PAD_A_DOWN_LEFT
        bne Check_PAD_A_UP_RIGHT
        jsr HandleCursorPressedA
        jsr MoveCursorDown
        jsr MoveCursorLeft
        jmp StopChecking

    Check_PAD_A_UP_RIGHT:
        cmp #PAD_A_UP_RIGHT
        bne Check_PAD_A_DOWN_RIGHT
        jsr HandleCursorPressedA
        jsr MoveCursorUp
        jsr MoveCursorRight
        jmp StopChecking

    Check_PAD_A_DOWN_RIGHT:
        cmp #PAD_A_DOWN_RIGHT
        bne Check_PAD_SELECT
        jsr HandleCursorPressedA
        jsr MoveCursorDown
        jsr MoveCursorRight
        jmp StopChecking

    Check_PAD_SELECT:
        cmp #PAD_SELECT
        bne Check_PAD_SELECT_LEFT
        ;code for when SELECT is pressed alone
        jmp StopChecking

    Check_PAD_SELECT_LEFT:
        cmp #PAD_SELECT_LEFT
        bne Check_PAD_SELECT_RIGHT
        
        jsr DecreaseChrTileIndex
        jmp StopChecking

    Check_PAD_SELECT_RIGHT:
        cmp #PAD_SELECT_RIGHT
        bne Check_PAD_SELECT_UP
        
        jsr IncreaseChrTileIndex
        jmp StopChecking

    Check_PAD_SELECT_UP:
        cmp #PAD_SELECT_UP
        bne Check_PAD_SELECT_DOWN
        
        jsr IncreaseColorPalleteIndex
        jmp StopChecking

    Check_PAD_SELECT_DOWN:
        cmp #PAD_SELECT_DOWN
        bne Check_PAD_START
        
        jsr DecreaseColorPalleteIndex
        jmp StopChecking

    Check_PAD_START:
        cmp #PAD_START
        bne Check_PAD_START_LEFT
        ;code for when START is pressed alone
        jmp StopChecking

    Check_PAD_START_LEFT:
        cmp #PAD_START_LEFT
        bne Check_PAD_START_RIGHT
        jsr DecreaseToolSelection
        jmp StopChecking

    
    Check_PAD_START_RIGHT:
        cmp #PAD_START_RIGHT
        bne Check_PAD_START_UP
        jsr IncreaseToolSelection
        jmp StopChecking


    Check_PAD_START_UP:
        cmp #PAD_START_UP
        bne Check_PAD_START_DOWN
        jmp StopChecking


    Check_PAD_START_DOWN:
        cmp #PAD_START_DOWN
        bne Check_PAD_LEFT
        jmp StopChecking

    Check_PAD_LEFT:
        cmp #PAD_LEFT
        bne Check_PAD_RIGHT
        jsr MoveCursorLeft
        jmp StopChecking

    Check_PAD_RIGHT:
        cmp #PAD_RIGHT
        bne Check_PAD_UP
        jsr MoveCursorRight
        jmp StopChecking

    Check_PAD_UP:
        cmp #PAD_UP
        bne Check_PAD_DOWN
        lda scroll_y_position
        cmp #CANVAS_MODE
        bne MoveUpInMenu
        ;InCanvas:
        jsr MoveCursorUp
        jmp StopChecking

        MoveUpInMenu:
        jsr MoveSelectionStarUp
        
        jmp StopChecking

    Check_PAD_DOWN:
        cmp #PAD_DOWN
        bne Check_PAD_UP_LEFT
        lda scroll_y_position
        cmp #CANVAS_MODE
        bne MoveDownInMenu
        ;InCanvas:
        jsr MoveCursorDown
        jmp StopChecking

        MoveDownInMenu:
        jsr MoveSelectionStarDown
        
        jmp StopChecking

    Check_PAD_UP_LEFT:
        cmp #PAD_UP_LEFT
        bne Check_PAD_DOWN_LEFT
        jsr MoveCursorUp
        jsr MoveCursorLeft
        jmp StopChecking

    Check_PAD_DOWN_LEFT:
        cmp #PAD_DOWN_LEFT
        bne Check_PAD_UP_RIGHT
        jsr MoveCursorDown
        jsr MoveCursorLeft
        jmp StopChecking

    Check_PAD_UP_RIGHT:
        cmp #PAD_UP_RIGHT
        bne Check_PAD_DOWN_RIGHT
        jsr MoveCursorUp
        jsr MoveCursorRight
        jmp StopChecking

    Check_PAD_DOWN_RIGHT:
        cmp #PAD_DOWN_RIGHT
        bne Check_PAD_B
        jsr MoveCursorDown
        jsr MoveCursorRight
        jmp StopChecking

    Check_PAD_B:
        cmp #PAD_B
        bne StopChecking
        jsr HandleCursorPressedB
        jmp StopChecking

    ; Check_REST:               ; Might need this later
        ; jmp StopChecking


    StopChecking:
        jsr IncButtonHeldFrameCount
        rts
    

.endproc

; BudgetArms
.proc HandleCursorPressedA

    lda selected_tool

    ;Check_TOOL_PENCIL:
    cmp #PENCIL_TOOL_ACTIVATED
    bne Check_TOOL_ERASER
    ChangeToolAttr #BRUSH_TOOL_ON
    RTS

    Check_TOOL_ERASER:
    cmp #ERASER_TOOL_ACTIVATED
    bne Check_TOOL_FILL
    ChangeToolAttr #ERASER_TOOL_ON
    RTS

    Check_TOOL_FILL:
    cmp #FILL_TOOL_ACTIVATED
    bne Check_TOOL_CLEAR
    ChangeToolAttr #FILL_TOOL_ON
    RTS

    Check_TOOL_CLEAR:
    cmp #CLEAR_TOOL_ACTIVATED
    bne Check_TOOL_NEXT
    ChangeToolAttr #CLEAR_TOOL_ON
    RTS
    
    Check_TOOL_NEXT:
    rts 

    lda tool_mode
    cmp #FILL_MODE
    beq In_Fill_Mode

    lda tool_mode
    cmp #SHAPE_MODE
    beq In_Shape_Mode

        rts 

    In_Fill_Mode:
        ChangeToolAttr #FILL_TOOL_ON
        rts 

    In_Shape_Mode:
        ChangeToolAttr #SHAPE_TOOL_ON
        rts 


.endproc

; BudgetArms
.proc HandleCursorPressedB

    ; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet

    jsr CycleBrushSize

    lda cursor_type     ; load cursor type
    cmp #TYPE_CURSOR_MAXIMUM
    bne Not_Maximum_Size

        ; Maximum size
        lda #TYPE_CURSOR_MINIMUM
        sta cursor_type

        ; reset small cursor_small_direction always even
        ; if the minimum cursor type isn't small_cursor
        lda DIR_CURSOR_SMALL_TOP_LEFT
        sta cursor_small_direction

        Not_Maximum_Size:

        ; increment accumulator
        sec 
        adc #$00

        ; set new cursor_type
        sta cursor_type

    DontRegisterYet:
        rts 


.endproc