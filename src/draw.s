;file for all drawing functions

; BudgetArms / Khine
.proc LoadCursorSprite

    jsr HideCursorSprite

    lda current_player_properties + P_CURSOR_SIZE

    cmp #TYPE_CURSOR_NORMAL
    bne :+
        lda #<CURSOR_NORMAL_DATA
        sta abs_address_to_access
        lda #>CURSOR_NORMAL_DATA
        sta abs_address_to_access + 1
        ldx #OAM_BYTE_SIZE_CURSOR_NORMAL
        jmp Start_Load
    :

    cmp #TYPE_CURSOR_MEDIUM
    bne :+
        lda #<CURSOR_MEDIUM_DATA
        sta abs_address_to_access
        lda #>CURSOR_MEDIUM_DATA
        sta abs_address_to_access + 1
        ldx #OAM_BYTE_SIZE_CURSOR_MEDIUM
        jmp Start_Load
    :

    cmp #TYPE_CURSOR_BIG
    bne :+
        lda #<CURSOR_BIG_DATA
        sta abs_address_to_access
        lda #>CURSOR_BIG_DATA
        sta abs_address_to_access + 1
        ldx #OAM_BYTE_SIZE_CURSOR_BIG
        jmp Start_Load
    :

    Start_Load:
    ldy current_player_properties + P_INDEX
    cpy #PLAYER_1
    bne P2

    P1:
        ldy #$00
        P1_Loop:
            lda (abs_address_to_access), Y
            sta oam + OAM_OFFSET_P1_CURSOR, Y
            iny
            dex
            bne P1_Loop  ; loop until all bytes are loaded
        rts
    P2:
        ldy #$00
        P2_Loop:
            lda (abs_address_to_access), Y
            sta oam + OAM_OFFSET_P2_CURSOR, Y
            iny
            dex
            bne P2_Loop  ; loop until all bytes are loaded
        rts

.endproc
; BudgetArms / Khine


; BudgetArms
.proc LoadCursorShapeTool

    ; check what cursor should be loaded
    lda shape_tool_has_set_first_pos
    bne Second_Cursor

    ; Load first shape cursor
    ldx #$00

    @Loop:
        lda CURSOR_SHAPE_TOOL_DATA, X
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL, X
        inx 

        cpx #OAM_BYTE_SIZE_CURSOR_SHAPE
        bne @Loop

    jmp Update_Cursor_Shape_Position


    Second_Cursor:
    ; Load second shape cursor
    ldx #$00

    @Loop:
        lda CURSOR_SHAPE_TOOL_DATA + 4, X  ; 4 is the next sprite
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL, X

        inx 

        cpx #OAM_BYTE_SIZE_CURSOR_SHAPE
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
    ;lda tool_use_flag, x
    ;lda current_player_properties + P_TOOL_USE_FLAG
    ;and #BRUSH_TOOL_ON
    ;bne @Use_Brush
        ;rts

    ;@Use_Brush:
    ;lda tool_use_flag, x
    ;lda current_player_properties + P_TOOL_USE_FLAG
    ;eor #BRUSH_TOOL_ON
    ;sta tool_use_flag, x
    ;sta current_player_properties + P_TOOL_USE_FLAG

    lda current_player_properties + P_TILE_ADDR
    sta drawing_tile_position
    lda current_player_properties + P_TILE_ADDR + 1
    sta drawing_tile_position + 1

    ;lda selected_tool, x
    lda current_player_properties + P_SELECTED_TOOL
    cmp #ERASER_TOOL_SELECTED
    bne :+
        lda #BACKGROUND_TILE_INDEX
        sta drawing_color_tile_index
        jmp :++
    :
        ;lda selected_color_chr_index, x
        lda current_player_properties + P_SELECTED_COLOR_INDEX
        sta drawing_color_tile_index
    :

    jsr PlayBrushSoundEffect

    ; Store the tile position in a different var
    ; This is done so that the cursor position can stay on the original spot
    ; after drawing has completed.

    ; square brush
    ldy #$00
    @column_loop:
        lda PPU_STATUS ; reset address latch
        lda drawing_tile_position + 1 ; High bit of the location
        sta PPU_ADDR
        lda drawing_tile_position ; Low bit of the location
        sta PPU_ADDR

        lda drawing_color_tile_index
        ldx #$00
        @row_loop:
            sta PPU_DATA
            inx
            ;cpx cursor_size
            cpx current_player_properties + P_CURSOR_SIZE
            bne @row_loop

        clc
        lda drawing_tile_position
        adc #32
        sta drawing_tile_position
        lda drawing_tile_position + 1
        adc #$00
        sta drawing_tile_position + 1
        iny
        ;cpy cursor_size
        cpy current_player_properties + P_CURSOR_SIZE
        bne @column_loop

    rts

.endproc
; Khine / BudgetArms

; BudgetArms
.proc UseShapeTool

    lda tool_use_flag
    and #SHAPE_TOOL_ON
    bne Use_Shape
        rts 
    
    Use_Shape:

    ; Remove SHAPE_TOOL_ON from the tool_use_flagibutes
    lda tool_use_flag
    eor #SHAPE_TOOL_ON
    sta tool_use_flag

    ; Change things
    lda shape_tool_has_set_first_pos
    bne Second_Position
    
    First_Position:
        ; First position set

        ; if current pos same as previous shape's tool second pos
        ; eg. bc called on held, fix it by checking if it's still in the same location
        lda cursor_x
        cmp shape_tool_second_pos_x
        bne @Use_Second_Position

        lda cursor_y
        cmp shape_tool_second_pos_y
        bne @Use_Second_Position

        ; if current pos == previous pos
        jmp Finish


        @Use_Second_Position:

        lda #$01
        sta shape_tool_has_set_first_pos
    
        ; store x/y
        lda cursor_x
        sta shape_tool_first_pos_x

        lda cursor_y
        sta shape_tool_first_pos_y
        
        rts 


    Second_Position:
        ; Second position set

        ; if first pos and second pos the same, rts, else @Use_Second_Position
        lda cursor_x
        cmp shape_tool_first_pos_x
        bne @Use_Second_Position

        lda cursor_y
        cmp shape_tool_first_pos_y
        bne @Use_Second_Position


        ; if First pos == Second pos, rts
        rts 


        @Use_Second_Position:

        lda #$00
        sta shape_tool_has_set_first_pos

        ; store x/y
        lda cursor_x
        sta shape_tool_second_pos_x

        lda cursor_y
        sta shape_tool_second_pos_y
        

        ; Rectangle
        lda shape_tool_type
        and #SHAPE_TOOL_TYPE_RECTANGLE
        bne @Not_Rectangle_Type

            ; if rectangle mode
            jsr DrawShapeRectangle
            rts 

        @Not_Rectangle_Type:

        ; Circle
        lda shape_tool_type
        and #SHAPE_TOOL_TYPE_CIRCLE
        bne @Not_Circle_Type

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
    cmp #SHAPE_TOOL_SELECTED
    beq Use_Shape

        ; hide shape cursor
        lda #OAM_OFFSCREEN
        sta oam + OAM_OFFSET_CURSOR_SHAPE_TOOL

        rts 
    
    Use_Shape:

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
    ;lda tool_use_flag, x
    ;lda current_player_properties + P_TOOL_USE_FLAG
    ;and #FILL_TOOL_ON
    ;bne @Use_Fill
        ;rts

    ;@Use_Fill:
    ;lda tool_use_flag, x
    ;lda current_player_properties + P_TOOL_USE_FLAG
    ;eor #FILL_TOOL_ON
    ;sta tool_use_flag, x
    ;sta current_player_properties + P_TOOL_USE_FLAG

    ; Store the current tile position to the cursor_pos
    lda current_player_properties + P_TILE_ADDR + 1
    sta fill_current_addr + 1
    lda current_player_properties + P_TILE_ADDR
    sta fill_current_addr

    ;cpx #$00
    ;beq P1
    ;P2:
    ;    lda p2_cursor_tile_position + 1
    ;    sta fill_current_addr + 1
    ;    lda p2_cursor_tile_position
    ;    sta fill_current_addr
    ;    jmp End_Assignment
    ;P1:
    ;    lda p1_cursor_tile_position + 1
    ;    sta fill_current_addr + 1
    ;    lda p1_cursor_tile_position
    ;    sta fill_current_addr
    ;End_Assignment:

    ; Resets the scroll, so the window
    ; doesn't x doesn't change when doing stuff 
    jsr ResetScroll

    ; turn ppu off
    jsr PPUOff

    ; Set target color 
    jsr ReadPPUAtCurrentAddr
    sta fill_target_color

    ; if the brush tile index is not transparent, Start_Fill
    ;ldx current_player
    lda fill_target_color
    ;cmp selected_color_chr_index, x     ; brush_tile_index
    cmp current_player_properties + P_SELECTED_COLOR_INDEX
    bne Start_Fill
        ; if transparent, Finish
        jmp Finish


    Start_Fill:
        ; initialize/Reset ring queue
        lda #$0
        sta queue_head
        sta queue_tail

        ; draw tile
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

    ; Set staring pos to first pos
    lda shape_tool_first_pos_x
    sta shape_tool_staring_pos_x

    lda shape_tool_first_pos_y
    sta shape_tool_staring_pos_y

    ; check where the second pos X is compared to first    

    ; X offset is stored in X
    sec  
    lda shape_tool_second_pos_x
    sbc shape_tool_first_pos_x

    tax 

    bpl First_Pos_Is_Left_Of_Second_Pos

        ; first pos is right of second pos

        ; change staring pos X 
        lda shape_tool_second_pos_x
        sta shape_tool_staring_pos_x


    First_Pos_Is_Left_Of_Second_Pos:


    ; Y offset is stored in Y
    sec 
    sta shape_tool_first_pos_y
    sbc shape_tool_second_pos_y
    

    rts 

.endproc
; BudgetArms


; BudgetArms
.proc DrawShapeCircle

    ; stub (aka yet to be implemented)

    rts 

.endproc
; BudgetArms


; Khine
.proc LoadTilemap
    lda PPU_STATUS ; reset address latch
    lda #>NAME_TABLE_1 ; High bit of the location
    sta PPU_ADDR
    lda #<NAME_TABLE_1 ; Low bit of the location
    sta PPU_ADDR

    ldx #$00
    lda #<Canvas_UI_Tilemap
    sta abs_address_to_access
    lda #>Canvas_UI_Tilemap
    sta abs_address_to_access + 1
    @outer_loop:
    ldy #$00
        @inner_loop:
        lda (abs_address_to_access), y
        sta PPU_DATA
        iny
        bne @inner_loop
    lda abs_address_to_access + 1
    clc
    adc #$01
    sta abs_address_to_access + 1
    inx
    cpx #$04
    bne @outer_loop

    rts

.endproc
; Khine