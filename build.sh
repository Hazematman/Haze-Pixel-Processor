#!/bin/bash

if [[ "$OS" == *"Windows"* ]]; then
    LIBS="-lSDL2"
else
    LIBS="-lSDL2"
fi

verilator -cc top.sv hpu.sv vga.sv --exe main.cpp -LDFLAGS ${LIBS}
make -C ./obj_dir -f Vtop.mk
