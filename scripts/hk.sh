#!/bin/bash

cd hl/u-boot
PATH=~/odroid/khadas/gcc-linaro-aarch64-none-elf/bin:~/odroid/khadas/gcc-linaro-arm-none-eabi/bin:$PATH CROSS_COMPILE=aarch64-none-elf- ./mk odroidc4
cd ../..
