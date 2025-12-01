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
.proc HandleInputA
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

        ;jsr HandleCanvasInput
        rts 

    Not_In_Canvas:

    jsr HandleSelectionMenuInput
    rts 


.endproc



; BudgetArms
.proc HandleMenuInput

    rts 

.endproc


; BudgetArms
.proc HandleInput

    ; Combo's

    ; if holding start, ignore all the other input
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
        bne Check_PAD_SELECT
        ;code
        jsr HandleCursorPressedA
        jsr MoveCursorDown
        jsr MoveCursorRight
        ;rts ; jmp StopChecking
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

        ;jsr CycleCanvasModes
        ;jsr DisplayCanvasModeOverlay
        ;jsr CycleCanvasModes
        jmp StopChecking

    Check_PAD_START_LEFT:
        cmp #PAD_START_LEFT
        bne Check_PAD_START_RIGHT
        ;code for when START is pressed
        ;jsr MoveSelectionStarDown
        ;jsr DisplayCanvasModeOverlay
        jsr DecreaseToolSelection
        jmp StopChecking

    
    Check_PAD_START_RIGHT:
        cmp #PAD_START_RIGHT
        bne Check_PAD_START_UP
        ;code for when START is pressed
        ;jsr MoveSelectionStarUp
        ;jsr DisplayCanvasModeOverlay
        jsr IncreaseToolSelection
        jmp StopChecking


    Check_PAD_START_UP:
        cmp #PAD_START_UP
        bne Check_PAD_START_DOWN
        ;code for when START is pressed
        ;jsr MoveSelectionStarUp
        ;jsr DisplayCanvasModeOverlay
        jmp StopChecking


    Check_PAD_START_DOWN:
        cmp #PAD_START_DOWN
        bne Check_PAD_LEFT
        ;code for when START is pressed
        ;jsr MoveSelectionStarDown
        ;jsr DisplayCanvasModeOverlay
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
    

.endproc

.proc HandleSelectionMenuInput

    ; Pressed
    ; HandleButtonPressed PAD_SELECT,     HandleSelectionMenuPressedSelect

    ; HandleButtonPressed PAD_A,          HandleSelectionMenuPressedA

    ; HandleButtonReleased PAD_UP,        HandleSelectionMenuPressedUp
    ; HandleButtonReleased PAD_DOWN,      HandleSelectionMenuPressedDown

    rts 

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
.proc HandleCursorHoldingA
    lda tool_mode

    cmp #FILL_MODE
    beq @In_Fill_Mode

    cmp #DRAW_MODE
    beq @In_Brush_Mode

    cmp #ERASER_MODE
    beq @In_Brush_Mode

    rts

    @In_Brush_Mode:
        ChangeToolAttr #BRUSH_TOOL_ON
        rts
    @In_Fill_Mode:
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


; BudgetArms
.proc HandleCursorPressedLeft

    lda cursor_type     ; load cursor type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor

    ; this should never be reached
    rts 

    Small_Cursor:

        lda cursor_small_direction  ; load current direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq BottomRight

        ; this should never be reached
        rts 
        
        TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            jsr MoveCursorLeft

            rts 

        TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            rts 

        BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            ; update cursor x-pos 
            jsr MoveCursorLeft

            rts 

        BottomRight:
            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            rts 


        ; should never reach this
        rts 


    Normal_Cursor:
        ; Update x-pos (1 step)
        jsr MoveCursorLeft

        rts 


    Medium_Cursor:
        ; Update x-pos (2 step)
        jsr MoveCursorLeft
        jsr MoveCursorLeft

        rts 


    Big_Cursor:
        ; Update x-pos (3 step)
        jsr MoveCursorLeft
        jsr MoveCursorLeft
        jsr MoveCursorLeft

        rts 

.endproc


; BudgetArms
.proc HandleCursorPressedRight

    lda cursor_type     ; load cursor type

    ; check the cursor size
    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor

    ; this should never be reached
    rts 


    Small_Cursor:

        ; check the cursor direction
        lda cursor_small_direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq BottomRight

        ; this should never be reached
        rts 
        
        TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            rts 

        TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            ; update cursor x-pos 
            jsr MoveCursorRight

            rts 

        BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            rts 

        BottomRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            ; update cursor x-pos 
            jsr MoveCursorRight

            rts 

        ; should never reach this
        rts 


    Normal_Cursor:

        ; Update x-pos (1 step)
        jsr MoveCursorRight

        rts 


    Medium_Cursor:

        ; Update x-pos (2 step)
        jsr MoveCursorRight
        jsr MoveCursorRight

        rts 


    Big_Cursor:
        
        ; Update x-pos (3 step)
        jsr MoveCursorRight
        jsr MoveCursorRight
        jsr MoveCursorRight

        rts 

.endproc


; BudgetArms
.proc HandleCursorPressedUp

    lda cursor_type     ; load cursor type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor

    ; this should never be reached
    rts 


    Small_Cursor:

        lda cursor_small_direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq BottomRight

        ; this should never be reached
        rts 
        
        TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorUp

            rts 

        TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorUp

            rts 

        BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            rts 

        BottomRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            rts 


        ; should never reach this
        rts 


    Normal_Cursor:

        ; Update y-pos (1 step)
        jsr MoveCursorUp

        rts 

    Medium_Cursor:

        ; Update y-pos (2 step)
        jsr MoveCursorUp
        jsr MoveCursorUp

        rts 


    Big_Cursor:
        
        ; Update y-pos (3 step)
        jsr MoveCursorUp
        jsr MoveCursorUp
        jsr MoveCursorUp

        rts 

.endproc


; BudgetArms
.proc HandleCursorPressedDown

    lda cursor_type     ; load cursor type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor

    ; this should never be reached
    rts 


    Small_Cursor:

        lda cursor_small_direction

        cmp #DIR_CURSOR_SMALL_TOP_LEFT
        beq TopLeft

        cmp #DIR_CURSOR_SMALL_TOP_RIGHT
        beq TopRight

        cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
        beq BottomLeft

        cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        beq BottomRight

        ; this should never be reached
        rts 
        
        TopLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_LEFT
            sta cursor_small_direction

            rts 

        TopRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_BOTTOM_RIGHT
            sta cursor_small_direction

            rts 

        BottomLeft:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_LEFT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorDown

            rts 

        BottomRight:

            ; update the small direction
            lda #DIR_CURSOR_SMALL_TOP_RIGHT
            sta cursor_small_direction

            ; update cursor y-pos 
            jsr MoveCursorDown

            rts 


    Normal_Cursor:

        ; Update y-pos (1 step)
        jsr MoveCursorDown

        rts 


    Medium_Cursor:

        ; Update y-pos (2 step)
        jsr MoveCursorDown
        jsr MoveCursorDown

        rts 


    Big_Cursor:
        
        ; Update y-pos (3 step)
        jsr MoveCursorDown
        jsr MoveCursorDown

        rts 

.endproc


;*****************************************************************
;                       RELEASED
;*****************************************************************


; BudgetArms
.proc HandleCursorReleasedA

    ResetFrameCounterHolder frame_counter_holding_button_a
    rts 

.endproc
; BudgetArms

; BudgetArms
.proc HandleCursorReleasedB

    ResetFrameCounterHolder frame_counter_holding_button_b
    rts 

.endproc
; BudgetArms

; BudgetArms
.proc HandleCursorReleasedDpad

    ResetFrameCounterHolder frame_counter_holding_button_dpad
    rts 

.endproc
; BudgetArms



;*****************************************************************
;                       SELECTION_MENU
;*****************************************************************


; BudgetArms
.proc HandleSelectionMenuPressedSelect

    jsr CycleCanvasModes
    rts 

.endproc

; BudgetArms
.proc HandleSelectionMenuPressedA

    jsr SelectTool
    rts 

.endproc

; BudgetArms
.proc HandleSelectionMenuPressedUp

    jsr MoveSelectionStarUp
    rts 

.endproc


; BudgetArms
.proc HandleSelectionMenuPressedDown

    jsr MoveSelectionStarDown
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


