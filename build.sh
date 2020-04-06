#!/bin/bash

verilator -cc top.sv hpu.sv vga.sv --exe main.cpp -LDFLAGS -lSDL2
make -C ./obj_dir -f Vtop.mk
