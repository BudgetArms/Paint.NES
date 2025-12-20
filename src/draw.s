; File for all drawing functions

; BudgetArms / Khine
.proc LoadCursorSprite

    jsr HideCursorSprite

    lda player + P_CURSOR_SIZE

    cmp #TYPE_CURSOR_NORMAL
    bne Not_Normal_Cursor
        lda player + P_SELECTED_TOOL
        cmp #SHAPE_TOOL_SELECTED
        bne :+
            jsr LoadShapeToolCursorSprite

            rts 
        :

        lda #<CURSOR_NORMAL_DATA
        sta abs_address_to_access

        lda #>CURSOR_NORMAL_DATA
        sta abs_address_to_access + 1

        ldx #OAM_BYTE_SIZE_CURSOR_NORMAL
        jmp Start_Load

    Not_Normal_Cursor:

    cmp #TYPE_CURSOR_MEDIUM
    bne Not_Medium_Cursor

        lda #<CURSOR_MEDIUM_DATA
        sta abs_address_to_access

        lda #>CURSOR_MEDIUM_DATA
        sta abs_address_to_access + 1

        ldx #OAM_BYTE_SIZE_CURSOR_MEDIUM
        jmp Start_Load

    Not_Medium_Cursor:

    cmp #TYPE_CURSOR_BIG
    bne Not_Big_Cursor

        lda #<CURSOR_BIG_DATA
        sta abs_address_to_access

        lda #>CURSOR_BIG_DATA
        sta abs_address_to_access + 1

        ldx #OAM_BYTE_SIZE_CURSOR_BIG
        jmp Start_Load

    Not_Big_Cursor:

    Start_Load:

    ldy player + P_INDEX
    cpy #PLAYER_1
    bne Player_2

    Player_1:
        ldy #$00
        Player_1_Loop:
            lda (abs_address_to_access), Y
            sta oam + OAM_OFFSET_P1_CURSOR, Y

            iny 
            dex 
            bne Player_1_Loop  ; loop until all bytes are loaded

        rts 

    Player_2:
        ldy #$00
        Player_2_Loop:
            lda (abs_address_to_access), Y
            sta oam + OAM_OFFSET_P2_CURSOR, Y
            
            iny 
            dex 
            bne Player_2_Loop  ; loop until all bytes are loaded

        rts 

.endproc
; BudgetArms / Khine


; BudgetArms / Khine
.proc LoadShapeToolCursorSprite

    ldy player + P_SHAPE_TOOL_TYPE

    cpy #SHAPE_TOOL_TYPE_CIRCLE
    bne :+
        lda #TILEINDEX_CURSOR_SHAPE_TOOL_CIRCLE
    :

    cpy #SHAPE_TOOL_TYPE_RECTANGLE
    bne :+
        lda #TILEINDEX_CURSOR_SHAPE_TOOL_RECT
    :

    clc 
    adc player + P_SHAPE_TOOL_FIRST_SET
    tax 


    lda player + P_INDEX

    cmp #PLAYER_1
    bne :+
        stx oam + OAM_OFFSET_P1_CURSOR + OAM_TILE
        rts 
    :

    cmp #PLAYER_2
    bne :+
        stx oam + OAM_OFFSET_P2_CURSOR + OAM_TILE
        rts 
    :

    rts 

.endproc
; BudgetArms / Khine


; Khine / BudgetArms / Jeronimas
.proc UseBrushTool

    lda player + P_SELECTED_TOOL
    cmp #ERASER_TOOL_SELECTED
    bne :+
        lda #BACKGROUND_TILE_INDEX
        sta drawing_color_tile_index
        jmp :++
    :
        lda player + P_SELECTED_COLOR_INDEX
        sta drawing_color_tile_index
    :

    jsr PlayToolSoundEffect

    ; Store the tile position in a different var
    ; This is done so that the cursor position can stay on the original spot
    ; after drawing has completed.

    ldy #$00
    @Column_Loop:
        ; Reset address latch
        lda PPU_STATUS 

        lda player + P_TILE_ADDR + 1 ; High bit of the location
        sta PPU_ADDR

        lda player + P_TILE_ADDR ; Low bit of the location
        sta PPU_ADDR

        lda drawing_color_tile_index
        ldx #$00
        @Row_Loop:
            sta PPU_DATA

            inx 
            cpx player + P_CURSOR_SIZE
            bne @Row_Loop

        clc 
        lda player + P_TILE_ADDR
        adc #32
        sta player + P_TILE_ADDR

        lda player + P_TILE_ADDR + 1
        adc #$00
        sta player + P_TILE_ADDR + 1

        iny 

        cpy player + P_CURSOR_SIZE
        bne @Column_Loop

    rts 

.endproc
; Khine / BudgetArms


; BudgetArms
.proc UseShapeTool

    jsr PlayToolSoundEffect

    ; Change things
    lda player + P_SHAPE_TOOL_FIRST_SET
    bne Second_Position
    
    First_Position:
        ; First position set
        ; store x/y
        lda player + P_X_POS
        sta player + P_SHAPE_TOOL_FIRST_POS

        ;lda cursor_y
        lda player + P_Y_POS
        sta player + P_SHAPE_TOOL_FIRST_POS + 1

        lda #$01
        sta player + P_SHAPE_TOOL_FIRST_SET
        jsr LoadShapeToolCursorSprite

        rts 

    Second_Position:
        ; Second position set

        ; if first pos and second pos the same, rts, else @Use_Second_Position
        ;lda cursor_x
        lda #$00
        sta shape_tool_same_pos

        lda player + P_X_POS
        cmp player + P_SHAPE_TOOL_FIRST_POS
        bne :+
            inc shape_tool_same_pos
        :

        lda player + P_Y_POS
        cmp player + P_SHAPE_TOOL_FIRST_POS + 1
        bne :+
            inc shape_tool_same_pos
        :

        lda shape_tool_same_pos
        cmp #$02
        bne :+
            rts
        :

        lda #$00
        sta player + P_SHAPE_TOOL_FIRST_SET
        jsr LoadShapeToolCursorSprite

        ; store x/y
        lda player + P_X_POS
        sta player + P_SHAPE_TOOL_SECOND_POS

        lda player + P_Y_POS
        sta player + P_SHAPE_TOOL_SECOND_POS + 1

        ; Rectangle
        lda player + P_SHAPE_TOOL_TYPE

        cmp #SHAPE_TOOL_TYPE_RECTANGLE
        bne @Not_Rectangle_Type

            ; if rectangle mode
            jsr DrawShapeRectangle
            rts 

        @Not_Rectangle_Type:

        ; Circle
        cmp #SHAPE_TOOL_TYPE_CIRCLE
        bne @Not_Circle_Type

            ; if circle mode
            jsr DrawShapeCircle
            rts 

        @Not_Circle_Type:

        ; this should never be reached
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


    ; Store the current tile position to the cursor_pos
    lda player + P_TILE_ADDR + 1
    sta fill_current_addr + 1

    lda player + P_TILE_ADDR
    sta fill_current_addr

    jsr PlayToolSoundEffect

    ; Resets the scroll, so the window
    ; doesn't x doesn't change when doing stuff 
    jsr ResetScroll

    ; turn ppu off
    jsr PPUOff

    ; Set target color 
    jsr ReadPPUAtCurrentAddr
    sta fill_target_color

    ; if the brush tile index is not transparent, Start_Fill
    lda fill_target_color
    cmp player + P_SELECTED_COLOR_INDEX
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

    ; Checking neighbors:
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


    ; Store starting position X & rectangle width

    ; check where the second pos X is compared to first    
    lda player + P_SHAPE_TOOL_FIRST_POS
    cmp player + P_SHAPE_TOOL_SECOND_POS
    bcs First_PosX_Right_Of_Second_PosX

    First_PosX_Left_Of_Second_PosX:

        ; Store rectangle width
        sec  
        lda player + P_SHAPE_TOOL_SECOND_POS
        sbc player + P_SHAPE_TOOL_FIRST_POS
        sta shape_tool_rectangle_width

        ; Store starting position X
        lda player + P_SHAPE_TOOL_FIRST_POS
        sta shape_tool_starting_pos

        jmp Done_Setting_X


    First_PosX_Right_Of_Second_PosX:

        ; Store rectangle width
        sec  
        lda player + P_SHAPE_TOOL_FIRST_POS
        sbc player + P_SHAPE_TOOL_SECOND_POS
        sta shape_tool_rectangle_width

        ; change staring pos X 
        lda player + P_SHAPE_TOOL_SECOND_POS
        sta shape_tool_starting_pos

        jmp Done_Setting_X
    

    Done_Setting_X:


    ; Store starting position Y & rectangle height

    ; check where the second pos Y is compared to first    
    lda player + P_SHAPE_TOOL_FIRST_POS + 1
    cmp player + P_SHAPE_TOOL_SECOND_POS + 1
    bcs First_PosY_Below_Second_PosY

    First_PosY_Above_Second_PosY:

        ; Store rectangle height
        sec  
        lda player + P_SHAPE_TOOL_SECOND_POS + 1
        sbc player + P_SHAPE_TOOL_FIRST_POS + 1
        sta shape_tool_rectangle_height

        ; Store starting position Y
        lda player + P_SHAPE_TOOL_FIRST_POS + 1
        sta shape_tool_starting_pos + 1

        jmp Done_Setting_Y


    First_PosY_Below_Second_PosY:

        ; Store rectangle height
        sec  
        lda player + P_SHAPE_TOOL_FIRST_POS + 1
        sbc player + P_SHAPE_TOOL_SECOND_POS + 1
        sta shape_tool_rectangle_height

        ; change staring pos Y
        lda player + P_SHAPE_TOOL_SECOND_POS + 1
        sta shape_tool_starting_pos + 1

        jmp Done_Setting_Y
    

    Done_Setting_Y:


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

            DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_temp_pos

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
    lda player + P_SHAPE_TOOL_FIRST_POS
    sta shape_tool_starting_pos

    lda player + P_SHAPE_TOOL_FIRST_POS + 1
    sta shape_tool_starting_pos + 1


    ; Calculate abosolute X
    sec 
    lda player + P_SHAPE_TOOL_SECOND_POS
    sbc player + P_SHAPE_TOOL_FIRST_POS
    bpl @Dx_Pos

        ; make negative value absolute
        eor #$FF
        adc #$01

    @Dx_Pos:
    sta shape_tool_circle_offset

    ; calculate abosolute Y
    sec 
    lda player + P_SHAPE_TOOL_SECOND_POS + 1
    sbc player + P_SHAPE_TOOL_FIRST_POS + 1
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


; Khine
.proc LoadTilemapToNameTable1

    jsr PPUOff

    ldx PPU_STATUS ; reset address latch

    ldx #>NAME_TABLE_1 ; High bit of the location
    stx PPU_ADDR

    ldx #<NAME_TABLE_1 ; Low bit of the location
    stx PPU_ADDR

    ldx #$00
    @Outer_Loop:
        ldy #$00

        @Inner_Loop:
            lda (abs_address_to_access), y
            sta PPU_DATA

            iny 
            bne @inner_loop

        lda abs_address_to_access + 1
        clc 
        adc #$01
        sta abs_address_to_access + 1

        inx 
        cpx #$04 ; todo: change to variable
        bne @outer_loop

    rts 

.endproc
; Khine


; Khine
.proc LoadTilemapWithTransition

    ldx PPU_STATUS ; reset address latch

    ldx current_transition_addr + 1
    stx PPU_ADDR

    ldx current_transition_addr ; Low bit of the location
    stx PPU_ADDR

    ldx #$00
    ldy #$00
    Loop:
        lda (abs_address_to_access), y
        sta PPU_DATA

        lda abs_address_to_access
        clc 
        adc #$01
        sta abs_address_to_access

        lda abs_address_to_access + 1
        adc #$00
        sta abs_address_to_access + 1

        lda current_transition_addr
        clc 
        adc #$01
        sta current_transition_addr

        lda current_transition_addr + 1
        adc #$00
        sta current_transition_addr + 1

        inx 
        cpx #TRANSITION_SPEED
        bne Loop

    rts 

.endproc
; Khine


; Khine
.proc LoadTilemapToNameTable3

    jsr PPUOff

    ldx PPU_STATUS ; reset address latch

    ldx #>NAME_TABLE_3 ; High bit of the location
    stx PPU_ADDR

    ldx #<NAME_TABLE_3 ; Low bit of the location
    stx PPU_ADDR

    ldx #$00
    @Outer_Loop:
        ldy #$00

        @Inner_Loop:
            lda (abs_address_to_access), y
            sta PPU_DATA
        
            iny 
            bne @Inner_Loop

        lda abs_address_to_access + 1
        clc 
        adc #$01
        sta abs_address_to_access + 1

        inx 
        cpx #$04 ; todo: change to variable
        bne @Outer_Loop

    rts 

.endproc
; Khine


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

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    ; Octant 2: (CenterX + y, CenterY - x)
    clc 
    lda shape_tool_starting_pos
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    sec 
    lda shape_tool_starting_pos + 1
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    ; Octant 3: (CenterX + y, CenterY + x)
    clc 
    lda shape_tool_starting_pos
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    ; Octant 4: (CenterX + x, CenterY + y)
    clc 
    lda shape_tool_starting_pos
    adc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos + 1

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    ; Octant 5: (CenterX - x, CenterY + y)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos + 1

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    ; Octant 6: (CenterX - y, CenterY + x)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    clc 
    lda shape_tool_starting_pos + 1
    adc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    ; Octant 7: (CenterX - y, CenterY - x)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos

    sec 
    lda shape_tool_starting_pos + 1
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos + 1

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    ; Octant 8: (CenterX - x, CenterY - y)
    sec 
    lda shape_tool_starting_pos
    sbc shape_tool_circle_offset
    sta shape_tool_circle_draw_pos

    sec 
    lda shape_tool_starting_pos + 1
    sbc shape_tool_circle_offset + 1
    sta shape_tool_circle_draw_pos + 1

    DrawTile player + P_SELECTED_COLOR_INDEX, shape_tool_circle_draw_pos


    rts 

.endproc
; BudgetArms

