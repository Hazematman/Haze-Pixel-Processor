#!/usr/bin/env python3
import sys
from PIL import Image

TILE_SIZE = 256*24
TILE_OFFSET = 0
NAMETABLE_OFFSET = TILE_OFFSET + TILE_SIZE
NAMETABLE_SIZE = 64*60 + (64*60)//4
ATTR_OFFSET = TILE_OFFSET + TILE_SIZE + 64*60
PALETTE_OFFSET = NAMETABLE_OFFSET + NAMETABLE_SIZE
PALETTE_SIZE = 20

def write_tile(tile_data, index, vram):
    tile_bytes = [0]*24
    byte_index = 0
    cur_byte = 0
    cur_bit = 0
    for i in range(8):
        byte_1 = tile_data[i*8 + 0] | (tile_data[i*8 + 1] << 3) | ((tile_data[i*8 + 2] & 0b11) << 6)
        byte_2 = ((tile_data[i*8 + 2] & 0b100) >> 2) | (tile_data[i*8 + 3] << 1) | (tile_data[i*8 + 4] << 4) | ((tile_data[i*8+5] & 0b1) << 7)
        byte_3 = ((tile_data[i*8 + 5] & 0b110) >> 1) | (tile_data[i*8 + 6] << 2) | (tile_data[i*8+7] << 5)
       
        vram[TILE_OFFSET + index*24 + i*3 + 0] = byte_1
        vram[TILE_OFFSET + index*24 + i*3 + 1] = byte_2
        vram[TILE_OFFSET + index*24 + i*3 + 2] = byte_3
    
    return
    
def write_palettes(palettes, vram):
    for i in range(len(palettes)):
        byte_1 = palettes[i][0] | ((palettes[i][1] & 0b11) << 6)
        byte_2 = ((palettes[i][1] & 0b111100) >> 2) | ((palettes[i][2] & 0b1111) << 4)
        byte_3 = ((palettes[i][2] & 0b110000) >> 4) | (palettes[i][3] << 2)
        byte_4 = palettes[i][4] | ((palettes[i][5] &0b11) << 6)
        byte_5 = ((palettes[i][5] & 0b111100) >> 2) | ((palettes[i][6] & 0b1111) << 4)
        byte_6 = ((palettes[i][6] & 0b110000) >> 4) | (palettes[i][7] << 2)
        
        vram[PALETTE_OFFSET + i*6 + 0] = byte_1
        vram[PALETTE_OFFSET + i*6 + 1] = byte_2
        vram[PALETTE_OFFSET + i*6 + 2] = byte_3
        vram[PALETTE_OFFSET + i*6 + 3] = byte_4
        vram[PALETTE_OFFSET + i*6 + 4] = byte_5
        vram[PALETTE_OFFSET + i*6 + 5] = byte_6
    return

def write_screen(screen_indexes, tile_map_attrib, vram):
    for i in range(64*60):
        index = screen_indexes[i]
        vram[NAMETABLE_OFFSET + i] = index
        vram[NAMETABLE_OFFSET + 64*60 + i//4] |= (tile_map_attrib[index] << ((i % 4)*2))

def main():
    vram = [0]*(64*1024)
    colors = []
    colors_image = Image.open("palette.png")
    colors_pixels = colors_image.load()
    for i in range(64):
        pre_val = colors_pixels[i, 0]
        val = (pre_val[0], pre_val[1], pre_val[2])
        colors.append(val)
        
    palettes = []
    tiles_image = Image.open("vram.png")
    tiles_pixels = tiles_image.load()
    
    tile_map_attrib = [0]*256
    tile_map_pixels = []
    screen_indexes = []
    
    # Get all palettes, report error if more than one pallette is used
    # also log attributes here for each tile
    for y in range(16):
        for x in range(16):
            pal_1= tiles_pixels[x*8 + 0, (y*2+1)*8][0:3]
            pal_2= tiles_pixels[x*8 + 1, (y*2+1)*8][0:3]
            pal_3= tiles_pixels[x*8 + 2, (y*2+1)*8][0:3]
            pal_4= tiles_pixels[x*8 + 3, (y*2+1)*8][0:3]
            pal_5= tiles_pixels[x*8 + 4, (y*2+1)*8][0:3]
            pal_6= tiles_pixels[x*8 + 5, (y*2+1)*8][0:3]
            pal_7= tiles_pixels[x*8 + 6, (y*2+1)*8][0:3]
            pal_8= tiles_pixels[x*8 + 7, (y*2+1)*8][0:3]
            
            palette_pixels = (pal_1, pal_2, pal_3, pal_4, pal_5, pal_6, pal_7, pal_8)
            palette = (colors.index(pal_1), colors.index(pal_2), colors.index(pal_3), colors.index(pal_4), colors.index(pal_5), colors.index(pal_6), colors.index(pal_7), colors.index(pal_8))
            if palette not in palettes:
                if len(palettes) >= 4:
                    print("More than 4 palettes used!")
                    return 1
                else:
                    palettes.append(palette)
            
            tile_map_attrib[y*16+x] = palettes.index(palette)
            
            tile_values = []
            tile_values_pixels = []
            
            # Now read pixel values and map them to their pallet value
            for yy in range(8):
                for xx in range(8):
                    pixel_value = tiles_pixels[x*8 + xx, (y*2)*8 + yy][0:3]
                    pal_value = palette_pixels.index(pixel_value)
                    tile_values.append(pal_value)
                    tile_values_pixels.append(pixel_value)
                    
            tile_map_pixels.append(tile_values_pixels)
            write_tile(tile_values, y*16+x, vram)
            
    write_palettes(palettes, vram)
    
    
    screen_image = Image.open("screen.png")
    screen_pixels = screen_image.load()
    
    for y in range(60):
        for x in range(64):
            tile = []
            for yy in range(8):
                for xx in range(8):
                    pixel = screen_pixels[x*8+xx, y*8 + yy][0:3]
                    tile.append(pixel)
                    
            index = tile_map_pixels.index(tile)
            screen_indexes.append(index)
            
    write_screen(screen_indexes, tile_map_attrib, vram)
    
    print("TILE_OFFSET {}\nNAMETABLE_OFFSET {}\nATTR_OFFSET {}\nPALETTE_OFFSET {}".format(hex(TILE_OFFSET), hex(NAMETABLE_OFFSET), hex(ATTR_OFFSET), hex(PALETTE_OFFSET)))
    
    f = open("vram.bin", "wb")
    for i in range(64*1024):
        f.write(bytes([vram[i]]))
    f.close()
    
    f = open("palette.bin", "w")
    for c in colors:
        f.write("{}{}{} ".format(format(c[0],'02x'), format(c[1], '02x'), format(c[2], '02x')))
    f.close()
    
    return 0
    
if __name__ == "__main__":
    sys.exit(main())
