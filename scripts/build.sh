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
    echo "Usage: $0 [openlinux branch] [refboard]"
}

if [[ $# -lt 2 ]]
then
    usage
    exit 22
fi

GITBRANCH=${1}
REFBOARD=${2}

# path to clone the openlinux repos
#TMP_GIT=$(mktemp -d)
TMP_GIT=out

TMP="out"
mkdir $TMP

# U-Boot
git clone --depth=2 https://gitlab.com/baylibre/amlogic/atv/u-boot.git -b $GITBRANCH $TMP_GIT/u-boot

mkdir $TMP_GIT/gcc-linaro-aarch64-none-elf
wget -qO- https://releases.linaro.org/components/toolchain/binaries/7.2-2017.11/aarch64-elf/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-elf.tar.xz | tar -xJ --strip-components=1 -C $TMP_GIT/gcc-linaro-aarch64-none-elf
sed -i "s,/opt/gcc-.*/bin/,," $TMP_GIT/u-boot/Makefile
(
    cd $TMP_GIT/u-boot
    make ${REFBOARD}_defconfig
    export PATH=/home/build/odroid/out/gcc-linaro-aarch64-none-elf/bin:$PATH CROSS_COMPILE=aarch64-elf-
    echo $PATH
    make -j8 > /dev/null
)

#rm -rf ${TMP_GIT}
