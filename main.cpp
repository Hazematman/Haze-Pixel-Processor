#include "Vtop.h"
#include <iostream>
#include <fstream>
#include <SDL2/SDL.h>
#include <stdio.h>
using namespace std;

/* Undef main for SDL2 on windows */
#undef main

#define XSIZE 640
#define YSIZE 480

#define FULL_X 800
#define FULL_Y 525

typedef struct Pixel {
    uint8_t a;
    uint8_t b;
    uint8_t g;
    uint8_t r;
} Pixel;

SDL_Renderer *ren;
Pixel pixels[XSIZE*YSIZE];

uint8_t vram[64*1024];

bool load_vram(string filename)
{
    ifstream bin(filename.c_str(), ios_base::binary);
    if(!bin)
    {
        cout << "Cannot load " << filename << "!!!" << endl;
        return false;
    }
    for(int i=0; i < 64*1024; i++)
    {
        uint8_t byte;
        bin.read((char*)&byte, 1);
        vram[i] = byte;
    }
    
    return true;
}

int main(int argc, char *argv[])
{
    int reset;
    bool running = true;
    Verilated::commandArgs(argc, argv);
    
    if(SDL_Init(SDL_INIT_EVERYTHING) == -1) {
        return -1;
    }
    
    if(load_vram("ppu_data/vram.bin") == false)
    {
        return -1;
    }
    
    SDL_Window *win = SDL_CreateWindow("HPU",
                                       SDL_WINDOWPOS_CENTERED,
                                       SDL_WINDOWPOS_CENTERED,
                                       640*2, 480*2, 0);

    ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);

    SDL_Texture *t = SDL_CreateTexture(ren, SDL_PIXELFORMAT_RGBA8888, 
            SDL_TEXTUREACCESS_TARGET, XSIZE, YSIZE);
    
    Vtop *top = new Vtop;
    top->reset = 1;
    top->clk = 0;
    top->eval();
    top->reset = 0;
    top->eval();
        
    for(int i = 0; i < 4; i++)
    {
        uint64_t val = 0;
        val |= (uint64_t)vram[0x2ac0 + i*6 + 0] << 0;
        val |= (uint64_t)vram[0x2ac0 + i*6 + 1] << 8;
        val |= (uint64_t)vram[0x2ac0 + i*6 + 2] << 16;
        val |= (uint64_t)vram[0x2ac0 + i*6 + 3] << 24;
        val |= (uint64_t)vram[0x2ac0 + i*6 + 4] << 32;
        val |= (uint64_t)vram[0x2ac0 + i*6 + 5] << 40;
        top->palettes[i] = val;
    }
    
    SDL_Event e;
    while(running)
    {
        while(SDL_PollEvent(&e)) 
        {
            if(e.type == SDL_QUIT) 
            {
                running = false;
            }
        }
        
        for(int i=0; i < FULL_X * FULL_Y; i++)
        {
            /* Flip clock */
            top->clk = 1;
            top->eval();
            
            /* Flip clock */
            top->clk = 0;
            top->eval();
            
            //if(top->addr_out >= 0x1c58)
            //    cout << "Read addr " << top->addr_out << endl;
                
            //if(top->pix_out != 8 && top->pix_out != 9)
            //    cout << "Pixel out " << (int)top->pix_out << endl;
            
            top->data_in = vram[top->addr_out];
            
            if (top->line < YSIZE && top->column < XSIZE) {
                Pixel *p = &pixels[top->line*XSIZE + top->column];
                p->r = top->r_out;
                p->g = top->g_out;
                p->b = top->b_out;
                p->a = 255;
            }
            
            if(top->line == YSIZE && top->column == XSIZE) {
                    //top->x_offset += 1;
                    top->y_offset += 1;
            }
        }
        
                    
        SDL_UpdateTexture(t, NULL, pixels, XSIZE*sizeof(Pixel));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, t, NULL, NULL);
        SDL_RenderPresent(ren);
    }
}
