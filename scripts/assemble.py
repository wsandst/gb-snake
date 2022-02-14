#!/usr/bin/env python3
"""
Script assembling several tile images into a larger tilemap.
If the first argument is a number, the tile ids will be offset by the number
"""

from PIL import Image
import sys

from tiles import convert_image

def main():
    if len(sys.argv) < 2:
        print("Please specify cut-up images to assemble")
        return

    if sys.argv[1].isnumeric():
        i = int(sys.argv[1])
        filenames = sys.argv[2:]
    else:
        i = 0
        filenames = sys.argv[1:]

    tilemap = [0] * 18*20 

    tiledata_str = ""
    tilemap_str = ""

    tiledata_str_map = {}
    for filename in filenames:
        # Make sure the specified file is valid
        if "-" not in filename and "x" not in filename:
            print(f"Invalid filename '{filename}' specified")
            continue

        im=Image.open(filename)
        width, height = im.size
        if width % 8 != 0 or height % 8 != 0:
            print("The image size must be a multiple of 8x8")
            continue

        tile_coord = filename.split("-")[1].split("x")
        tile_x = int(tile_coord[0])
        tile_y = int(tile_coord[1].split(".")[0])

        img_str = convert_image(im)

        if img_str in tiledata_str_map:
            # If this same data is already used, reuse it
            tilemap[tile_y*20 + tile_x] = tiledata_str_map[img_str]
            continue
    
        tiledata_str_map[img_str] = i

        tiledata_str += "    " + f";{filename}, {i}:\n"
        tiledata_str += "    " + img_str + "\n"

        tilemap[tile_y*20 + tile_x] = i

        i += 1
        print(f"Conversion complete for {filename}")

    print("\nTiledata:")
    print(tiledata_str)

    # Create tilemap
    for y in range(18):
        row_str = "    db"
        for x in range(20):
            row_str += f" {tilemap[y*20+x]:>3},"
        tilemap_str += row_str + "    0,0,0,0,0,0,0,0,0,0,0,0\n"

    print("\nTilemap:")
    print(tilemap_str)

if __name__ == "__main__":
    main()