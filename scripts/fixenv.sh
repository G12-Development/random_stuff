#!/bin/bash

./update.exe bulkcmd "mmc dev 1"
./update.exe bulkcmd "amlmmc erase env"
./update.exe bulkcmd "amlmmc erase misc"
./update.exe bulkcmd "env default -a"
./update.exe bulkcmd "save"
./update.exe bulkcmd "burn_complete 1"