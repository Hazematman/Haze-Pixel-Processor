#!/bin/bash

verilator -cc top.sv hpu_tile.sv vga.sv --exe main.cpp -LDFLAGS -lSDL2
make -C ./obj_dir -f Vtop.mk
