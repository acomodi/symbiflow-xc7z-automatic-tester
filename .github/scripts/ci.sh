#!/bin/bash

WORKDIR=${PWD}

# Getting the ARM toolchain
wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
tar -xf gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
export PATH=${PWD}/gcc-arm-none-eabi-9-2019-q4-major/bin:$PATH
rm gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2

# Create artifacts directory
mkdir -p artifacts/boot
mkdir -p artifacts/root
ARTIFACTS_DIR=${WORKDIR}/artifacts

# Build U-boot bootloader
pushd u-boot-xlnx
export ARCH=arm
export CROSS_COMPILE=arm-none-eabi-
make zynq_zybo_z7_defconfig
make -j`nproc`

cp spl/boot.bin u-boot.img ${ARTIFACTS_DIR}/boot
popd

# Build Linux kernel
pushd linux-xlnx
git apply ../linux/0001-Add-symbiflow-tester-driver.patch
export ARCH=arm
export CROSS_COMPILE=arm-none-eabi-
export LOADADDR=0x8000
make xilinx_zynq_defconfig
make -j`nproc` uImage
make -j`nproc` dtbs
make -j`nproc` modules

cp arch/arm/boot/uImage ${ARTIFACTS_DIR}/boot
cp arch/arm/boot/dts/zynq-zybo-z7.dtb ${ARTIFACTS_DIR}/boot/devicetree.dtb
cp drivers/misc/symbiflow-tester.ko ${ARTIFACTS_DIR}/root
popd

# Adding required files to rootfs
cp -a python/symbiflow_test.py devmemX zynq_bootloader ${ARTIFACTS_DIR}/root
