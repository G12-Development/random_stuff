#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

set -o xtrace

# The goal of this script is gather all binaries provides by AML in order to generate
# our final u-boot image from the u-boot.bin (bl33)
#
# Some binaries come from the u-boot vendor kernel (bl21, acs, bl301)
# Others from the buildroot package (aml_encrypt tool, bl2.bin, bl30)

function usage() {
    echo "Usage: $0 [openlinux branch] [soc] [refboard]"
}

if [[ $# -lt 3 ]]
then
    usage
    exit 22
fi

GITBRANCH=${1}
SOCFAMILY=${2}
REFBOARD=${3}

if [[ "$SOCFAMILY" == "sm1" ]]
then
    SOCFAMILY="g12a"
fi

if ! [[ "$SOCFAMILY" == "g12a" || "$SOCFAMILY" == "g12b" || "$SOCFAMILY" == "sm1" ]]
then
    echo "${SOCFAMILY} is not supported - should be [g12a, g12b, sm1]"
    usage
    exit 22
fi

BIN_LIST="$SOCFAMILY/bl2.bin \
	  $SOCFAMILY/bl30.bin \
	  $SOCFAMILY/bl31.bin \
	  $SOCFAMILY/bl31.img \
	  $SOCFAMILY/aml_encrypt_$SOCFAMILY "

FW_LIST="$SOCFAMILY/*.fw"

# path to clone the openlinux repos
TMP_GIT="/home/build/odroid/hk/"

TMP="fip-collect-${SOCFAMILY}-${REFBOARD}-${GITBRANCH}-$(date +%Y%m%d-%H%M%S)"
mkdir $TMP

# U-Boot
git clone --depth=2 https://github.com/hardkernel/u-boot -b $GITBRANCH $TMP_GIT/u-boot

mkdir $TMP_GIT/gcc-linaro-aarch64-none-elf
wget -qO- https://releases.linaro.org/archive/13.11/components/toolchain/binaries/gcc-linaro-aarch64-none-elf-4.8-2013.11_linux.tar.xz | tar -xJ --strip-components=1 -C $TMP_GIT/gcc-linaro-aarch64-none-elf
mkdir $TMP_GIT/gcc-linaro-arm-none-eabi
wget -qO- https://releases.linaro.org/archive/13.11/components/toolchain/binaries/gcc-linaro-arm-none-eabi-4.8-2013.11_linux.tar.xz | tar -xJ --strip-components=1 -C $TMP_GIT/gcc-linaro-arm-none-eabi
sed -i "s,/opt/gcc-.*/bin/,," $TMP_GIT/u-boot/Makefile
(
    cd $TMP_GIT/u-boot
    (
        # fix source for ddr_parse
        sed -i 's/ddr_set_t __ddr_setting\[\] = {/ddr_set_t __ddr_setting\[\] __attribute__ ((section(".ddr_settings"))) = {/' board/hardkernel/odroidc4/firmware/timing.c
        sed -i 's/\*(.data\*)/\*(.data\*)\n        \*(.ddr_settings\*)/' arch/arm/cpu/armv8/g12a/firmware/acs/acs.ld.S
        sed -i 's/.rsv_set_addr\t= 0,/\n\t\t\t\t\t.board_id\t\t= {0,},\n\t\t\t\t\t.ddr_struct_size = {0,},\n\t\t\t\t\t.ddr_struct_org_size = sizeof(ddr_set_t),/' arch/arm/cpu/armv8/g12a/firmware/acs/acs.c
        sed -i 's/.word	__ramdump_data/.word\t__ramdump_data\n\t.word\t__ddr_setting/' arch/arm/cpu/armv8/g12a/firmware/acs/acs_entry.S
        sed -i 's/.word\t0x0/.word\t0x0\n\t.word\t__ddr_setting/' arch/arm/cpu/armv8/g12a/firmware/acs/acs_entry.S
        sed -i 's/unsigned long\t\trsv_set_addr;/unsigned long\t\trsv_set_addr;\n\t\tchar\t\t\t\tboard_id[12];\n\t\tunsigned short\t\tddr_struct_size[12];\n\t\tunsigned long\t\tddr_struct_org_size;\n/' arch/arm/include/asm/arch-g12a/acs.h
    )
    make ${REFBOARD}_defconfig
    PATH=$TMP_GIT/gcc-linaro-aarch64-none-elf/bin:$TMP_GIT/gcc-linaro-arm-none-eabi/bin:$PATH CROSS_COMPILE=aarch64-none-elf- make -j8 > /dev/null
    mkdir -p fip/tools/ddr_parse && cd fip/tools/ddr_parse
    wget https://raw.githubusercontent.com/khadas/u-boot/khadas-vims-pie/fip/tools/ddr_parse/Makefile
    wget https://raw.githubusercontent.com/khadas/u-boot/khadas-vims-pie/fip/tools/ddr_parse/parse.c
    make clean && make
)

cp $TMP_GIT/u-boot/build/board/hardkernel/*/firmware/acs.bin $TMP/
cp $TMP_GIT/u-boot/build/scp_task/bl301.bin $TMP/
# cp $TMP_GIT/u-boot/fip/tools/ddr_parse/parse $TMP/
$TMP_GIT/u-boot/fip/tools/ddr_parse/parse ${TMP}/acs.bin
# FIP/BLX
echo $BIN_LIST
for item in $BIN_LIST
do
    BIN=$(echo $item)
    DIR=$TMP_GIT/u-boot/fip/

    if [[ -d $DIR/$SOCFAMILY/ ]]
    then
      cp $DIR/$BIN ${TMP}
    fi

done

echo $FW_LIST
cp $TMP_GIT/u-boot/fip/$FW_LIST ${TMP}


# Normalize
mv $TMP_GIT/u-boot/fip/$SOCFAMILY/aml_encrypt_$SOCFAMILY $TMP/aml_encrypt

date > $TMP/info.txt
echo "SOC: $SOCFAMILY" >> $TMP/info.txt
echo "BRANCH: $GITBRANCH ($(date +%Y%m%d))" >> $TMP/info.txt
for component in $TMP_GIT/*
do
    if [[ -d $component/.git ]]
    then
        echo "$(basename $component): $(git --git-dir=$component/.git log --pretty=format:%H HEAD~1..HEAD)" >> $TMP/info.txt
    fi
done
echo "BOARD: $REFBOARD" >> $TMP/info.txt
echo "export SOCFAMILY=$SOCFAMILY" > $TMP/soc-var.sh

#rm -rf ${TMP_GIT}
