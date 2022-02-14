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
    filenames = sys.argv[1:]
    i = 0
    for filename in filenames:
        im=Image.open(filename)
        width, height = im.size
        if width != 8 or height != 8:
            print("The specified image does not meet the size requirements of 8x8 pixels")
            return
        print(f";{filename}, {i}:")
        print(convert_image(im))
        i = i + 1

def is_color_close(color1, color2):
    return abs(color1 - color2[0]) < 35

def convert_image(im):
    width, height = im.size
    pixels = list(im.getdata())
    result = "db "
    for y in range(height):
        byte1 = 0
        byte2 = 0
        for x in range(width):
            color = pixels[width*y + x]
            if is_color_close(color, WHITE):
                #0,0
                pass
            elif is_color_close(color, LIGHTGREY):
                #1,0
                byte1 = set_bit(byte1, 7-x)
            elif is_color_close(color, DARKGREY):
                #0,1
                byte2 = set_bit(byte2, 7-x)
            elif is_color_close(color, BLACK):
                #0,1
                byte1 = set_bit(byte1, 7-x)
                byte2 = set_bit(byte2, 7-x)
            else:
                print("Invalid color found, must be white, light gray, dark gray or black!")
                return
        result += f"${byte1:02x},${byte2:02x}, "
    return result


if __name__ == "__main__":
    main()