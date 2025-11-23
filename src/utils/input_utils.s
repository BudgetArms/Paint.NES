;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
;*****************************************************************
.proc poll_gamepad
    ; save last frame input
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



;*****************************************************************
; HandleInput: Called every frame, after poll_gamepad. It's used to call 
; the Pressed, Released and Held functions with Help of macro's
; HandleButtonPressed, HandleButtonReleased and HandleButtonHeld.
;*****************************************************************

; BudgetArms
.proc HandleInput

    ; combo example 

    ; if holding start, ignore all the other input
    lda input_holding_this_frame
    and #PAD_START
    bne Not_Holding_Start:

        ; if Holding_start

        ; HandleButtonPressed PAD_LEFT,   ADD_THE_FUNCTION
        ; HandleButtonPressed PAD_RIGHT,  ADD_THE_FUNCTION
        ; HandleButtonPressed PAD_UP,     ADD_THE_FUNCTION
        ; HandleButtonPressed PAD_DOWN,   ADD_THE_FUNCTION

        rts 


    Not_Holding_Start:


    ; Pressed
    HandleButtonPressed PAD_START,  HandleCursorPressedStart
    HandleButtonPressed PAD_SELECT, HandleCursorPressedSelect

    HandleButtonPressed PAD_A,      HandleCursorPressedA
    HandleButtonPressed PAD_B,      HandleCursorPressedB

    HandleButtonPressed PAD_LEFT,   HandleCursorPressedLeft
    HandleButtonPressed PAD_RIGHT,  HandleCursorPressedRight
    HandleButtonPressed PAD_UP,     HandleCursorPressedUp
    HandleButtonPressed PAD_DOWN,   HandleCursorPressedDown


    ; Released
    HandleButtonReleased PAD_START,     HandleCursorReleasedStart
    HandleButtonReleased PAD_SELECT,    HandleCursorReleasedSelect

    HandleButtonReleased PAD_A,         HandleCursorReleasedA
    HandleButtonReleased PAD_B,         HandleCursorReleasedB

    HandleButtonReleased PAD_LEFT,      HandleCursorReleasedLeft
    HandleButtonReleased PAD_RIGHT,     HandleCursorReleasedRight
    HandleButtonReleased PAD_UP,        HandleCursorReleasedUp
    HandleButtonReleased PAD_DOWN,      HandleCursorReleasedDown


    ; Pressed
    ; in this case all call the pressed function
    HandleButtonHeld PAD_START,     frame_counter_holding_button_start,     BUTTON_HOLD_TIME,   HandleCursorPressedStart
    HandleButtonHeld PAD_SELECT,    frame_counter_holding_button_select,    BUTTON_HOLD_TIME,   HandleCursorPressedSelect

    HandleButtonHeld PAD_A,         frame_counter_holding_button_a,         BUTTON_HOLD_TIME,   HandleCursorPressedA
    HandleButtonHeld PAD_B,         frame_counter_holding_button_b,         BUTTON_HOLD_TIME,   HandleCursorPressedB

    HandleButtonHeld PAD_LEFT,      frame_counter_holding_button_left,      BUTTON_HOLD_TIME,   HandleCursorPressedLeft
    HandleButtonHeld PAD_RIGHT,     frame_counter_holding_button_right,     BUTTON_HOLD_TIME,   HandleCursorPressedRight
    HandleButtonHeld PAD_UP,        frame_counter_holding_button_up,        BUTTON_HOLD_TIME,   HandleCursorPressedUp
    HandleButtonHeld PAD_DOWN,      frame_counter_holding_button_down,      BUTTON_HOLD_TIME,   HandleCursorPressedDown

    

    rts 

.endproc



;*****************************************************************
;                       PRESSED
;*****************************************************************


; BudgetArms
.proc HandleCursorPressedStart
    ; Empty for now
    rts 


.endproc


; BudgetArms
.proc HandleCursorPressedSelect
    ; Empty for now
    rts 


.endproc


; BudgetArms
.proc HandleCursorPressedA
    ; Empty for now
    rts 


.endproc


; BudgetArms
.proc HandleCursorPressedB

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



;*****************************************************************
;                       RELEASED
;*****************************************************************


.proc HandleCursorReleasedStart
    ; Empty for now
    rts 


.endproc


.proc HandleCursorReleasedSelect
    ; Empty for now
    rts 


.endproc


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



