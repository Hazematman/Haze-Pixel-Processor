#!/usr/bin/env python3
import sys

def main():
    vram = [0]*(64*1024)
    f = open("vram.bin", "rb")
    for i in range(64*1024):
        vram[i] = int.from_bytes(f.read(1), "little")
    f.close()
    
    f = open("out.mem", "w")
    for i in range(8*1024):
        byte = vram[i]
        f.write("{} ".format(hex(byte)[2:]))
    f.close()
    
    f = open("palettes.mem", "w")
    
    for i in range(4):
        val = 0;
        val |= vram[0x1cb0 + i*6 + 0] << 0;
        val |= vram[0x1cb0 + i*6 + 1] << 8;
        val |= vram[0x1cb0 + i*6 + 2] << 16;
        val |= vram[0x1cb0 + i*6 + 3] << 24;
        val |= vram[0x1cb0 + i*6 + 4] << 32;
        val |= vram[0x1cb0 + i*6 + 5] << 40;
        f.write("{} ".format(hex(val)[2:]))
    
    f.close()
    return 0
    
if __name__ == "__main__":
    sys.exit(main()) 
