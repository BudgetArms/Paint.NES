;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
;*****************************************************************
.proc poll_gamepad
    lda current_input
    sta last_frame_input
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

    sta current_input

    lda last_frame_input
    eor #%11111111
    and current_input
    sta input_pressed_this_frame

    lda current_input
    eor #%11111111
    and last_frame_input
    sta input_released_this_frame

    lda last_frame_input
    and current_input
    eor input_released_this_frame
    sta input_holding_this_frame


    rts
.endproc



;*****************************************************************
;                       Macro's
;*****************************************************************

; BudgetArms
.macro HandleButtonPressed buttonMask, handleFunction

    .local exit_macro

    ;lda input_pressed_this_frame
    ;eor #buttonMask
    ;bne 

    ;exit exit_macro:



    ; to make labels work in macro's
    .local exit_macro 

    ; Check button is pressed
    lda input_pressed_this_frame
    and #buttonMask
    beq exit_macro
        ; code for when button is pressed
        jsr handleFunction

    exit_macro:

.endmacro



; BudgetArms
.macro HandleButtonReleased buttonMask, handleFunction

    ; to make labels work in macro's
    .local exit_macro 

    ; Check button is released
    lda input_released_this_frame
    and #buttonMask
    beq exit_macro
        ; code for when button is released
        jsr handleFunction

    exit_macro:

.endmacro


; BudgetArms
.macro HandleButtonHeld buttonMask, frameCounterHold, holdFramesThreshold, handleFunction 

    ; to make labels work in macro's
    .local exit_macro 

    ; Check button is holding
    lda input_holding_this_frame
    and #buttonMask
    beq exit_macro
    

        inc frameCounterHold
        lda frameCounterHold

        ; if frameCounterHold higher than holdFramesThreshold 
        ; check with carry flag
        cmp #holdFramesThreshold
        bcc exit_macro

        @press_button:
            jsr handleFunction  ; call function
            ResetFrameCounterHolder frameCounterHold ; reset frameCounter 


    exit_macro:

.endmacro


; BudgetArms
.macro HandleButtonCombo buttonMask1, buttonMask2, holdFramesThreshold, frameCounterHold, handleFunction

    ; to make labels work in macro's
    .local exit_macro 

    ; Check button is holding
    lda #buttonMask1
    ora #buttonMask2
    eor input_holding_this_frame
    bne exit_macro

        lda #$01
        sta is_combo_used


        inc frameCounterHold
        lda frameCounterHold

        ; if frameCounterHold higher than holdFramesThreshold 
        ; check with carry flag
        cmp #holdFramesThreshold
        bcc exit_macro


        @press_button:
            jsr handleFunction  ; call function
            ResetFrameCounterHolder frameCounterHold ; reset frameCounter 
            lda #$01
            sta is_combo_used
            ;jmp Test

    exit_macro:

.endmacro




;*****************************************************************
; HandleInput: Called every frame, after poll_gamepad. It's used to call 
; the Pressed, Released and Held functions with Help of macro's
; HandleButtonPressed, HandleButtonReleased and HandleButtonHeld.
;*****************************************************************

; BudgetArms
.proc HandleInput
;CheckCombos:
    ;Joren
    lda #PAD_START
    ora #PAD_LEFT ;create and store a mask for the start + left button being pressed together
    eor input_holding_this_frame ;XOR the current input with start+left mask
    bne not_pressed_StartAndLeft
    ;code for when Start + Left is pressed together
        lda newPalleteColor
        clc
        adc #$01
        sta newPalleteColor
        JMP StopCheckingPressedButtons

    not_pressed_StartAndLeft:
	; check StartAndRight
    lda #PAD_START
    ora #PAD_RIGHT ;create and store a mask for the start + left button being pressed together
    eor input_holding_this_frame ;XOR the current input with start+left mask
    bne CheckUpAndStart ; start checking other buttons
        ;code for when Start + right is pressed together
        lda newPalleteColor
        clc
        sbc #$01
        sta newPalleteColor
        JMP StopCheckingPressedButtons

    CheckUpAndStart:
    lda #PAD_START
    ora #PAD_UP ;create and store a mask for the start + left button being pressed together
    eor input_pressed_this_frame ;XOR the current input with start+left mask
    bne CheckDownAndStart
        ;code for when Start + up is pressed together
        
        JMP StopCheckingPressedButtons

    CheckDownAndStart:
    lda #PAD_START
    ora #PAD_DOWN ;create and store a mask for the start + left button being pressed together
    eor input_pressed_this_frame ;XOR the current input with start+left mask
    bne CheckNonComboButtons
        ;code for when Start + down is pressed together
        JMP StopCheckingPressedButtons




CheckNonComboButtons:

    lda input_pressed_this_frame
    TXA ;for quick acces later

    ;eor PAD_START

    eor PAD_A
    bne Check_Pad_B ; if a  is not pressed
    jmp HandleCursorPressedA ; if a is pressed
    JMP StopCheckingPressedButtons

    Check_Pad_B:
    TXA ; lda input_pressed_this_frame
    eor PAD_B
    bne Check_Pad_Dpad
    jmp HandleCursorPressedB
    JMP StopCheckingPressedButtons


    Check_Pad_Dpad:
    TXA ; lda input_pressed_this_frame
    eor PAD_RIGHT
    bne Check_Pad_Up
    jmp HandleCursorPressedRight
    rts
    ;JMP StopCheckingPressedButtons

    Check_Pad_Up:
    TXA ; lda input_pressed_this_frame
    eor PAD_UP
    bne Check_Pad_Left
    jmp HandleCursorPressedUp
    rts
;    JMP StopCheckingPressedButtons

    Check_Pad_Left:
    TXA ; lda input_pressed_this_frame
    eor PAD_LEFT
    bne Check_Pad_Down
    jmp HandleCursorPressedLeft
    rts
    ;JMP StopCheckingPressedButtons

    Check_Pad_Down:
    TXA ; lda input_pressed_this_frame
    eor PAD_DOWN
    bne Check_Pad_Select
    jmp HandleCursorPressedDown
    rts
    ;JMP StopCheckingPressedButtons

    Check_Pad_Select:
    TXA ; lda input_pressed_this_frame
    eor PAD_SELECT
    bne Check_Pad_Start
    jmp HandleCursorPressedStart
    JMP StopCheckingPressedButtons

    Check_Pad_Start:
    TXA ; lda input_pressed_this_frame
    eor PAD_START
    bne StopCheckingPressedButtons
    jmp HandleCursorPressedStart
    JMP StopCheckingPressedButtons
    
    StopCheckingPressedButtons:
    

    ; Pressed
    ;HandleButtonPressed PAD_START,  HandleCursorPressedStart
    ;HandleButtonPressed PAD_SELECT, HandleCursorPressedSelect

    ;HandleButtonPressed PAD_A,      HandleCursorPressedA
    ;HandleButtonPressed PAD_B,      HandleCursorPressedB

    ;HandleButtonPressed PAD_LEFT,   HandleCursorPressedLeft
    ;HandleButtonPressed PAD_RIGHT,  HandleCursorPressedRight
    ;HandleButtonPressed PAD_UP,     HandleCursorPressedUp
    ;HandleButtonPressed PAD_DOWN,   HandleCursorPressedDown


    ; Released
    ;HandleButtonReleased PAD_START,     HandleCursorReleasedStart
    ;HandleButtonReleased PAD_SELECT,    HandleCursorReleasedSelect

    ;HandleButtonReleased PAD_A,         HandleCursorReleasedA
    ;HandleButtonReleased PAD_B,         HandleCursorReleasedB

    ;HandleButtonReleased PAD_LEFT,      HandleCursorReleasedLeft
    ;HandleButtonReleased PAD_RIGHT,     HandleCursorReleasedRight
    ;HandleButtonReleased PAD_UP,        HandleCursorReleasedUp
    ;HandleButtonReleased PAD_DOWN,      HandleCursorReleasedDown


    ; Pressed
    ; in this case all call the pressed function
    ;HandleButtonHeld PAD_START,     frame_counter_holding_button_start,     BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedStart
    ;HandleButtonHeld PAD_SELECT,    frame_counter_holding_button_select,    BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedSelect

    ;HandleButtonHeld PAD_A,         frame_counter_holding_button_a,         BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedA
    ;HandleButtonHeld PAD_B,         frame_counter_holding_button_b,         BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedB

    ;HandleButtonHeld PAD_LEFT,      frame_counter_holding_button_left,      BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedLeft
    ;HandleButtonHeld PAD_RIGHT,     frame_counter_holding_button_right,     BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedRight
    ;HandleButtonHeld PAD_UP,        frame_counter_holding_button_up,        BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedUp
    ;HandleButtonHeld PAD_DOWN,      frame_counter_holding_button_down,      BUTTON_HOLD_TIME_NORMAL,   HandleCursorPressedDown

    ;Test:
    ;rts 


.endproc



;*****************************************************************
;                       PRESSED
;*****************************************************************


; BudgetArms
.proc HandleCursorPressedStart
    jsr CycleToolModes
    rts 


.endproc


; BudgetArms
.proc HandleCursorPressedSelect
    jsr CycleCanvasModes
    rts 


.endproc


; BudgetArms
.proc HandleCursorPressedA
    lda scroll_y_position
    cmp #CANVAS_MODE
    beq @In_Canvas_Mode
        jsr SelectTool
        rts
    @In_Canvas_Mode:
    ChangeToolAttr #BRUSH_TOOL_ON
    rts 


.endproc


; BudgetArms
.proc HandleCursorPressedB
    jsr CycleBrushSize

    lda cursor_type     ; load cursor type

    cmp #TYPE_CURSOR_SMALL
    beq @smallCursor

    cmp #TYPE_CURSOR_NORMAL
    beq @normalCursor

    cmp #TYPE_CURSOR_BIG
    beq @bigCursor

    ; this should never be reached
    rts 


    @smallCursor:
            
        ; change cursor type to normal
        lda #TYPE_CURSOR_NORMAL
        sta cursor_type 

        rts 

    @normalCursor:

        ; change cursor type to big
        lda #TYPE_CURSOR_BIG
        sta cursor_type 

        rts 


    @bigCursor:
        
        ; change cursor type to small
        lda #TYPE_CURSOR_SMALL
        sta cursor_type 

        ; reset the direction (top left)
        lda #DIR_CURSOR_SMALL_TOP_LEFT 
        sta cursor_small_direction

        rts 

.endproc


; BudgetArms
.proc HandleCursorPressedLeft

    lda cursor_type     ; load cursor type

    cmp #TYPE_CURSOR_SMALL
    beq @smallCursor

    cmp #TYPE_CURSOR_NORMAL
    beq @normalCursor

    cmp #TYPE_CURSOR_BIG
    beq @bigCursor

    ; this should never be reached
    rts 

    @smallCursor:

        lda cursor_small_direction  ; load current direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq @TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq @TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq @BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts 
        
        @TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            jsr MoveCursorLeft

            rts 

        @TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            rts 

        @BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            ; update cursor x-pos 
            jsr MoveCursorLeft

            rts 

        @BottomRight:
            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            rts 


        ; should never reach this
        rts 


    @normalCursor:
        ; Update x-pos (1 step)
        jsr MoveCursorLeft

        rts 


    @bigCursor:
        ; Update x-pos (2 step)
        jsr MoveCursorLeft
        jsr MoveCursorLeft

        rts 

.endproc


; BudgetArms
.proc HandleCursorPressedRight

    lda cursor_type     ; load cursor type

    ; check the cursor size
    cmp #TYPE_CURSOR_SMALL
    beq @smallCursor

    cmp #TYPE_CURSOR_NORMAL
    beq @normalCursor

    cmp #TYPE_CURSOR_BIG
    beq @bigCursor

    ; this should never be reached
    rts 


    @smallCursor:

        ; check the cursor direction
        lda cursor_small_direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq @TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq @TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq @BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts 
        
        @TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            rts 

        @TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            ; update cursor x-pos 
            jsr MoveCursorRight

            rts 

        @BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            rts 

        @BottomRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            ; update cursor x-pos 
            jsr MoveCursorRight

            rts 

        ; should never reach this
        rts 


    @normalCursor:

        ; Update x-pos (1 step)
        jsr MoveCursorRight

        rts 


    @bigCursor:
        
        ; Update x-pos (2 step)
        jsr MoveCursorRight
        jsr MoveCursorRight

        rts 

.endproc


; BudgetArms
.proc HandleCursorPressedUp
    lda scroll_y_position
    cmp #CANVAS_MODE
    beq @In_Canvas_Mode
        jsr MoveSelectionStarUp
        rts
    @In_Canvas_Mode:

    lda cursor_type     ; load cursor type

    cmp #TYPE_CURSOR_SMALL
    beq @smallCursor

    cmp #TYPE_CURSOR_NORMAL
    beq @normalCursor

    cmp #TYPE_CURSOR_BIG
    beq @bigCursor

    ; this should never be reached
    rts 


    @smallCursor:

        lda cursor_small_direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq @TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq @TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq @BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts 
        
        @TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorUp

            rts 

        @TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorUp

            rts 

        @BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            rts 

        @BottomRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            rts 


        ; should never reach this
        rts 


    @normalCursor:

        ; Update y-pos (1 step)
        jsr MoveCursorUp

        rts 


    @bigCursor:
        
        ; Update y-pos (2 step)
        jsr MoveCursorUp
        jsr MoveCursorUp

        rts 

.endproc


; BudgetArms
.proc HandleCursorPressedDown
    lda scroll_y_position
    cmp #CANVAS_MODE
    beq @In_Canvas_Mode
        jsr MoveSelectionStarDown
        rts
    @In_Canvas_Mode:

    lda cursor_type     ; load cursor type

    cmp #TYPE_CURSOR_SMALL
    beq @smallCursor

    cmp #TYPE_CURSOR_NORMAL
    beq @normalCursor

    cmp #TYPE_CURSOR_BIG
    beq @bigCursor

    ; this should never be reached
    rts 


    @smallCursor:

        lda cursor_small_direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq @TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq @TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq @BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts 
        
        @TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            rts 

        @TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            rts 

        @BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorDown

            rts 

        @BottomRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorDown

            rts 


    @normalCursor:

        ; Update y-pos (1 step)
        jsr MoveCursorDown

        rts 


    @bigCursor:
        
        ; Update y-pos (2 step)
        jsr MoveCursorDown
        jsr MoveCursorDown

        rts 

.endproc
; Khine



;*****************************************************************
;                       RELEASED
;*****************************************************************


.proc HandleCursorReleasedStart
    ; Empty for now
    rts 


.endproc
; Khine


.proc HandleCursorReleasedSelect
    ; Empty for now
    rts 


.endproc
; Khine


.proc HandleCursorReleasedA
    ; Empty for now
    rts 


.endproc


.proc HandleCursorReleasedB
    ; Empty for now
    rts 


.endproc


.proc HandleCursorReleasedLeft
    ; Empty for now
    rts 


.endproc


.proc HandleCursorReleasedRight
    ; Empty for now
    rts 


.endproc


.proc HandleCursorReleasedUp
    ; Empty for now
    rts 


.endproc


.proc HandleCursorReleasedDown
    ; Empty for now
    rts 


.endproc


