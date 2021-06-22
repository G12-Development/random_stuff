#!/bin/bash

cd out/u-boot/
make khadas-vim3l_android_defconfig
PATH=~/odroid/out/gcc-linaro-aarch64-none-elf/bin:~/odroid/khadas/gcc-linaro-arm-none-eabi/bin:$PATH CROSS_COMPILE=aarch64-elf- make -j8
cd ../..
./generate-bins-new.sh fip-collect-g12a-odroidc4-odroidg12-v2015.01-20210613-160721/ out/u-boot/u-boot.bin
