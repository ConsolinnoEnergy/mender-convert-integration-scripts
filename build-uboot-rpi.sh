#!/bin/bash

# Script to generate Mender integration binaries for Raspberry Pi boards
#
# Files that will be packaged:
#
#     - u-boot.bin
#     - fw_printenv
#     - fw_env.config
#     - boot.scr
#
# NOTE! This script is not necessarily well tested and the main purpose
# is to provide an reference on how the current integration binaries where
# generated.

set -e

function usage() {
    echo "./$(basename $0) <defconfig> <board name>"
}

if [ -z "$1" ] || [ -z "$2" ]; then
    usage
    exit 1
fi

# Availabile defconfigs:
#
#    - rpi_0_w_defconfig
#    - rpi_3_32b_defconfig
#    - rpi_4_32b_defconfig
#
rpi_defconfig=$1
rpi_board=$2

# ARM 32bit build (custom toolchain to support ARMv6)
export PATH="$PATH:/armv6-eabihf--glibc--stable-2018.11-1/bin"
export CROSS_COMPILE=arm-buildroot-linux-gnueabihf-
export ARCH=arm

# Test if the toolchain is actually installed
arm-buildroot-linux-gnueabihf-gcc --version

UBOOT_MENDER_BRANCH=2020.01

# Clean-up old builds
#rm -rf uboot-mender
echo "currently at ${PWD}"
ls
#git clone https://github.com/mendersoftware/uboot-mender.git -b mender-rpi-${UBOOT_MENDER_BRANCH}
cd uboot-mender

make ${rpi_defconfig}
make -j $(nproc)
make -j $(nproc) envtools

cat <<- 'EOF' > boot.cmd
# DO NOT EDIT THIS FILE
#

fdt addr ${fdt_addr} && fdt get value bootargs /chosen bootargs
run mender_setup
mmc dev ${mender_uboot_dev}
if load ${mender_uboot_root} ${kernel_addr_r} /boot/zImage; then
    bootz ${kernel_addr_r} - ${fdt_addr}
elif load ${mender_uboot_root} ${kernel_addr_r} /boot/uImage; then
    bootm ${kernel_addr_r} - ${fdt_addr}
else
    echo "No bootable Kernel found."
fi
run mender_try_to_recover

# Recompile with:
# mkimage -C none -A arm -T script -d boot.cmd boot.scr
EOF

mkimage -C none -A arm -T script -d boot.cmd boot.scr

cat <<- EOF > fw_env.config
/dev/mmcblk0 0x400000 0x4000
/dev/mmcblk0 0x800000 0x4000
EOF

mkdir integration-binaries
cp u-boot.bin tools/env/fw_printenv fw_env.config boot.scr integration-binaries/
git log --graph --pretty=oneline -15 > integration-binaries/uboot-git-log.txt
cd integration-binaries

# Availabile boards:
#
#    - raspberrypi0w
#    - raspberrypi3
#    - raspberrypi4
#
tar czvf ${rpi_board}-${UBOOT_MENDER_BRANCH}.tar.gz ./*
cd -
