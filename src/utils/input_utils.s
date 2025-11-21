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


 	lda #PAD_START
 	ora #PAD_LEFT ;create and store a mask for the start + left button being pressed together
 	eor input_pressed_this_frame ;XOR the current input with start+left mask
 	bne not_pressed_StartAndLeft
	;lda $30
	;sta palleteSwitchValue
	;lda collor_pallete_selection
	;TAX ; store quick acces later
	;and #%00000100
	;bne ButtonWasPressedLastFrame
	;txa
	;CLC
	;sbc #$01
	
	;NV--DIZC


	;inc palleteSwitchValue
; ; code for when Start + Left is pressed:
;LDA #$3F      ; Load palette address start ($3F00-$3FFF)
;STA $2006     ; Set high byte of PPU address
;LDA #$00      
;STA $2006     ; Set low byte of PPU address

;LDA #$01      ; Load color index (blue in NES palette)
;STA $2007

 	;lda collor_pallete_selection
 	;tax ; store quick acces later
 	;and #%00000100
 	;bne ButtonWasAlreadyPressedLastFrame
; ;DecrementColourpalletteIndex:
;LDA #$3F      ; Load palette address start ($3F00-$3FFF)
;STA $2006     ; Set high byte of PPU address
;LDA #$00      
;STA $2006     ; Set low byte of PPU address

;LDA #$01      ; Load color index (blue in NES palette)
;STA $2007     ; Write color to PPU

 	;txa
	;SBC #1 ;decrement the collorpallette indexcounter
	;bcc Input_Has_Been_Handled


	

 	not_pressed_StartAndLeft:
	; check StartAndRight
 	lda #PAD_START
 	ora #PAD_RIGHT ;create and store a mask for the start + left button being pressed together
 	eor input_pressed_this_frame ;XOR the current input with start+left mask
 	bne CheckOtherButtons ; start checking other buttons
	;lda $0f
	;sta palleteSwitchValue
	;dec palleteSwitchValue
 ; code for when Start + Right is pressed:
;LDA #$3F      ; Load palette address start ($3F00-$3FFF)
;STA $2006     ; Set high byte of PPU address
;LDA #$00      
;;STA $2006     ; Set low byte of PPU address

;LDA #$06      ; Load color index (blue in NES palette)
;STA $2007

 	;lda collor_pallete_selection
 	;tax ; store quick acces later
 	;and #%00000100
 	;bne ButtonWasAlreadyPressedLastFrame
;LDA #$3F      ; Load palette address start ($3F00-$3FFF)
;STA $2006     ; Set high byte of PPU address
;LDA #$00      
;STA $2006     ; Set low byte of PPU address

;LDA #$01      ; Load color index (blue in NES palette)
;STA $2007     ; Write color to PPU

; 	inx ;increment collorpallette indexcounter
; 	TXA
; 	ora #%00000100 ;set 3rd bit high.
; 	sta collor_pallete_selection


	;ButtonWasAlreadyPressedLastFrame:
;;;LDA #$3F      ; Load palette address start ($3F00-$3FFF)
;STA $2006     ; Set high byte of PPU address
;LDA #$00      
;;STA $2006     ; Set low byte of PPU address

;LDA #$05      ; Load color index (blue in NES palette)
;STA $2007     ; Write color to PPU
	; nothing should happen
ButtonWasPressedLastFrame:
	CheckOtherButtons:
	; Check A button
	lda input_pressed_this_frame
	and #PAD_A
	beq not_pressed_a
	paletteloop1:
	lda switched_palette_1, x
	sta palette, x
	inx
	cpx #32
	bcc paletteloop1
	;lda #$30
	;sta palleteSwitchValue
		; code for when A is pressed
		;lda $00
		;sta palleteSwitchValue
	not_pressed_a:

	; Check B button
	lda input_pressed_this_frame
	and #PAD_B
	beq not_pressed_b
	paletteloop2:
	lda switched_palette_2, x
	;lda #$14
	sta palette, x
	inx
	cpx #32
	bcc paletteloop2
		; code for when B is pressed
	not_pressed_b:

	; Check Select button
	lda input_pressed_this_frame
	and #PAD_SELECT
	beq not_pressed_select
	; point PPU to $2001
; --- write tile #4 to screen tile #2 ($2001) ---
;lda #$20
;sta $2006
;lda #$02
;sta $2006
;lda positionXOnScreen
;sta $2007

; --- write tile #4 to screen tile #3 ($2002) ---
;lda #$20
;sta $2006
;lda #$02
;sta $2006
;lda #$04
;sta $2007


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
	inc positionXOnCHR
lda #$20
sta $2006
lda #$01
sta $2006
lda positionXOnCHR
sta $2007
		; code for when Up is pressed
	not_pressed_up:

	; Check Down
	lda input_pressed_this_frame
	and #PAD_DOWN
	beq not_pressed_down
		; code for when Down is pressed
	not_pressed_down:

	; Check Left
	lda input_pressed_this_frame
	and #PAD_LEFT
	beq not_pressed_left
		; code for when Left is pressed
	not_pressed_left:

	; Check Right
	lda input_pressed_this_frame
	and #PAD_RIGHT
	beq not_pressed_right
	inc positionXOnScreen
lda #$20
sta $2006
lda #$02
sta $2006
lda positionXOnScreen
sta $2007
		; code for when Right is pressed
	not_pressed_right:

	rts

	Input_Has_Been_Handled:

.endproc
