#!/bin/bash

cd arm-trusted-firmware
PATH=/home/build/odroid/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin:$PATH CROSS_COMPILE=aarch64-none-linux-gnu- make PLAT=g12a DEBUG=1 all
cd ..
