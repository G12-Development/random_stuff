#!/bin/sh

./update.exe mwrite "deadpool_aml_upgrade_package/_aml_dtb.PARTITION" mem dtb normal
./update.exe bulkcmd "disk_initial 1"
./update.exe partition _aml_dtb "deadpool_aml_upgrade_package/_aml_dtb.PARTITION"
./update.exe bulkcmd "setenv upgrade_step 1"
./update.exe bulkcmd "save"
./update.exe bulkcmd "setenv firstboot 1"
./update.exe bulkcmd "save"
./update.exe partition boot "deadpool_aml_upgrade_package/boot.PARTITION"
./update.exe partition dtbo "deadpool_aml_upgrade_package/dtbo.PARTITION"
./update.exe partition logo "deadpool_aml_upgrade_package/logo.PARTITION"
./update.exe partition recovery "deadpool_aml_upgrade_package/recovery.PARTITION"
./update.exe partition super "deadpool_aml_upgrade_package/super.PARTITION"
./update.exe partition vbmeta "deadpool_aml_upgrade_package/vbmeta.PARTITION"
./update.exe  bulkcmd "burn_complete 1"
