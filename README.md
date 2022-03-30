# Snake - Gameboy
A simple implementation of the game Snake in Gameboy Assembly. Made for the original Gameboy (DMG). The project uses RGBDS to assemble a Gameboy ROM. This project was made to gain further understanding of the Gameboy architecture. Various useful scripts for generating Gameboy graphics can be found under `scripts/`.

## Challenges
The Gameboy architecture is tile based and the screen can fit 18x20 tiles. This is problematic when implementing Snake, as 18x20 is quite a small grid for a snake game. The solution to this issue was to use subtile positions by subdiving every tile into 4 subtiles and then including tiles for every possible combination of these subtiles. This complicated the code but makes for a better snake game.

## Build instructions
RGBDS is required to assemble the game. Once installed, run `make` in the root directory. The rom file will now be available under `build/snake.gb`.