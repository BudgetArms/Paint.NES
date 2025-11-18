;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
;*****************************************************************
.proc poll_gamepad
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

    rts
.endproc

;*****************************************************************
; handle_input: handles controller input for the current frame
;   Reads from `input_pressed_this_frame` and gives a branch where you can write code for when its pressed
;   This one only updates when you start pressing the button, use `current_input` for having it be called every tick or
;	`input_released_this_frame` to have it be called only once when releasing the button
;*****************************************************************
.proc handle_input
    ; Check A button
    lda input_pressed_this_frame
    and #PAD_A
    beq not_pressed_a
        ; code for when A is pressed


    not_pressed_a:

    ; Check B button
    lda input_pressed_this_frame
    and #PAD_B
    beq not_pressed_b
        ; code for when B is pressed

        jsr Handle_Cursor_B


    not_pressed_b:

    ; Check Select button
    lda input_pressed_this_frame
    and #PAD_SELECT
    beq not_pressed_select
        ; code for when Select is pressed


    not_pressed_select:

    ; Check Start button
    lda input_pressed_this_frame
    and #PAD_START
    beq not_pressed_start
        ; code for when Start is pressed


    not_pressed_start:

    ; Check Up
    lda input_pressed_this_frame
    and #PAD_UP
    beq not_pressed_up
        ; code for when Up is pressed

        jsr Handle_Cursor_Up

    not_pressed_up:

    ; Check Down
    lda input_pressed_this_frame
    and #PAD_DOWN
    beq not_pressed_down
        ; code for when Down is pressed

        jsr Handle_Cursor_Down

    not_pressed_down:

    ; Check Left
    lda input_pressed_this_frame
    and #PAD_LEFT
    beq not_pressed_left
        ; code for when Left is pressed

        jsr Handle_Cursor_Left

    not_pressed_left:

    ; Check Right
    lda input_pressed_this_frame
    and #PAD_RIGHT
    beq not_pressed_right
        ; code for when Right is pressed

        jsr Handle_Cursor_Right

    not_pressed_right:

    rts 
.endproc



.proc Handle_Cursor_B

    lda cursor_type     ; load cursor type

    cmp #CURSOR_TYPE_SMALL
    beq @smallCursor

    cmp #CURSOR_TYPE_NORMAL
    beq @normalCursor

    cmp #CURSOR_TYPE_BIG
    beq @bigCursor

    ; this should never be reached
    rts


    @smallCursor:
            
        ; change cursor type to normal
        lda #CURSOR_TYPE_NORMAL
        sta cursor_type 


        rts 

    @normalCursor:

        ; change cursor type to big
        lda #CURSOR_TYPE_BIG
        sta cursor_type 


        rts


    @bigCursor:
        
        ; change cursor type to small
        lda #CURSOR_TYPE_SMALL
        sta cursor_type 

        ; reset the direction (top left)
        lda #CURSOR_SMALL_DIR_TOP_LEFT 
        sta cursor_small_direction

        rts

.endproc



.proc Handle_Cursor_Up

    lda cursor_type     ; load cursor type

    cmp #CURSOR_TYPE_SMALL
    beq @smallCursor

    cmp #CURSOR_TYPE_NORMAL
    beq @normalCursor

    cmp #CURSOR_TYPE_BIG
    beq @bigCursor

    ; this should never be reached
    rts 


    @smallCursor:

        lda cursor_small_direction

        cmp #CURSOR_SMALL_DIR_TOP_LEFT
        beq @TopLeft

        cmp #CURSOR_SMALL_DIR_TOP_RIGHT
        beq @TopRight

        cmp #CURSOR_SMALL_DIR_BOTTOM_LEFT
        beq @BottomLeft

        cmp #CURSOR_SMALL_DIR_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts
        
        @TopLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_LEFT
            sta cursor_small_direction

            ; update cursor y-pos 
            dec cursor_y

            rts 

        @TopRight:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_RIGHT
            sta cursor_small_direction

            ; update cursor y-pos 
            dec cursor_y

            rts 

        @BottomLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_LEFT
            sta cursor_small_direction

            rts 

        @BottomRight:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_RIGHT
            sta cursor_small_direction

            rts 


        ; should never reach this
        rts 


    @normalCursor:

        ; Update y-pos (1 step)
        dec cursor_y

        rts 


    @bigCursor:
        
        ; Update y-pos (2 step)
        dec cursor_y
        dec cursor_y

        rts 

.endproc


.proc Handle_Cursor_Down

    lda cursor_type     ; load cursor type

    cmp #CURSOR_TYPE_SMALL
    beq @smallCursor

    cmp #CURSOR_TYPE_NORMAL
    beq @normalCursor

    cmp #CURSOR_TYPE_BIG
    beq @bigCursor

    ; this should never be reached
    rts 


    @smallCursor:

        lda cursor_small_direction

        cmp #CURSOR_SMALL_DIR_TOP_LEFT
        beq @TopLeft

        cmp #CURSOR_SMALL_DIR_TOP_RIGHT
        beq @TopRight

        cmp #CURSOR_SMALL_DIR_BOTTOM_LEFT
        beq @BottomLeft

        cmp #CURSOR_SMALL_DIR_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts
        
        @TopLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_LEFT
            sta cursor_small_direction

            rts 

        @TopRight:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_RIGHT
            sta cursor_small_direction

            rts 

        @BottomLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_LEFT
            sta cursor_small_direction

            ; update cursor y-pos 
            inc cursor_y

            rts 

        @BottomRight:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_RIGHT
            sta cursor_small_direction

            ; update cursor y-pos 
            inc cursor_y

            rts 


    @normalCursor:

        ; Update y-pos (1 step)
        inc cursor_y

        rts 


    @bigCursor:
        
        ; Update y-pos (2 step)
        inc cursor_y
        inc cursor_y

        rts 

.endproc


.proc Handle_Cursor_Left

    lda cursor_type     ; load cursor type

    cmp #CURSOR_TYPE_SMALL
    beq @smallCursor

    cmp #CURSOR_TYPE_NORMAL
    beq @normalCursor

    cmp #CURSOR_TYPE_BIG
    beq @bigCursor

    ; this should never be reached
    rts

    @smallCursor:

        lda cursor_small_direction  ; load current direction

        cmp #CURSOR_SMALL_DIR_TOP_LEFT
        beq @TopLeft

        cmp #CURSOR_SMALL_DIR_TOP_RIGHT
        beq @TopRight

        cmp #CURSOR_SMALL_DIR_BOTTOM_LEFT
        beq @BottomLeft

        cmp #CURSOR_SMALL_DIR_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts
        
        @TopLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_RIGHT
            sta cursor_small_direction

            ; update cursor x-pos 
            dec cursor_x

            rts 

        @TopRight:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_LEFT
            sta cursor_small_direction

            rts 

        @BottomLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_RIGHT
            sta cursor_small_direction

            ; update cursor x-pos 
            dec cursor_x

            rts 

        @BottomRight:
            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_LEFT
            sta cursor_small_direction

            rts 


        ; should never reach this
        rts 


    @normalCursor:

        ; Update x-pos (1 step)
        dec cursor_x

        rts 


    @bigCursor:
        
        ; Update x-pos (2 step)
        dec cursor_x
        dec cursor_x

        rts 

.endproc


.proc Handle_Cursor_Right

    lda cursor_type     ; load cursor type

    cmp #CURSOR_TYPE_SMALL
    beq @smallCursor

    cmp #CURSOR_TYPE_NORMAL
    beq @normalCursor

    cmp #CURSOR_TYPE_BIG
    beq @bigCursor

    ; this should never be reached
    rts 


    @smallCursor:

        lda cursor_small_direction

        cmp #CURSOR_SMALL_DIR_TOP_LEFT
        beq @TopLeft

        cmp #CURSOR_SMALL_DIR_TOP_RIGHT
        beq @TopRight

        cmp #CURSOR_SMALL_DIR_BOTTOM_LEFT
        beq @BottomLeft

        cmp #CURSOR_SMALL_DIR_BOTTOM_RIGHT
        beq @BottomRight

        ; this should never be reached
        rts
        
        @TopLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_RIGHT
            sta cursor_small_direction

            rts 

        @TopRight:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_TOP_LEFT
            sta cursor_small_direction

            ; update cursor x-pos 
            inc cursor_x

            rts 

        @BottomLeft:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_RIGHT
            sta cursor_small_direction

            rts 

        @BottomRight:

            ; update the small direction
            lda #CURSOR_SMALL_DIR_BOTTOM_LEFT
            sta cursor_small_direction

            ; update cursor x-pos 
            inc cursor_x

            rts 

        ; should never reach this
        rts 


    @normalCursor:

        ; Update x-pos (1 step)
        inc cursor_x

        rts 


    @bigCursor:
        
        ; Update x-pos (2 step)
        inc cursor_x
        inc cursor_x

        rts 

.endproc

