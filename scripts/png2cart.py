# Convert a 128x128 png into a cartridge with the png data in the sprite section

# TODO: support alternate palette?

import sys
from PIL import Image
import numpy as np

PALETTE = np.array([
    [0, 0, 0],
    [29, 43, 83],
    [126, 37, 83],
    [0, 135, 81],
    [171, 82, 54],
    [95, 87, 79],
    [194, 195, 199],
    [255, 241, 232],
    [255, 0, 77],
    [255, 163, 0],
    [255, 236, 39],
    [0, 228, 54],
    [41, 173, 255],
    [131, 118, 156],
    [255, 119, 168],
    [255, 204, 170],
])

if len(sys.argv) < 3:
    print("USAGE: png2cart.py <input png> <output p8>")
    sys.exit(1)

img = Image.open(sys.argv[1])
pixels = img.load()

img_w, img_h = img.size
if img_w != 128 or img_h != 128:
    print("only images of size 128x128 are supported")
    sys.exit(1)

print('pico-8 cartridge // http://www.pico-8.com')
print('version 42')
print('__gfx__') # export to gfx section

for j in range(128):
    for i in range(128):
        dist = (PALETTE - np.array(pixels[i, j]))**2
        dist = np.sqrt(np.sum(dist, axis=1))
        col = hex(np.argmin(dist))[2:]
        print(col, end="")
    print("")


