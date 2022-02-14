#!/usr/bin/env python3
"""
Script for cutting up a larger image into 8x8 tiles
"""

#!/usr/bin/env python3
"""
Script for converting a tile (8x8) image to hex data for assembly
"""

from PIL import Image
import sys

def main():
    if len(sys.argv) < 2:
        print("Please specify an image to convert")
        return
    filenames = sys.argv[1:]
    for filename in filenames:
        im=Image.open(filename)
        width, height = im.size
        if width % 8 != 0 or height % 8 != 0:
            print("The image size must be a multiple of 8x8")
            return
        cut_image(im, filename)
        print(f"Cutting complete for {filename}")

def cut_image(im, filename):
    width, height = im.size
    pixels = list(im.getdata())
    subpixels = [(0,0,0)] * 8 * 8
    for ty in range(height//8):
        for tx in range(width//8):
            for ry in range(8):
                for rx in range(8):
                    subpixels[ry*8 + rx] = pixels[width*(ty*8+ry) + tx*8 + rx]
            subimage = Image.new(im.mode, (8, 8))
            subimage.putdata(subpixels)
            subimage.save(f"{filename}-{tx}x{ty}.png")


if __name__ == "__main__":
    main()