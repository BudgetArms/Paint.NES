.proc update_cursor
    ; Read controller input and move cursor based on button presses
    ; Movement is 1 pixel per frame when a direction is held
    
    ; Check LEFT button
    lda current_input         ; Load current controller state
    and #PAD_LEFT             ; Mask out all bits except LEFT button
    beq no_left               ; If zero (button not pressed), skip movement
    dec cursor_x              ; Move cursor left (decrease X position)
no_left:

    ; Check RIGHT button
    lda current_input
    and #PAD_RIGHT            ; Mask for RIGHT button
    beq no_right              ; Branch if not pressed
    inc cursor_x              ; Move cursor right (increase X position)
no_right:

    ; Check UP button
    lda current_input
    and #PAD_UP               ; Mask for UP button
    beq no_up                 ; Branch if not pressed
    dec cursor_y              ; Move cursor up (decrease Y position)
no_up:

    ; Check DOWN button
    lda current_input
    and #PAD_DOWN             ; Mask for DOWN button
    beq no_down               ; Branch if not pressed
    inc cursor_y              ; Move cursor down (increase Y position)
no_down:

    ; Update sprite 0 in OAM with new cursor position
    lda cursor_y
    sta oam                   ; Byte 0: Y position
    lda #$20
    sta oam+1                 ; Byte 1: tile index
    lda #$00
    sta oam+2                 ; Byte 2: attributes (palette 0, no flip)
    lda cursor_x
    sta oam+3                 ; Byte 3: X position

    rts                       ; Return from subroutine
.endproc