# PAINT.NES

## Introduction
Paint.NES is painting program, developped for the NES console. It was developped mostly using Mesen the emulator, for tests, but the program was tested weekly on an actual NES aswell. And thus, every feature should work as intended.

## Fun description
In this game, you get an empty canvas to fill with your own creativity. You can use a bunch of different tools, such as the fill tool, or the shape tool to really bring the canvas to life. There are about 55 colors to pick from, and you can use up to 4 of them at the same time.


## Buttons
Because of the various menus that are implemented. The input can sometimes vary slightly based on what menu the player is in.

When in canvas:
single buttons:
    D-Pad : moves the cursor
    A : use tool
    B : change tool properties, eg: brushsize, rectangle to circle, etc.
combos:
    Select + left/right D-PAD : select one of the 4 colors
    Select + down/up D-PAD    : change colorvalue of the selected color
    Start + left/right D-PAD  : select tool
    Select + start : go to help-menu

When in a menu:
    D-Pad : moves the 'cursor'
    A : select option

When in help-menu:
    A : save
    B : continue
    Start : restart program


## Start menu
The start menu will be shown at the start of the game. It gives the player the option to play single-player, or multi-player (up to 2 controllers can be used to play the game).


### Help menu
A menu that shows the player the controls for the game, and also gives the option to save, load, or start a new game


## Technical description
The 'game' can be played with up to 2 players at once, meaning you can draw together. Both players can select and use the same or a different color to draw, or use any tool.
There are 5 working tools:
    - Brush tool:
        When pressing A, the tile or tiles selected by the cursor will be filled with the selected color
        When pressing B, the cursorsize will cycle through 3 sizes. 1x1 tile (1 tile), 2x2 tiles (4 tiles), 3x3 tiles (9 tiles).
    - Eraser tool:
        When pressing A, the tile or tiles selected by the cursor will be filled with the background color
        When pressing B, the cursorsize will cycle through 3 sizes. 1x1 tile (1 tile), 2x2 tiles (4 tiles), 3x3 tiles (9 tiles).
    - Fill tool:
        When pressing A, if the cursor is inside any kind of shape, the inside of that shape will be filled with the selected color. If the cursor is not inside any kind of shape, the entire screen will be filled.
    - Shape tool:
        When pressing A, First press: pick a starting point. Second press: pick an endpoint.
        When pressing B, a different shape will be chosen. There are 2 shapes: rectangle, circle.
    - Clear tool:
        When pressing A, the entire canvas will be set to the background color.
        
    The player can freely change any of the 4 colors in the collorpallete to any possible colorvalue the NES has.
    The player can select any of the 4 colors to use for drawing, or filling, etc.
    These colors, and which color is selected, is displayed on the top left of the canvas overlay.
    On the top center/right, the available tools, and which one is selected is displayed.
    On the bottom left the x- and y-position of the cursor are shown.
    on the bottom right, it says in text which tool is selected. 


## Credits
'The Painters' consisting of:
- Khine Lin Kyaw
- Joren Soenen
- Jeronimas Boots
- Polle Desutter