#!/bin/bash

cd google/u-boot
make g12a_odroidc4_defconfig
PATH=~/odroid/khadas/gcc-linaro-aarch64-none-elf/bin:~/odroid/khadas/gcc-linaro-arm-none-eabi/bin:$PATH CROSS_COMPILE=aarch64-none-elf- make -j8
cd ../..
./generate-bins-new.sh fip-collect-g12a-odroidc4-odroidg12-v2015.01-20210613-160721/  google/u-boot/build/u-boot.bin
