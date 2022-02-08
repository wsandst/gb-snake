#!/usr/bin/env python3
"""
Script for converting a tile (8x8) image to hex data for assembly
"""

from PIL import Image
import sys

WHITE = (255, 255, 255, 255)
LIGHTGREY = (170, 170, 170, 255)
DARKGREY = (85, 85, 85, 255)
BLACK = (0, 0, 0, 255)

def set_bit(value, bit):
    return value | (1<<bit)

def clear_bit(value, bit):
    return value & ~(1<<bit)

def main():
    if len(sys.argv) < 2:
        print("Please specify an image to convert")
        return
    filename = sys.argv[1]
    im=Image.open(filename)
    width, height = im.size
    if width != 8 or height != 8:
        print("The specified image does not meet the size requirements of 8x8 pixels")
        return

    pixels = list(im.getdata())
    result = "db "
    for y in range(height):
        byte1 = 0
        byte2 = 0
        for x in range(width):
            color = pixels[width*y + x]
            if color == WHITE:
                #0,0
                pass
            elif color == LIGHTGREY:
                #1,0
                byte1 = set_bit(byte1, 7-x)
            elif color == DARKGREY:
                #0,1
                byte2 = set_bit(byte2, 7-x)
            elif color == BLACK:
                #0,1
                byte1 = set_bit(byte1, 7-x)
                byte2 = set_bit(byte2, 7-x)
            else:
                print("Invalid color found, must be white, light gray, dark gray or black!")
                return
        result += f"${byte1:02x},${byte2:02x}, "
    print(result)


if __name__ == "__main__":
    main()