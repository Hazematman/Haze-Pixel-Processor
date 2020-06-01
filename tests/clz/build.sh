#!/bin/bash

verilator -cc top.sv ../../clz.sv --exe main.cpp
make -C ./obj_dir -f Vtop.mk
