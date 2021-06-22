#!/bin/sh

./update.exe write ./$1 0xfffa0000 0x10000
./update.exe run 0xfffa0000
./update.exe bl2_boot ./$1
