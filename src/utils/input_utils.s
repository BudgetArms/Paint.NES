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
        cmp #buttonMask
        bne exit_macro
        jsr handleFunction
    ;lda input_pressed_this_frame
    ;eor #buttonMask
    ;bne 

    ;exit exit_macro:



    ; to make labels work in macro's
    ;.local exit_macro 

    ; Check button is pressed
    ;lda input_pressed_this_frame
    ;and #buttonMask
    ;beq exit_macro
        ; code for when button is pressed
        ;jsr handleFunction

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
    ;input holding = 
; check if input last frame = same as input current frame

    ;lda input_pressed_this_frame
    ;lda current_input
    lda input_holding_this_frame
    bne Check_PAD_A
    lda #$00 ; reset frame count to 0
    sta frame_count
    rts ;if no buttons are pressed, skip all checks.

    Check_PAD_A:
    ;lda input_pressed_this_frame
        cmp #PAD_A
        bne Check_PAD_A_LEFT
        ;code for when A is pressed alone
        jsr HandleCursorPressedA
        ;rts ; jmp StopChecking
        jmp StopChecking
    
    Check_PAD_A_LEFT:
    ;lda input_pressed_this_frame
        cmp #PAD_A_LEFT
        bne Check_PAD_A_RIGHT
        ;code for when A + LEFT is pressed
        jsr HandleCursorPressedA
        jsr MoveCursorLeft
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_A_RIGHT:
    ;lda input_pressed_this_frame
        cmp #PAD_A_RIGHT
        bne Check_PAD_A_UP
        ;code for when a + right is pressed
        jsr HandleCursorPressedA
        jsr MoveCursorRight
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_A_UP:
    ;lda input_pressed_this_frame
        cmp #PAD_A_UP
        BNE Check_PAD_A_DOWN
        ;code for when  A + UP is pressed
        jsr HandleCursorPressedA
        jsr MoveCursorUp
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_A_DOWN:
    ;lda input_pressed_this_frame
        cmp #PAD_A_DOWN
        bne Check_PAD_A_UP_LEFT
        ;code for when a + down is pressed
        jsr HandleCursorPressedA
        jsr HandleCursorPressedA
        jsr MoveCursorDown
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_A_UP_LEFT:
        cmp #PAD_A_UP_LEFT
        bne Check_PAD_A_DOWN_LEFT
        ;code for when a + up + Left is pressed
        jsr HandleCursorPressedA
        jsr MoveCursorUp
        jsr MoveCursorLeft
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_A_DOWN_LEFT:
        cmp #PAD_A_DOWN_LEFT
        bne Check_PAD_A_UP_RIGHT
        ;code
        jsr HandleCursorPressedA
        jsr MoveCursorDown
        jsr MoveCursorLeft
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_A_UP_RIGHT:
        cmp #PAD_A_UP_RIGHT
        bne Check_PAD_A_DOWN_RIGHT
        ;code
        jsr HandleCursorPressedA
        jsr MoveCursorUp
        jsr MoveCursorRight
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_A_DOWN_RIGHT:
        cmp #PAD_A_DOWN_RIGHT
        bne Check_PAD_START
        ;code
        jsr HandleCursorPressedA
        jsr MoveCursorDown
        jsr MoveCursorRight
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_START:
        cmp #PAD_START
        bne Check_PAD_START_LEFT
        ;code for when START is pressed alone
        jsr HandleCursorPressedStart
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_START_LEFT:
        cmp #PAD_START_LEFT
        bne Check_PAD_START_RIGHT
        ;code for when START is pressed
        ;lda #$02
        ;sta chrTileIndex
        jsr DecreaseChrTileIndex
        ;rts ; jmp StopChecking
        jmp StopChecking

    
    Check_PAD_START_RIGHT:
        cmp #PAD_START_RIGHT
        bne Check_PAD_START_UP
        ;code for when START is pressed
        jsr IncreaseChrTileIndex
        ;lda #$00
        ;sta chrTileIndex
        ;rts ; jmp StopChecking
        jmp StopChecking


    Check_PAD_START_UP:
        cmp #PAD_START_UP
        bne Check_PAD_START_DOWN
        ;code for when START is pressed
        jsr IncreaseColorPalleteIndex
        ;lda #$01
        ;sta chrTileIndex
        ;rts ; jmp StopChecking
        jmp StopChecking


    Check_PAD_START_DOWN:
        cmp #PAD_START_DOWN
        bne Check_PAD_LEFT
        ;code for when START is pressed
        jsr DecreaseColorPalleteIndex
        ;lda #$03
        ;sta chrTileIndex
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_LEFT:
        cmp #PAD_LEFT
        bne Check_PAD_RIGHT
        jsr MoveCursorLeft
        ;jsr HandleCursorPressedLeft
        ;code for when Left is pressed alone
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_RIGHT:
        cmp #PAD_RIGHT
        bne Check_PAD_UP
        jsr MoveCursorRight
        ;jsr HandleCursorPressedRight
        ;code for when Left is pressed alone
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_UP:
        cmp #PAD_UP
        bne Check_PAD_DOWN
        jsr MoveCursorUp
        ;jsr HandleCursorPressedUp
        ;code for when Left is pressed alone
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_DOWN:
        cmp #PAD_DOWN
        bne Check_PAD_UP_LEFT
        ;code for when Left is pressed alone
        jsr MoveCursorDown
        ;jsr HandleCursorPressedDown
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_UP_LEFT:
        cmp #PAD_UP_LEFT
        bne Check_PAD_DOWN_LEFT
        ;code for when Left is pressed alone
        jsr MoveCursorUp
        jsr MoveCursorLeft
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_DOWN_LEFT:
        cmp #PAD_DOWN_LEFT
        bne Check_PAD_UP_RIGHT
        ;code for when Left is pressed alone
        jsr MoveCursorDown
        jsr MoveCursorLeft
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_UP_RIGHT:
        cmp #PAD_UP_RIGHT
        bne Check_PAD_DOWN_RIGHT
        ;code for when Left is pressed alone
        jsr MoveCursorUp
        jsr MoveCursorRight
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_DOWN_RIGHT:
        cmp #PAD_DOWN_RIGHT
        bne Check_PAD_B
        ;code for when Left is pressed alone
        jsr MoveCursorDown
        jsr MoveCursorRight
        ;jsr IncreaseColorPalleteIndex
        ;rts ; jmp StopChecking
        jmp StopChecking

    Check_PAD_B:
        cmp #PAD_B
        bne StopChecking
        ;code for when Left is pressed alone
        jsr HandleCursorPressedB
        jmp StopChecking

    ;Check_REST:
        ;rts ; jmp StopChecking


    StopChecking:
        jsr IncButtonHeldFrameCount
        rts
    
    ;Pressed
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
; Code to slow input registration down
    lda frame_count
    bne DontRegisterYet

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

    DontRegisterYet:
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


