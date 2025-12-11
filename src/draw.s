;file for all drawing functions

; BudgetArms
.proc LoadCursor

    lda cursor_type

    cmp #TYPE_CURSOR_SMALL
    beq Small_Cursor

    cmp #TYPE_CURSOR_NORMAL
    beq Normal_Cursor

    cmp #TYPE_CURSOR_MEDIUM
    beq Medium_Cursor

    cmp #TYPE_CURSOR_BIG
    beq Big_Cursor

    ;this should never be reached
    rts 

    Small_Cursor:
        jsr LoadSmallCursor
        rts 

    Normal_Cursor:
        jsr LoadNormalCursor
        rts 

    Medium_Cursor:
        jsr LoadMediumCursor
        rts 

    Big_Cursor:
        jsr LoadBigCursor
        rts 

    ; this should never be reached
    rts 

.endproc
; BudgetArms


; BudgetArms
.proc LoadSmallCursor

    lda cursor_small_direction

    cmp #DIR_CURSOR_SMALL_TOP_LEFT
    beq DrawTopLeft

    cmp #DIR_CURSOR_SMALL_TOP_RIGHT
    beq DrawTopRight

    cmp #DIR_CURSOR_SMALL_BOTTOM_LEFT
    beq DrawBottomLeft

    cmp #DIR_CURSOR_SMALL_BOTTOM_RIGHT
    beq DrawBottomRight

    ; this should never be reached
    rts 

    ; set x, it's the offset from CURSOR_SMALL_CURSOR to it's current sprite

    DrawTopLeft:
        ldx #DIR_CURSOR_SMALL_TOP_LEFT
        jmp DoneSettingStartAddress

    DrawTopRight:
        ldx #DIR_CURSOR_SMALL_TOP_RIGHT
        jmp DoneSettingStartAddress

    DrawBottomLeft:
        ldx #DIR_CURSOR_SMALL_BOTTOM_LEFT
        jmp DoneSettingStartAddress

    DrawBottomRight:
        ldx #DIR_CURSOR_SMALL_BOTTOM_RIGHT
        jmp DoneSettingStartAddress


    DoneSettingStartAddress:

        ldy #$00

        @Loop: 
            lda CURSOR_SMALL_DATA, X
            sta oam + OAM_OFFSET_CURSOR_SMALL, Y

            inx     ; so the next sprite get read/written
            iny     ; to keep track of the Nth byte we are reading

            cpy #OAM_SIZE_CURSOR_SMALL
            bne @Loop   ; loop until the whole sprite is loaded in

        rts 

.endproc
; BudgetArms


; BudgetArms
.proc LoadNormalCursor

    ldx #$00

    @Loop:
        lda CURSOR_NORMAL_DATA, X
        sta oam + OAM_OFFSET_CURSOR_NORMAL, X
        inx 

        cpx #OAM_SIZE_CURSOR_NORMAL
        bne @Loop  ; loop until all bytes are loaded

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc LoadMediumCursor

    ldx #$00

    @Loop:
        lda CURSOR_MEDIUM_DATA, X
        sta oam + OAM_OFFSET_CURSOR_MEDIUM, X
        inx 

        cpx #OAM_SIZE_CURSOR_MEDIUM
        bne @Loop  ; loop until all bytes are loaded

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc LoadBigCursor

    ldx #$00

    @Loop:
        lda CURSOR_BIG_DATA, X
        sta oam + OAM_OFFSET_CURSOR_BIG, X
        inx 

        cpx #OAM_SIZE_CURSOR_BIG
        bne @Loop  ; loop until all bytes are loaded

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc LoadCursorShapeTool

    ; check what cursor should be loaded
    lda shape_tool_has_set_first_pos
    bne Second_Cursor

    ; Load first shape cursor
    ldx #$00

    @Loop:
        lda shape_tool_type
        
        @Check_Rectangle:
            cmp #SHAPE_TOOL_TYPE_RECTANGLE
            bne @Check_Circle

                lda CURSOR_SHAPE_TOOL_RECTANGLE_DATA, X
                jmp @Store_Shape
        
        @Check_Circle:
            cmp #SHAPE_TOOL_TYPE_CIRCLE
            bne @Check_Others

                lda CURSOR_SHAPE_TOOL_CIRCLE_DATA, X
                jmp @Store_Shape
        
        @Check_Others:
            ; this should never be reached
            rts 

        @Store_Shape:
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL, X
        inx 

        cpx #OAM_SIZE_CURSOR_SHAPE
        bne @Loop

    jmp Update_Cursor_Shape_Position


    Second_Cursor:
    ; Load second shape cursor
    ldx #$00

    @Loop:

        lda shape_tool_type
        
        @Check_Rectangle:
            cmp #SHAPE_TOOL_TYPE_RECTANGLE
            bne @Check_Circle

                lda CURSOR_SHAPE_TOOL_RECTANGLE_DATA + 4, X
                jmp @Store_Shape
        
        @Check_Circle:
            cmp #SHAPE_TOOL_TYPE_CIRCLE
            bne @Check_Others

                lda CURSOR_SHAPE_TOOL_CIRCLE_DATA + 4, X
                jmp @Store_Shape
        
        @Check_Others:
            ; this should never be reached
            rts 
        
        @Store_Shape:
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL, X

        inx 

        cpx #OAM_SIZE_CURSOR_SHAPE
        bne @Loop

    jmp Update_Cursor_Shape_Position


    Update_Cursor_Shape_Position:

        ; Increase cursor_y with oam data's y-pos
        clc 
        lda cursor_y
        ; not addition to OAM Y bc it's set to offscreen        

        ; subtract A (y pos) by one bc it's draw on the next scanline  
        clc 
        sbc #$00

        ; Store data to OAM
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL

        ; Increase cursor_x with oam data's x-pos
        clc 
        lda cursor_x
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL + OAM_X

    rts 

.endproc
; BudgetArms


; Khine / BudgetArms / Jeronimas
.proc UseBrushTool

    ; Check if the PAD_A has been pressed
    ; This is not checked in the `input_utils.s` because this can run into issues with
    ; the program updating the PPU even though PPU has not finished drawing on the screen
    ; not waiting for the VBLANK
    lda tool_use_attr
    and #BRUSH_TOOL_ON
    bne @Use_Brush
        rts
    @Use_Brush:
    lda tool_use_attr
    eor #BRUSH_TOOL_ON
    sta tool_use_attr

    jsr PlayBrushSoundEffect

    ; Store the tile position in a different var
    ; This is done so that the cursor position can stay on the original spot
    ; after drawing has completed.
    lda cursor_tile_position
    sta drawing_tile_position
    lda cursor_tile_position + 1
    sta drawing_tile_position + 1

    ; square brush
    ldy #$00
    @column_loop:
        lda PPU_STATUS ; reset address latch
        lda drawing_tile_position + 1 ; High bit of the location
        sta PPU_ADDR
        lda drawing_tile_position ; Low bit of the location
        sta PPU_ADDR

        ldx #$00
        lda selected_color_chr_index
        @row_loop:
            sta PPU_DATA
            inx
            cpx brush_size
            bne @row_loop

        clc 
        lda drawing_tile_position
        adc #32
        sta drawing_tile_position
        lda drawing_tile_position + 1
        adc #$00
        sta drawing_tile_position + 1
        iny 
        cpy brush_size
        bne @column_loop

    rts 

.endproc
; Khine / BudgetArms


; BudgetArms
.proc UseEraserTool

    lda tool_use_attr
    and #ERASER_TOOL_ON
    bne Use_Eraser
        rts 

    Use_Eraser:

    lda tool_use_attr
    eor #ERASER_TOOL_ON
    sta tool_use_attr

    ; TODO: call eraser tool sound effect here
    ; example:
    ; jsr PlayEraserSoundEffect 

    ; Store the tile position in a different var
    ; This is done so that the cursor position can stay on the original spot
    ; after drawing has completed.
    lda cursor_tile_position
    sta drawing_tile_position
    lda cursor_tile_position + 1
    sta drawing_tile_position + 1

    ; square brush
    ldy #$00
    @Column_Loop:
        lda PPU_STATUS ; reset address latch
        lda drawing_tile_position + 1 ; High bit of the location
        sta PPU_ADDR
        lda drawing_tile_position ; Low bit of the location
        sta PPU_ADDR

        ldx #$00
        ; loads background tile index, instead of select color index
        lda #BACKGROUND_TILE 
        @Row_Loop:
            sta PPU_DATA
            inx 
            cpx brush_size
            bne @Row_Loop

        clc 
        lda drawing_tile_position
        adc #32
        sta drawing_tile_position

        lda drawing_tile_position + 1
        adc #$00
        sta drawing_tile_position + 1

        iny 
        cpy brush_size
        bne @Column_Loop

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc UseShapeTool

    lda tool_use_attr
    and #SHAPE_TOOL_ON
    bne Use_Shape
        rts 
    
    Use_Shape:

    ; Remove SHAPE_TOOL_ON from the tool_use_attributes
    lda tool_use_attr
    eor #SHAPE_TOOL_ON
    sta tool_use_attr

    ; Change things
    lda shape_tool_has_set_first_pos
    bne Second_Position
    
    First_Position:
        ; First position set

        ; if current pos same as previous shape's tool second pos
        ; eg. bc called on held, fix it by checking if it's still in the same location
        lda cursor_x
        cmp shape_tool_second_pos
        bne @Use_First_Position

        lda cursor_y
        cmp shape_tool_second_pos + 1
        bne @Use_First_Position

        ; if current pos == previous pos
        jmp Finish


        @Use_First_Position:

        lda #$01
        sta shape_tool_has_set_first_pos
    
        ; store x/y
        lda cursor_x
        sta shape_tool_first_pos

        lda cursor_y
        sta shape_tool_first_pos + 1
        
        rts 


    Second_Position:
        ; Second position set

        ; if first pos and second pos the same, rts, else @Use_Second_Position
        lda cursor_x
        cmp shape_tool_first_pos 
        bne @Use_Second_Position

        lda cursor_y
        cmp shape_tool_first_pos + 1
        bne @Use_Second_Position


        ; if First pos == Second pos, rts
        rts 


        @Use_Second_Position:

        lda #$00
        sta shape_tool_has_set_first_pos

        ; store x/y
        lda cursor_x
        sta shape_tool_second_pos

        lda cursor_y
        sta shape_tool_second_pos + 1
        

            ; for testing
            jsr DrawShapeCircle
            rts 

        ; Rectangle
        lda shape_tool_type
        and #SHAPE_TOOL_TYPE_RECTANGLE
        beq @Not_Rectangle_Type

            ; if rectangle mode
            jsr DrawShapeRectangle
            rts 

        @Not_Rectangle_Type:

        ; Circle
        lda shape_tool_type
        and #SHAPE_TOOL_TYPE_CIRCLE
        beq @Not_Circle_Type

            ; if circle mode
            jsr DrawShapeCircle
            rts 

        @Not_Circle_Type:

        ; this should never be reached
        rts 


    Finish:
    rts 

.endproc
; BudgetArms


; BudgetArms
.proc DrawShapeToolCursor

    lda selected_tool 
    cmp #SHAPE_TOOL_ACTIVATED
    beq Use_Shape

        ; hide shape cursor
        lda #OAM_OFFSCREEN
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL

        rts 
    
    Use_Shape:

    ; hide all cursors
    jsr HideActiveCursor
    jsr HideInactiveCursors

    ; Draw Shape Cursor
    jsr LoadCursorShapeTool

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc UseFillTool
    
    ; Flood Fill

    ; VRAM DATA:
    ;    HIGH       LOW
    ; 7654 3210   7654 3210
    ; ---- --YY   YYYX XXXX

    lda tool_use_attr
    and #FILL_TOOL_ON
    bne Use_Fill
        rts 

    Use_Fill:

    ; Remove FILL_TOOL_ON from the tool_use_attributes
    lda tool_use_attr
    eor #FILL_TOOL_ON
    sta tool_use_attr

    ; Resets the scroll, so the window
    ; doesn't x doesn't change when doing stuff 
    jsr ResetScroll
    
    ; turn ppu off
    jsr PPUOff

    ; Store the current tile position to the cursor_pos 
    lda cursor_tile_position + 1
    sta fill_current_addr + 1
    lda cursor_tile_position
    sta fill_current_addr

    ; Set target color 
    jsr ReadPPUAtCurrentAddr
    sta fill_target_color

    ; if the brush tile index is not transparent, Start_Fill
    lda fill_target_color
    cmp selected_color_chr_index     ; brush_tile_index
    bne Start_Fill
        ; if transparent, Finish
        jmp Finish


    Start_Fill:
        ; initialize/Reset ring queue
        lda #$00
        sta queue_head
        sta queue_tail

        ; Push current tile to queue
        lda fill_current_addr
        ldx fill_current_addr + 1
        jsr PushToQueue


    Fill_Loop:
        ; if head == tail -> Finish, else Not_Finish
        lda queue_head
        cmp queue_tail
        bne Not_Finish 

            jmp Finish

        Not_Finish:

        ; get current color 
        jsr PopFromQueue 

        ; If color is same as target color, Fill_Loop (check next tile in queue)
        jsr ReadPPUAtCurrentAddr
        cmp fill_target_color
        bne Fill_Loop

        ; Draw current tile
        jsr WriteBrushToCurrentAddr

    Start_Algorithm:

    ; Checks if it can fill current tile, then
    ; tries to check neighbors in order:
    ; Up, Down, Left, Right
    ; if tile is good, add tile to queue 


    Try_Up:
    
        ; If tile not on top of screen, Do_Up
        GetNametableTileY fill_current_addr
        cmp #CURSOR_MIN_Y
        bne Do_Up


        ; else if tile on right side of screen, Try_Down
        clc 
        GetNametableTileX fill_current_addr
        cmp #DISPLAY_SCREEN_WIDTH
        bcc Try_Down

        ; this should never be reached
        rts 


    Try_Down:

        ; if not last row, Do_Down
        GetNametableTileY fill_current_addr
        cmp #CURSOR_MAX_Y - 1
        bne Do_Down
        
        ; if last row, try_left
        beq Try_Left

        ; this should never be reached
        rts 


    Try_Left:

        ; if not first column, Do_Left
        GetNametableTileX fill_current_addr
        cmp #CURSOR_MIN_X
        bne Do_Left

        ; if first column, Try_Right 
        beq Try_Right

        ; this should never be reached
        rts 


    Try_Right:

        ; If not last column, Do_Right
        clc 
        GetNametableTileX fill_current_addr
        cmp #CURSOR_MAX_X - 1
        bne Do_Right

        ; if last column, Loop_End
        beq Loop_End

        ; this should never be reached
        rts 


    Do_Up:

        ; Move up, by subtracing (screen_width + 1)
        sec 
        lda fill_current_addr
        sbc #DISPLAY_SCREEN_WIDTH
        sta fill_neighbor_addr

        ; Move Up
        lda fill_current_addr + 1
        sbc #0
        sta fill_neighbor_addr + 1
        
        ; If neighbor tile (up) is filled, try down
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Try_Down

        ; Add tile to queue
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue

        ; Go Try_Down
        jmp Try_Down


    Do_Down:

        ; Move down, by adding (screen_width)
        ; set neighbor tile (low)
        clc 
        lda fill_current_addr
        adc #DISPLAY_SCREEN_WIDTH
        sta fill_neighbor_addr

        ; set neighbor tile (high)
        lda fill_current_addr + 1
        adc #0
        sta fill_neighbor_addr + 1

        ; If neighbor tile (down) is filled, try left
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Try_Left

        ; Add tile to queue
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue

        ; Go Try_Left
        jmp Try_Left


    Do_Left:

        ; set neighbor tile (low) 
        sec 
        lda fill_current_addr
        sbc #1
        sta fill_neighbor_addr

        ; set neighbor tile (high) 
        lda fill_current_addr + 1
        sbc #0
        sta fill_neighbor_addr + 1


        ; If neighbor tile (left) is filled, try right
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Try_Right
        
        ; Add tile to queue
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue

        ; Go Try_Right
        jmp Try_Right


    Do_Right:

        ; Set fill_neighbor low byte address to right neighbor
        clc 
        lda fill_current_addr
        adc #1
        sta fill_neighbor_addr

        ; Set fill_neighbor high byte address to right neighbor
        lda fill_current_addr + 1
        adc #0
        sta fill_neighbor_addr + 1

        ; Check if color right is target color, if not LoopEnd
        jsr ReadPPUAtNeighbor
        cmp fill_target_color
        bne Loop_End

        ; Add tile to queue
        lda fill_neighbor_addr
        ldx fill_neighbor_addr + 1
        jsr PushToQueue

        ; Go Loop_End
        jmp Loop_End



    Loop_End:
        jmp Fill_Loop


    Finish:
        rts 

.endproc
; BudgetArms


; BudgetArms
.proc DrawShapeRectangle

    jsr PPUOff
    jsr ResetScroll

    ; Set staring pos to first pos
    lda shape_tool_first_pos
    sta shape_tool_starting_pos

    lda shape_tool_first_pos + 1
    sta shape_tool_starting_pos + 1


    ; check where the second pos X is compared to first    

    ; store rectangle width
    sec  
    lda shape_tool_second_pos
    sbc shape_tool_first_pos
    sta shape_tool_rectangle_width

    ; if first position was left of second pos, ignore
    bpl Done_Setting_X

        ; first pos is right of second pos

        ; change staring pos X 
        lda shape_tool_second_pos
        sta shape_tool_starting_pos

        ; set offset again (but no negative)
        ; store rectangle width
        sec 
        lda shape_tool_first_pos
        sbc shape_tool_second_pos
        sta shape_tool_rectangle_width


    Done_Setting_X:


    ; check where the second pos Y is compared to first    

    ; store rectangle height
    sec  
    lda shape_tool_second_pos + 1
    sbc shape_tool_first_pos + 1
    sta shape_tool_rectangle_height

    ; higher as in the value is higher
    ; but the position is lower vertically on screen than second pos
    bpl Done_Setting_Y

        ; first pos is lower than second pos

        ; change staring pos Y 
        lda shape_tool_second_pos + 1
        sta shape_tool_starting_pos + 1

        ; store rectangle height
        sec 
        lda shape_tool_first_pos + 1
        sbc shape_tool_second_pos + 1
        sta shape_tool_rectangle_height


    Done_Setting_Y:


    Done_Setting:

    ; convert rectangle width/height from pos to tile size (eg. 16 -> 2)
    lda shape_tool_rectangle_width 
    lsr 
    lsr 
    lsr 
    sta shape_tool_rectangle_width

    lda shape_tool_rectangle_height 
    lsr 
    lsr 
    lsr 
    sta shape_tool_rectangle_height

    ; the width does not include the current column/row
    ; so add + 1 to width/height
    inc shape_tool_rectangle_width
    inc shape_tool_rectangle_height


    ; set temp pos to starting pos
    lda shape_tool_starting_pos
    sta shape_tool_temp_pos

    lda shape_tool_starting_pos + 1
    sta shape_tool_temp_pos + 1
    
    ; Draw loop
    ldy #$00
    Row_Loop:
        ldx #$00
        @Column_Loop:

            DrawTile selected_color_chr_index, shape_tool_temp_pos

            ; add go to next X pos
            clc 
            lda shape_tool_temp_pos
            adc #$08
            sta shape_tool_temp_pos

            inx 

            lda shape_tool_temp_pos
            cpx shape_tool_rectangle_width
            beq @Done_Column_Loop
                jmp @Column_Loop

        @Done_Column_Loop:


        ; reset temp position to starting position
        lda shape_tool_starting_pos
        sta shape_tool_temp_pos
        lda shape_tool_starting_pos + 1
        sta shape_tool_temp_pos + 1

        ; increase row
        iny 
        tya 

        ; * 8
        asl 
        asl 
        asl 

        ; add row to temp pos
        clc 
        adc shape_tool_temp_pos + 1
        sta shape_tool_temp_pos + 1

        cpy shape_tool_rectangle_height
        beq Done_Drawing
            jmp Row_Loop    ; needs to be a jump bc range


    Done_Drawing:

    rts 

.endproc
; BudgetArms

; BudgetArms
.proc DrawShapeCircle

    jsr PPUOff
    jsr ResetScroll

    ; Besham's circle algorithm:
    ; https://fci.stafpu.bu.edu.eg/Computer%20Science/4899/crs-12417/Files/Midpoint%20Circle%20Algorithm.pdf
    ; https://stackoverflow.com/questions/59382988/filling-a-circle-produced-by-midpoint-algorithm
    

    ; Starting pos is center
    lda shape_tool_first_pos
    sta shape_tool_starting_pos
    lda shape_tool_first_pos + 1
    sta shape_tool_starting_pos + 1


    ; Calculate abosolute X
    sec 
    lda shape_tool_second_pos
    sbc shape_tool_first_pos
    bpl @Dx_Pos

        ; make negative value absolute
        eor #$FF
        adc #$01

    @Dx_Pos:
    sta shape_tool_circle_offset

    ; calculate abosolute Y
    sec 
    lda shape_tool_second_pos + 1
    sbc shape_tool_first_pos + 1
    bpl @Dy_Pos

        ; make negative value absolute
        eor #$FF
        adc #$01


    @Dy_Pos:
    sta shape_tool_circle_offset + 1

    ; Calculate radius: max + min/2 
    lda shape_tool_circle_offset
    cmp shape_tool_circle_offset + 1
    bcs @X_Is_Max
    
        ; if dy is max (or equal)
        ; r = dy + (dx / 2)
        clc 
        lda shape_tool_circle_offset
        lsr 
        adc shape_tool_circle_offset + 1
        jmp @Store_Radius


    @X_Is_Max:

    ; r = dx + (dy / 2)
    clc 
    lda shape_tool_circle_offset + 1
    lsr 
    adc shape_tool_circle_offset


    @Store_Radius:

    ; convert radius from pos to tile pos
    lsr 
    lsr 
    lsr 
    sta shape_tool_circle_radius

    ; if radius is 0, discard drawing 
    lda shape_tool_circle_radius
    beq Done_Drawing


    ; start algorithm: 
    ; x = 0
    ; y = radius
    lda #$00
    sta shape_tool_temp_pos

    lda shape_tool_circle_radius
    sta shape_tool_temp_pos + 1  

    ; Decision parameter: d = 1 - radius
    sec 
    lda #$01
    sbc shape_tool_circle_radius
    sta shape_tool_circle_decision_parameter  ; Reuse variable for 'd'

    ; Draw Loop
    Circle_Loop:
        jsr DrawCircleOctants

        ; if x >= y (aka >=45°), stop drawing
        lda shape_tool_temp_pos
        cmp shape_tool_temp_pos + 1
        bcs Done_Drawing

        ; Update decision parameter
        lda shape_tool_circle_decision_parameter
        bmi @D_Negative

        @D_Positive:
            ; d = d + 2(x-y) + 5
            clc 
            lda shape_tool_circle_decision_parameter
            adc shape_tool_temp_pos
            adc shape_tool_temp_pos

            sec 
            sbc shape_tool_temp_pos + 1
            sbc shape_tool_temp_pos + 1
            adc #$05
            sta shape_tool_circle_decision_parameter

            ; y--
            dec shape_tool_temp_pos + 1  

            jmp @Next_Iteration

        @D_Negative:
            ; d = d + 2x + 3
            clc 
            lda shape_tool_circle_decision_parameter
            adc shape_tool_temp_pos
            adc shape_tool_temp_pos
            adc #$03
            sta shape_tool_circle_decision_parameter

        @Next_Iteration:
            ; x++
            inc shape_tool_temp_pos
            jmp Circle_Loop

    Done_Drawing:
    rts 

.endproc
; BudgetArms


; BudgetArms
.proc DrawCircleOctants

    ; Octants visual representation:
    ;       8 8 1 1
    ;    7           2
    ;  7               2
    ; 6                 3
    ; 6                 3
    ;  5               4
    ;    5           4
    ;       5 5 4 4


    ; convert x/y pos to tile pos
    lda shape_tool_temp_pos
    asl 
    asl 
    asl 
    sta shape_tool_circle_offset

    lda shape_tool_temp_pos + 1
    asl 
    asl 
    asl 
    sta shape_tool_circle_offset + 1


    ; Octant 1: (CenterX + x, CenterY - y)
    clc 
    lda shape_tool_starting_pos
    adc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos

    sec 
    lda shape_tool_starting_pos + 1
    sbc shape_tool_circle_offset + 1       
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    ; Octant 2: (CenterX + y, CenterY - x)
    clc 
    lda shape_tool_starting_pos
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    sec 
    lda shape_tool_starting_pos + 1
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    ; Octant 3: (CenterX + y, CenterY + x)
    clc 
    lda shape_tool_starting_pos
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    ; Octant 4: (CenterX + x, CenterY + y)
    clc 
    lda shape_tool_starting_pos
    adc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    ; Octant 5: (CenterX - x, CenterY + y)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    ; Octant 6: (CenterX - y, CenterY + x)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    ; Octant 7: (CenterX - y, CenterY - x)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    sec 
    lda shape_tool_starting_pos + 1
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    ; Octant 8: (CenterX - x, CenterY - y)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos

    sec 
    lda shape_tool_starting_pos + 1
    sbc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos + 1

    DrawTile selected_color_chr_index, shape_tool_circle_draw_pos


    rts 

.endproc
